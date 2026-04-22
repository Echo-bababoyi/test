import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import app.config as cfg
from app.ws_handler import router as ws_router

logging.basicConfig(level=logging.INFO)

cfg.validate()

app = FastAPI(title="zlb-elder-agent", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=cfg.CORS_ORIGINS + ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ws_router)


@app.get("/health")
async def health():
    from app.config import USE_LLM
    return {"status": "ok", "service": "zlb-elder-agent", "version": "0.1.0", "use_llm": USE_LLM}
