import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.ws_handler import router as ws_router

logging.basicConfig(level=logging.INFO)

app = FastAPI(title="zlb-elder-agent", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ws_router)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "zlb-elder-agent", "version": "0.1.0"}
