import os
import httpx
from dotenv import load_dotenv

load_dotenv()

_BASE_URL = "https://api.deepseek.com"
_MODEL = "deepseek-chat"


class DeepSeekClient:
    def __init__(self):
        api_key = os.environ.get("DEEPSEEK_API_KEY", "")
        if not api_key:
            raise RuntimeError("DEEPSEEK_API_KEY is not set")
        self._client = httpx.AsyncClient(
            base_url=_BASE_URL,
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=60.0,
        )

    async def chat(self, messages: list[dict], **kwargs) -> str:
        payload = {"model": _MODEL, "messages": messages, **kwargs}
        response = await self._client.post("/chat/completions", json=payload)
        response.raise_for_status()
        data = response.json()
        return data["choices"][0]["message"]["content"]

    async def aclose(self):
        await self._client.aclose()
