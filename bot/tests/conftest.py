import pytest

from tests.support import BotHarness


@pytest.fixture
async def harness():
    h = BotHarness()
    yield h
    await h.close()


@pytest.fixture
async def harness_without_mini_app():
    h = BotHarness(mini_app_url=None)
    yield h
    await h.close()
