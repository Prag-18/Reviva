from __future__ import annotations

from abc import ABC, abstractmethod


class EmailProvider(ABC):
    @abstractmethod
    def send_verification_email(self, *, to_email: str, verification_url: str) -> None:
        raise NotImplementedError


class ConsoleEmailProvider(EmailProvider):
    def send_verification_email(self, *, to_email: str, verification_url: str) -> None:
        print(f"[EMAIL-DEV] to={to_email} verify={verification_url}")


class EmailProviderFactory:
    @staticmethod
    def create() -> EmailProvider:
        return ConsoleEmailProvider()
