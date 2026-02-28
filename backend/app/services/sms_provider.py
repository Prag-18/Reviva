from __future__ import annotations

import os
from abc import ABC, abstractmethod


class SMSProvider(ABC):
    @abstractmethod
    def send_sms(self, *, to_phone: str, message: str) -> None:
        raise NotImplementedError


class ConsoleSMSProvider(SMSProvider):
    def send_sms(self, *, to_phone: str, message: str) -> None:
        print(f"[SMS-DEV] to={to_phone} message={message}")


class TwilioSMSProvider(SMSProvider):
    def __init__(self, account_sid: str, auth_token: str, from_phone: str):
        from twilio.rest import Client

        self._from_phone = from_phone
        self._client = Client(account_sid, auth_token)

    def send_sms(self, *, to_phone: str, message: str) -> None:
        self._client.messages.create(
            body=message,
            from_=self._from_phone,
            to=to_phone,
        )


class SMSProviderFactory:
    @staticmethod
    def create() -> SMSProvider:
        account_sid = os.getenv("TWILIO_ACCOUNT_SID")
        auth_token = os.getenv("TWILIO_AUTH_TOKEN")
        from_phone = os.getenv("TWILIO_FROM_PHONE")

        if account_sid and auth_token and from_phone:
            try:
                return TwilioSMSProvider(account_sid, auth_token, from_phone)
            except Exception:
                return ConsoleSMSProvider()

        return ConsoleSMSProvider()
