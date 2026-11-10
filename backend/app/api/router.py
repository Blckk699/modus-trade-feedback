"""Корневой роутер API. Все маршруты — под префиксом /api/v1.

Новый модуль: создайте свой `APIRouter` и подключите его здесь одной строкой.
"""

from fastapi import APIRouter

from app.api import health
from app.auth import router as auth

API_PREFIX = "/api/v1"

api_router = APIRouter(prefix=API_PREFIX)
api_router.include_router(health.router)
api_router.include_router(auth.router)
