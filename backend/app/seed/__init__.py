"""Демо-данные: компания и двадцать обращений из датасета организаторов."""

from app.seed.accounts import Account, AccountsFileError, default_accounts_path, load_accounts
from app.seed.loader import SeedReport, is_empty, reset_demo

__all__ = ["Account", "AccountsFileError", "SeedReport", "default_accounts_path", "is_empty", "load_accounts", "reset_demo"]
