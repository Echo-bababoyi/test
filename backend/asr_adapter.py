import asyncio
import base64
import json
import logging
import os

import websockets
from dotenv import load_dotenv

from backend.xunfei_auth import build_auth_url

load_dotenv()

logger = logging.getLogger(__name__)

_ASR_HOST = "iat-api.xfyun.cn"
_ASR_PATH = "/v2/iat"


class XunfeiASR:
    def __init__(self, app_id: str, api_key: str, api_secret: str):
        self._app_id = app_id
        self._api_key = api_key
        self._api_secret = api_secret

    def _ws_url(self) -> str:
        return build_auth_url(_ASR_HOST, _ASR_PATH, self._api_key, self._api_secret)

    def _start_frame(self, audio_b64: str, is_only: bool) -> dict:
        return {
            "common": {"app_id": self._app_id},
            "business": {
                "language": "zh_cn",
                "domain": "iat",
                "accent": "mandarin",
                "dwa": "wpgs",
            },
            "data": {
                "status": 2 if is_only else 0,
                "format": "audio/L16;rate=16000",
                "encoding": "raw",
                "audio": audio_b64,
            },
        }

    def _audio_frame(self, audio_b64: str, is_last: bool) -> dict:
        return {"data": {"status": 2 if is_last else 1, "format": "audio/L16;rate=16000", "encoding": "raw", "audio": audio_b64}}

    async def recognize(self, audio_chunks: list[bytes]) -> str:
        """接收音频 chunk 列表，返回最终识别文字。"""
        url = self._ws_url()
        result_text = ""

        async with websockets.connect(url) as ws:
            if len(audio_chunks) == 1:
                # Single chunk: status=2 in start frame, no further frames needed
                start = self._start_frame(base64.b64encode(audio_chunks[0]).decode(), is_only=True)
                await ws.send(json.dumps(start))
            else:
                # Multi-chunk: status=0 for first, 1 for middle, 2 for last
                start = self._start_frame(base64.b64encode(audio_chunks[0]).decode(), is_only=False)
                await ws.send(json.dumps(start))
                for i, chunk in enumerate(audio_chunks[1:], start=1):
                    is_last = (i == len(audio_chunks) - 1)
                    frame = self._audio_frame(base64.b64encode(chunk).decode(), is_last)
                    await ws.send(json.dumps(frame))
                    await asyncio.sleep(0.04)

            async for message in ws:
                data = json.loads(message)
                code = data.get("code", -1)
                if code != 0:
                    logger.error("ASR error code=%s msg=%s", code, data.get("message"))
                    break
                ws_data = data.get("data", {})
                result = ws_data.get("result", {})
                for w in result.get("ws", []):
                    for cw in w.get("cw", []):
                        result_text += cw.get("w", "")
                if ws_data.get("status") == 2:
                    break

        return result_text.strip()

    async def recognize_stream(self, audio_chunk: bytes, is_last: bool) -> dict:
        """单 chunk 流式识别接口（供逐帧调用场景使用）。"""
        text = await self.recognize([audio_chunk]) if is_last else ""
        return {"text": text, "is_final": is_last, "confidence": 1.0}


def get_asr_adapter() -> XunfeiASR | None:
    app_id = os.getenv("XUNFEI_APP_ID", "")
    api_key = os.getenv("XUNFEI_API_KEY", "")
    api_secret = os.getenv("XUNFEI_API_SECRET", "")
    if app_id and api_key and api_secret:
        return XunfeiASR(app_id=app_id, api_key=api_key, api_secret=api_secret)
    return None
