"""e2e: бот против настоящего бэкенда на временной базе. Фейк — только Telegram (и внешние сервисы бэкенда).

    cd bot && uv run pytest e2e          # поднимает backend/… через `uv run --project ../backend`

Или против уже запущенного: E2E_API_URL=http://127.0.0.1:8765 uv run pytest e2e
(бэкенд с ключом `e2e-service-key` и сидом из e2e/backend_server.py).
"""

import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

import httpx
import pytest

from e2e.constants import FIRST_TELEGRAM_ID, SERVICE_KEY
from tests.support import BotHarness

ROOT = Path(__file__).resolve().parents[2]
PORT = 8765


@pytest.fixture(scope="session")
def api_url():
    if url := os.environ.get("E2E_API_URL"):
        yield url.rstrip("/")
        return
    if shutil.which("uv") is None:
        pytest.skip("нужен uv, чтобы поднять бэкенд")
    proc = subprocess.Popen(
        ["uv", "run", "--project", str(ROOT / "backend"), "python", str(Path(__file__).with_name("backend_server.py")),
         "--port", str(PORT)],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    deadline = time.monotonic() + 180
    log = []
    try:
        for line in proc.stdout:
            log.append(line)
            if line.startswith("READY"):
                break
            if time.monotonic() > deadline:
                break
        url = f"http://127.0.0.1:{PORT}"
        for _ in range(50):
            try:
                if httpx.get(f"{url}/api/v1/health").status_code == 200:
                    break
            except httpx.HTTPError:
                time.sleep(0.2)
        else:
            pytest.fail("бэкенд не поднялся:\n" + "".join(log[-30:]))
        yield url
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=20)
        except subprocess.TimeoutExpired:
            proc.kill()


ADMIN_TELEGRAM_ID = FIRST_TELEGRAM_ID + 1  # второй в сиде — администратор (app/seed/data.py)


@pytest.fixture(scope="session")
def people(api_url) -> dict[str, int]:
    """Telegram ID демо-пользователей по имени: их видит только администратор (GET /users)."""
    headers = {"X-Service-Key": SERVICE_KEY, "X-Telegram-Id": str(ADMIN_TELEGRAM_ID)}
    users = httpx.get(f"{api_url}/api/v1/users", headers=headers).raise_for_status().json()
    return {u["full_name"]: u["telegram_id"] for u in users}


@pytest.fixture
async def bot(api_url):
    h = BotHarness(real_api_url=api_url, service_key=SERVICE_KEY)
    yield h
    await h.close()


@pytest.fixture
async def backend(api_url):
    """Прямые вызовы API от имени любого пользователя — то, что сделали бы веб и мобильное приложение."""
    async with httpx.AsyncClient(base_url=api_url, headers={"X-Service-Key": SERVICE_KEY}, timeout=15) as client:
        yield client
