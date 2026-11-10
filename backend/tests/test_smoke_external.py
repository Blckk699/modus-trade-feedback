"""Скрипт проверки настоящих сервисов: на фейках, чтобы проверить его отчёт и отсутствие утечек."""

from __future__ import annotations

from scripts.smoke_external import SAMPLE, run_checks

WEBHOOK = "https://portal.example/rest/1/secret-webhook-token/"


async def run(app, webhook: str = "") -> tuple[int, list[str]]:
    app.state.settings.bitrix24_webhook_url = webhook
    lines: list[str] = []
    code = await run_checks(app.state.services, app.state.settings, lines.append)
    return code, lines


def test_sample_is_a_short_wav() -> None:
    data = SAMPLE.read_bytes()
    assert data[:4] == b"RIFF" and data[8:12] == b"WAVE"
    assert 3 <= (len(data) - 44) / 32000 <= 5, "образец длиной 3–5 секунд, 16 кГц, 16 бит, моно"


async def test_all_ok_and_bitrix_skipped_without_webhook(app, fake_bitrix) -> None:
    code, lines = await run(app)
    assert code == 0
    assert [line.split(":")[0] for line in lines] == ["Claude", "ElevenLabs", "Битрикс24"]
    assert "пропущено" in lines[2]
    assert fake_bitrix.tasks == []


async def test_bitrix_checked_with_webhook(app, fake_bitrix) -> None:
    code, lines = await run(app, WEBHOOK)
    assert code == 0 and ": ok" in lines[2]
    assert len(fake_bitrix.tasks) == 1


async def test_failure_sets_exit_code_and_hides_details(app, fake_claude, monkeypatch) -> None:
    async def leak(*args, **kwargs):
        raise RuntimeError(f"запрос к {WEBHOOK} не прошёл")

    fake_claude.fail = True
    monkeypatch.setattr(app.state.services.bitrix, "create_task", leak)
    code, lines = await run(app, WEBHOOK)
    assert code == 1
    assert "ошибка (ai_unavailable)" in lines[0]
    assert "ошибка (RuntimeError)" in lines[2]
    assert "secret-webhook-token" not in "\n".join(lines)
