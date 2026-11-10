"""Адаптер распознавания речи: ElevenLabs Scribe (голосовые и записи совещаний)."""

from __future__ import annotations

import logging
from typing import Protocol

import httpx
from pydantic import BaseModel

from app.errors import ExternalServiceError

log = logging.getLogger(__name__)

ELEVENLABS_STT_URL = "https://api.elevenlabs.io/v1/speech-to-text"


class Transcript(BaseModel):
    text: str
    language_code: str | None = None


class SpeechToText(Protocol):
    async def transcribe(
        self, audio: bytes, *, filename: str, content_type: str, diarize: bool = False
    ) -> Transcript: ...


class ElevenLabsScribe:
    def __init__(
        self,
        api_key: str,
        *,
        model_id: str = "scribe_v1",
        language_code: str | None = "rus",
        transport: httpx.AsyncBaseTransport | None = None,
        timeout: float = 600.0,
    ) -> None:
        self._api_key = api_key
        self._model_id = model_id
        self._language_code = language_code
        self._http = httpx.AsyncClient(transport=transport, timeout=timeout)

    async def transcribe(
        self, audio: bytes, *, filename: str, content_type: str, diarize: bool = False
    ) -> Transcript:
        if not self._api_key:
            raise ExternalServiceError(
                "Распознавание речи не настроено: не задан ELEVENLABS_API_KEY", code="speech_unavailable"
            )
        data = {"model_id": self._model_id, "diarize": "true" if diarize else "false"}
        if self._language_code:
            data["language_code"] = self._language_code
        try:
            response = await self._http.post(
                ELEVENLABS_STT_URL,
                headers={"xi-api-key": self._api_key},
                data=data,
                files={"file": (filename, audio, content_type)},
            )
            response.raise_for_status()
            body = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            log.warning("ElevenLabs STT error: %s", type(exc).__name__)
            raise ExternalServiceError("Сервис распознавания речи недоступен", code="speech_unavailable") from exc
        text = (body.get("text") or "").strip()
        if not text:
            raise ExternalServiceError("Не удалось распознать речь в записи", code="speech_empty", status_code=422)
        return Transcript(text=text, language_code=body.get("language_code"))

    async def aclose(self) -> None:
        await self._http.aclose()
