"""Kalambatan API — Phase 1 skeleton.

Endpoints will grow with the platform modules. For now this exposes a health
check and a platform manifest so the frontend has something real to hit.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings

app = FastAPI(title=settings.app_name, version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict:
    return {"status": "nominal", "service": settings.app_name}


@app.get("/manifest")
def manifest() -> dict:
    """Platform manifest: modules and cost policy."""
    return {
        "platform": "Kalambatan",
        "tagline": "Keeping Customers Connected.",
        "monthly_llm_cost_php": 0,
        "inference": "local (Ollama)",
        "modules": [
            "Executive Command Center",
            "Customer Intelligence Hub",
            "Churn Prediction Engine",
            "Explainable AI Module",
            "Retention Strategy Simulator",
            "AI Insights Assistant",
        ],
    }
