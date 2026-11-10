"""Фоновые и периодические задачи при управляемом времени.

Первый тест — образец для следующих тикетов: история пользователя через HTTP API,
внешние сервисы подменены фейками, время двигается явно.
"""

from __future__ import annotations

from datetime import UTC, datetime, time, timedelta
from typing import Any

import httpx
from fastapi import APIRouter, FastAPI
from sqlalchemy import select

from app.adapters.fakes import FakeSpeech, FakeTelegram
from app.api.deps import ClockDep, SessionDep
from app.errors import NotFound
from app.jobs import DailyAt, Every, JobContext, JobRunner, enqueue
from app.jobs.models import Job, JobStatus
from tests.support import TZ, TimeMachine


async def test_meeting_recording_is_processed_in_background(
    app: FastAPI,
    client: httpx.AsyncClient,
    jobs: JobRunner,
    fake_speech: FakeSpeech,
    time_machine: TimeMachine,
) -> None:
    """Истории 48 и 62 в миниатюре: руководитель загружает запись, запрос сразу отвечает
    «обрабатывается», расшифровка готова после того, как воркер выполнил задачу.

    Маршрут и обработчик объявлены прямо в тесте: настоящие появятся в B-12.
    """
    transcripts: dict[int, str] = {}

    @jobs.registry.job("example.transcribe")
    async def transcribe(ctx: JobContext, payload: dict[str, Any]) -> None:
        result = await ctx.services.speech.transcribe(b"...", filename="meeting.ogg", content_type="audio/ogg")
        transcripts[ctx.job_id] = result.text

    router = APIRouter(prefix="/api/v1/_examples")

    @router.post("/recordings", status_code=202)
    async def upload(session: SessionDep, clock: ClockDep) -> dict:
        job_id = await enqueue(session, "example.transcribe", {"file": "meeting.ogg"}, run_at=clock.now())
        return {"id": job_id, "state": "processing"}

    @router.get("/recordings/{job_id}")
    async def status(job_id: int, session: SessionDep) -> dict:
        job = await session.get(Job, job_id)
        if job is None:
            raise NotFound()
        state = "ready" if job.status == JobStatus.DONE else "processing"
        return {"id": job_id, "state": state, "transcript": transcripts.get(job_id)}

    app.include_router(router)
    fake_speech.text = "Склад отгрузил не ту позицию, клиент ждёт третий день."

    uploaded = await client.post("/api/v1/_examples/recordings")
    assert uploaded.status_code == 202
    recording = uploaded.json()
    assert recording["state"] == "processing"

    before = await client.get(f"/api/v1/_examples/recordings/{recording['id']}")
    assert before.json()["state"] == "processing"
    assert fake_speech.calls == []

    await time_machine.advance(seconds=5)

    after = await client.get(f"/api/v1/_examples/recordings/{recording['id']}")
    assert after.json() == {
        "id": recording["id"],
        "state": "ready",
        "transcript": "Склад отгрузил не ту позицию, клиент ждёт третий день.",
    }
    assert len(fake_speech.calls_to("transcribe")) == 1


async def test_delayed_job_runs_only_when_its_time_comes(app: FastAPI, jobs: JobRunner, time_machine: TimeMachine) -> None:
    ran_at: list[datetime] = []

    @jobs.registry.job("example.remind")
    async def remind(ctx: JobContext, payload: dict[str, Any]) -> None:
        ran_at.append(ctx.now())

    async with app.state.sessionmaker() as session, session.begin():
        await enqueue(session, "example.remind", run_at=time_machine.now + timedelta(hours=2))

    assert await time_machine.advance(hours=1, minutes=59) == 0
    assert ran_at == []

    assert await time_machine.advance(minutes=1) == 1
    assert ran_at == [time_machine.now]

    await time_machine.advance(days=1)
    assert len(ran_at) == 1


async def test_daily_job_fires_at_local_time_once_per_day(
    jobs: JobRunner, time_machine: TimeMachine, fake_telegram: FakeTelegram
) -> None:
    """Так будет работать утренняя сводка (B-13): 09:00 по UTC+5, ровно раз в сутки."""

    @jobs.registry.periodic("example.morning", DailyAt(time(9, 0)))
    async def morning(ctx: JobContext, payload: dict[str, Any]) -> None:
        await ctx.services.telegram.send_message(1, f"Сводка на {ctx.now().astimezone(TZ):%d.%m %H:%M}")

    # Понедельник 10:00 — сегодняшние 09:00 уже прошли, первый запуск во вторник.
    await time_machine.run_due()
    await time_machine.travel_to(datetime(2026, 11, 10, 8, 59, tzinfo=TZ))
    assert fake_telegram.sent == []

    await time_machine.advance(minutes=1)
    assert [m.text for m in fake_telegram.sent] == ["Сводка на 10.11 09:00"]

    await time_machine.advance(days=2, step=timedelta(minutes=10))
    assert [m.text for m in fake_telegram.sent] == [
        "Сводка на 10.11 09:00",
        "Сводка на 11.11 09:00",
        "Сводка на 12.11 09:00",
    ]


async def test_interval_job_runs_every_n_minutes(jobs: JobRunner, time_machine: TimeMachine) -> None:
    """Так будет работать проверка эскалации (B-07): раз в ESCALATION_INTERVAL_MINUTES."""
    runs: list[datetime] = []

    @jobs.registry.periodic("example.check", lambda s: Every(minutes=s.escalation_interval_minutes))
    async def check(ctx: JobContext, payload: dict[str, Any]) -> None:
        runs.append(ctx.now())

    start = time_machine.now
    await time_machine.run_due()
    await time_machine.advance(minutes=30, step=timedelta(minutes=1))

    assert runs == [start + timedelta(minutes=10), start + timedelta(minutes=20), start + timedelta(minutes=30)]


