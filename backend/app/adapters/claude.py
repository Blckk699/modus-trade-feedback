"""Адаптер Claude: разбор текста обращений, поиск повторов, разбор совещаний, текст сводки.

Интерфейс — `ClaudeClient`. Реальная реализация — `AnthropicClaude` (официальный SDK `anthropic`,
структурированный ответ через `messages.parse`). В тестах — `FakeClaude` из `app.adapters.fakes`.
"""

from __future__ import annotations

import logging
from typing import Literal, Protocol

import anthropic
from pydantic import BaseModel, Field

from app.errors import ExternalServiceError

log = logging.getLogger(__name__)

AppealType = Literal["problem", "suggestion", "praise"]
Priority = Literal["high", "medium", "low"]


class AppealDraft(BaseModel):
    """Черновик обращения, который предлагает модель. Автор правит его перед подтверждением."""

    type: AppealType = Field(description="problem — проблема, suggestion — предложение, praise — положительный отзыв")
    category: str | None = Field(description="Название категории строго из переданного списка или null")
    priority: Priority
    summary: str = Field(description="Краткая суть, одно предложение")
    proposed_solution: str | None = Field(description="Предлагаемое решение, если оно есть в тексте")


class MeetingDraft(AppealDraft):
    quote: str = Field(description="Дословная цитата из расшифровки, на которой основан черновик")


class DuplicateCandidate(BaseModel):
    id: str
    text: str


class DuplicateMatch(BaseModel):
    id: str = Field(description="id кандидата из переданного списка")
    reason: str = Field(description="Почему это та же проблема, одно предложение по-русски")


class ClaudeClient(Protocol):
    async def draft_appeal(self, text: str, categories: list[str]) -> AppealDraft: ...

    async def find_duplicates(
        self, text: str, candidates: list[DuplicateCandidate]
    ) -> list[DuplicateMatch]: ...

    async def extract_meeting_drafts(self, transcript: str, categories: list[str]) -> list[MeetingDraft]: ...

    async def write_digest(self, facts: str) -> str: ...


_CONTEXT = (
    "Ты помогаешь системе обращений сотрудников группы компаний «Модус Трейд» "
    "(продажа и монтаж инженерного оборудования, Казахстан). Сотрудники сообщают о проблемах, "
    "вносят предложения и оставляют положительные отзывы. Пиши по-русски, коротко и по делу, "
    "без выдумок: опирайся только на присланный текст."
)


class _DuplicateList(BaseModel):
    matches: list[DuplicateMatch]


class _MeetingDraftList(BaseModel):
    drafts: list[MeetingDraft]


class AnthropicClaude:
    def __init__(
        self,
        api_key: str,
        model: str,
        *,
        client: anthropic.AsyncAnthropic | None = None,
        max_tokens: int = 16000,
    ) -> None:
        self._api_key = api_key
        self._model = model
        self._client = client
        self._max_tokens = max_tokens

    def _get_client(self) -> anthropic.AsyncAnthropic:
        if self._client is None:
            if not self._api_key:
                raise ExternalServiceError("Разбор текста не настроен: не задан ANTHROPIC_API_KEY", code="ai_unavailable")
            self._client = anthropic.AsyncAnthropic(api_key=self._api_key, timeout=120.0, max_retries=2)
        return self._client

    async def _parse[T: BaseModel](self, system: str, user: str, output: type[T]) -> T:
        client = self._get_client()
        try:
            response = await client.messages.parse(
                model=self._model,
                max_tokens=self._max_tokens,
                system=f"{_CONTEXT}\n\n{system}",
                messages=[{"role": "user", "content": user}],
                output_format=output,
            )
        except anthropic.APIError as exc:
            log.warning("Claude API error: %s", type(exc).__name__)
            raise ExternalServiceError("Сервис разбора текста недоступен", code="ai_unavailable") from exc
        if response.stop_reason == "refusal" or response.parsed_output is None:
            raise ExternalServiceError("Сервис разбора текста не смог обработать запрос", code="ai_unavailable")
        return response.parsed_output

    async def draft_appeal(self, text: str, categories: list[str]) -> AppealDraft:
        draft = await self._parse(
            "Составь черновик обращения по сообщению сотрудника. Категорию выбери строго из списка; "
            "если ни одна не подходит, верни null. Приоритет high — если работа стоит или есть прямые "
            "потери, low — пожелания без срочности, иначе medium.",
            f"Категории: {_bullets(categories)}\n\nСообщение сотрудника:\n{text}",
            AppealDraft,
        )
        return _clean_category(draft, categories)

    async def find_duplicates(self, text: str, candidates: list[DuplicateCandidate]) -> list[DuplicateMatch]:
        if not candidates:
            return []
        listing = "\n".join(f"- id={c.id}: {c.text}" for c in candidates)
        result = await self._parse(
            "Найди среди открытых обращений те, что описывают ту же самую проблему или предложение, "
            "что и новое. Похожая тема — ещё не повтор: нужен тот же предмет. Если повторов нет, верни пустой список.",
            f"Новое обращение:\n{text}\n\nОткрытые обращения:\n{listing}",
            _DuplicateList,
        )
        known = {c.id for c in candidates}
        return [m for m in result.matches if m.id in known]

    async def extract_meeting_drafts(self, transcript: str, categories: list[str]) -> list[MeetingDraft]:
        result = await self._parse(
            "Это расшифровка рабочего совещания. Выдели из неё отдельные проблемы и предложения, "
            "по которым нужно действие. Для каждого дай черновик обращения и дословную цитату из расшифровки. "
            "Категорию выбери строго из списка или верни null. Не дроби одну тему на несколько черновиков.",
            f"Категории: {_bullets(categories)}\n\nРасшифровка:\n{transcript}",
            _MeetingDraftList,
        )
        return [_clean_category(d, categories) for d in result.drafts]

    async def write_digest(self, facts: str) -> str:
        client = self._get_client()
        try:
            response = await client.messages.create(
                model=self._model,
                max_tokens=self._max_tokens,
                system=(
                    f"{_CONTEXT}\n\nНапиши утреннюю сводку для руководителя по переданным фактам: "
                    "простой текст для сообщения в Telegram, без Markdown-таблиц, не больше 15 строк. "
                    "Не добавляй чисел и фактов, которых нет во входных данных."
                ),
                messages=[{"role": "user", "content": facts}],
            )
        except anthropic.APIError as exc:
            log.warning("Claude API error: %s", type(exc).__name__)
            raise ExternalServiceError("Сервис разбора текста недоступен", code="ai_unavailable") from exc
        text = "".join(block.text for block in response.content if block.type == "text").strip()
        if response.stop_reason == "refusal" or not text:
            raise ExternalServiceError("Сервис разбора текста не смог составить сводку", code="ai_unavailable")
        return text

    async def aclose(self) -> None:
        if self._client is not None:
            await self._client.close()


def _bullets(items: list[str]) -> str:
    return "; ".join(items) if items else "(справочник пуст)"


def _clean_category[D: AppealDraft](draft: D, categories: list[str]) -> D:
    if draft.category is not None and draft.category not in categories:
        return draft.model_copy(update={"category": None})
    return draft
