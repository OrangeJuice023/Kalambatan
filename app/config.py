"""Kalambatan backend configuration.

Zero-cost policy: all AI inference runs locally through Ollama.
There are intentionally NO settings for OpenAI, Anthropic, or Gemini keys.
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Kalambatan API"
    database_url: str = "postgresql://kalambatan:kalambatan@localhost:5432/kalambatan"

    # Local inference only (Ollama default port). No paid APIs, ever.
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "qwen2.5:3b"

    # AI assistant rate limits (per the platform spec)
    assistant_requests_per_minute: int = 10
    assistant_requests_per_hour: int = 50
    assistant_cache_ttl_hours: int = 24

    class Config:
        env_file = ".env"


settings = Settings()