async def test_failing_job_is_retried_then_marked_failed(app: FastAPI, jobs: JobRunner, time_machine: TimeMachine) -> None:
    attempts: list[int] = []

    @jobs.registry.job("example.flaky")
    async def flaky(ctx: JobContext, payload: dict[str, Any]) -> None:
        attempts.append(ctx.attempt)
        raise RuntimeError("портал не отвечает")

    async with app.state.sessionmaker() as session, session.begin():
        job_id = await enqueue(session, "example.flaky", run_at=time_machine.now, max_attempts=3)

    await time_machine.run_due()  # попытка 1, повтор через минуту
    await time_machine.advance(minutes=1)  # попытка 2, повтор через 2 минуты
    await time_machine.advance(minutes=1)
    assert attempts == [1, 2]
    await time_machine.advance(minutes=1)  # попытка 3 — последняя
    await time_machine.advance(hours=1)
    assert attempts == [1, 2, 3]

    async with app.state.sessionmaker() as session:
        job = await session.get(Job, job_id)
    assert job.status == JobStatus.FAILED
    assert job.last_error == "RuntimeError: портал не отвечает"


async def test_failed_handler_rolls_back_its_database_changes(app: FastAPI, jobs: JobRunner, time_machine: TimeMachine) -> None:
    @jobs.registry.job("example.half_done")
    async def half_done(ctx: JobContext, payload: dict[str, Any]) -> None:
        await enqueue(ctx.session, "example.side_effect", run_at=ctx.now())
        raise RuntimeError("сбой посередине")

    async with app.state.sessionmaker() as session, session.begin():
        await enqueue(session, "example.half_done", run_at=time_machine.now, max_attempts=1)
    await time_machine.run_due()

    async with app.state.sessionmaker() as session:
        kinds = (await session.execute(select(Job.kind))).scalars().all()
    assert kinds == ["example.half_done"]


async def test_dedup_key_prevents_double_enqueue(app: FastAPI, time_machine: TimeMachine) -> None:
    async with app.state.sessionmaker() as session, session.begin():
        first = await enqueue(session, "example.once", run_at=time_machine.now, dedup_key="appeal:42:step1")
        second = await enqueue(session, "example.once", run_at=time_machine.now, dedup_key="appeal:42:step1")
    assert first is not None
    assert second is None


async def test_cleanup_removes_week_old_finished_jobs(app: FastAPI, time_machine: TimeMachine) -> None:
    now = time_machine.now
    async with app.state.sessionmaker() as session, session.begin():
        for kind, finished in [("old", now - timedelta(days=8)), ("fresh", now - timedelta(days=1))]:
            session.add(
                Job(kind=kind, payload={}, status=JobStatus.DONE, run_at=finished, created_at=finished, finished_at=finished)
            )

    await time_machine.run_due()  # регистрирует расписание: ближайшие 03:00 — во вторник
    await time_machine.travel_to(datetime(2026, 11, 10, 3, 0, tzinfo=TZ))

    async with app.state.sessionmaker() as session:
        kinds = set((await session.execute(select(Job.kind))).scalars())
    assert "old" not in kinds
    assert "fresh" in kinds
    assert "jobs.cleanup" in kinds


def test_daily_schedule_uses_system_timezone() -> None:
    schedule = DailyAt(time(9, 0))
    # 03:59 UTC = 08:59 по UTC+5 -> ближайший запуск в тот же день в 04:00 UTC.
    assert schedule.next_after(datetime(2026, 11, 10, 3, 59, tzinfo=UTC), TZ) == datetime(2026, 11, 10, 4, 0, tzinfo=UTC)
    # Ровно в 09:00 запуск уже состоялся -> следующий завтра.
    assert schedule.next_after(datetime(2026, 11, 10, 4, 0, tzinfo=UTC), TZ) == datetime(2026, 11, 11, 4, 0, tzinfo=UTC)


async def test_stale_running_job_is_requeued_after_its_own_timeout(
    app: FastAPI, jobs: JobRunner, time_machine: TimeMachine
) -> None:
    """Задача, зависшая в running после падения процесса, возвращается в очередь. Долгой задаче
    (расшифровка совещания) задан свой `stale_after`, и через 30 минут её не трогают."""

    @jobs.registry.job("example.long_transcribe", stale_after=timedelta(hours=2))
    async def long_transcribe(ctx: JobContext, payload: dict[str, Any]) -> None:
        pass

    now = time_machine.now
    async with app.state.sessionmaker() as session, session.begin():
        for kind in ("example.short", "example.long_transcribe"):
            session.add(
                Job(kind=kind, payload={}, status=JobStatus.RUNNING, run_at=now, created_at=now, started_at=now, attempts=1)
            )

    async def statuses() -> dict[str, str]:
        async with app.state.sessionmaker() as session:
            return dict((await session.execute(select(Job.kind, Job.status))).all())

    time_machine.clock.set(now + timedelta(minutes=31))
    await jobs.requeue_stale(time_machine.now)
    assert await statuses() == {"example.short": JobStatus.PENDING, "example.long_transcribe": JobStatus.RUNNING}

    time_machine.clock.set(now + timedelta(hours=2, minutes=1))
    await jobs.requeue_stale(time_machine.now)
    assert (await statuses())["example.long_transcribe"] == JobStatus.PENDING
