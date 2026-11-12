"""Корневой роутер API. Все маршруты — под префиксом /api/v1.

Новый модуль: создайте свой `APIRouter` и подключите его здесь одной строкой.
"""

from fastapi import APIRouter

from app.access import router as access
from app.admin import router as admin
from app.analytics import router as analytics
from app.api import dictionaries, health
from app.appeals import actions_router as appeal_actions
from app.appeals import bitrix as appeal_bitrix
from app.appeals import duplicates
from app.appeals import router as appeals
from app.auth import bitrix as auth_bitrix
from app.auth import router as auth
from app.directory import router as directory
from app.discussions import router as discussions
from app.drafts import router as drafts
from app.live import router as live
from app.meetings import router as meetings
from app.notifications import router as notifications

API_PREFIX = "/api/v1"

api_router = APIRouter(prefix=API_PREFIX)
api_router.include_router(health.router)
api_router.include_router(dictionaries.router)
api_router.include_router(auth.router)
api_router.include_router(auth_bitrix.router)
api_router.include_router(appeals.router)
api_router.include_router(appeal_actions.router)
api_router.include_router(duplicates.router)
api_router.include_router(appeal_bitrix.router)
api_router.include_router(directory.router)
api_router.include_router(discussions.router)
api_router.include_router(notifications.router)
api_router.include_router(admin.router)
api_router.include_router(access.router)
api_router.include_router(analytics.router)
api_router.include_router(drafts.router)
api_router.include_router(meetings.router)
api_router.include_router(live.router)
