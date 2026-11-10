from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(tags=["health"])


class HealthOut(BaseModel):
    status: str


@router.get("/health", response_model=HealthOut, summary="Проверка, что сервис жив")
async def health() -> HealthOut:
    return HealthOut(status="ok")
