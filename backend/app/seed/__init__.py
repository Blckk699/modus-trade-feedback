"""Демо-данные: компания и двадцать обращений из датасета организаторов."""

from app.seed.accounts import (
    Account,
    AccountsFileError,
    SwitchMember,
    default_accounts_path,
    load_accounts,
    load_switch_group,
)
from app.seed.loader import SeedReport, apply_switch_group, is_empty, reset_demo

__all__ = [
    "Account",
    "AccountsFileError",
    "SeedReport",
    "SwitchMember",
    "apply_switch_group",
    "default_accounts_path",
    "is_empty",
    "load_accounts",
    "load_switch_group",
    "reset_demo",
]
