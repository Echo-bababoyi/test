import os

from dotenv import load_dotenv

load_dotenv()

DEEPSEEK_API_KEY: str | None = os.getenv("DEEPSEEK_API_KEY")
USE_LLM: bool = os.getenv("USE_LLM", "true").lower() == "true"
CORS_ORIGINS: list[str] = os.getenv(
    "CORS_ORIGINS", "http://localhost:5000,http://localhost:3000"
).split(",")


def _mask(key: str | None) -> str:
    if not key or len(key) < 8:
        return "***"
    return key[:5] + "..." + key[-4:]


def validate():
    if USE_LLM and not DEEPSEEK_API_KEY:
        raise RuntimeError(
            "USE_LLM=true 但 DEEPSEEK_API_KEY 未配置，"
            "请在 backend/.env 中填入 API Key，或设置 USE_LLM=false 使用硬编码规则。"
        )
