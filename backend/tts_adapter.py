import base64
import io
import json
import logging
import os

import websockets
from dotenv import load_dotenv

from backend.xunfei_auth import build_auth_url

load_dotenv()

logger = logging.getLogger(__name__)

_TTS_HOST = "tts-api.xfyun.cn"
_TTS_PATH = "/v2/tts"

_tts_instance = None


class XunfeiTTS:
    def __init__(self, app_id: str, api_key: str, api_secret: str):
        self._app_id = app_id
        self._api_key = api_key
        self._api_secret = api_secret

    async def synthesize(self, text: str, speed: int = 40) -> bytes:
        """文字转语音，返回 mp3 bytes。speed=40 对应慢 15%（正常 50）。"""
        url = build_auth_url(_TTS_HOST, _TTS_PATH, self._api_key, self._api_secret)
        request_data = {
            "common": {"app_id": self._app_id},
            "business": {
                "aue": "lame",
                "sfl": 1,
                "auf": "audio/L16;rate=16000",
                "vcn": "xiaoyan",
                "speed": speed,
                "volume": 50,
                "pitch": 50,
                "tte": "utf8",
            },
            "data": {
                "status": 2,
                "text": base64.b64encode(text.encode("utf-8")).decode(),
            },
        }

        audio_buf = io.BytesIO()
        async with websockets.connect(url) as ws:
            await ws.send(json.dumps(request_data))
            async for message in ws:
                data = json.loads(message)
                code = data.get("code", -1)
                if code != 0:
                    logger.error("TTS error code=%s msg=%s", code, data.get("message"))
                    break
                audio_b64 = data.get("data", {}).get("audio", "")
                if audio_b64:
                    audio_buf.write(base64.b64decode(audio_b64))
                if data.get("data", {}).get("status") == 2:
                    break

        return audio_buf.getvalue()


class EdgeTTS:
    """Edge TTS 备选方案（免费，无需 API Key）。"""

    def __init__(self, voice: str = "zh-CN-XiaoxiaoNeural", rate: str = "-15%"):
        self._voice = voice
        self._rate = rate

    async def synthesize(self, text: str, rate: str | None = None) -> bytes:
        """文字转语音，返回 mp3 bytes。"""
        import edge_tts

        effective_rate = rate or self._rate
        communicate = edge_tts.Communicate(text, self._voice, rate=effective_rate)
        audio_buf = io.BytesIO()
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                audio_buf.write(chunk["data"])
        return audio_buf.getvalue()


def get_tts_adapter() -> XunfeiTTS | EdgeTTS:
    global _tts_instance
    if _tts_instance is None:
        app_id = os.getenv("XUNFEI_APP_ID", "")
        api_key = os.getenv("XUNFEI_API_KEY", "")
        api_secret = os.getenv("XUNFEI_API_SECRET", "")
        if app_id and api_key and api_secret:
            _tts_instance = XunfeiTTS(app_id=app_id, api_key=api_key, api_secret=api_secret)
        else:
            _tts_instance = EdgeTTS()
    return _tts_instance
