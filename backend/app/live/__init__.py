"""Живые обновления по WebSocket (B-24)."""

from app.live import capture as _capture  # noqa: F401 — подключает слушателей сессии
from app.live.hub import LiveHub

__all__ = ["LiveHub"]
