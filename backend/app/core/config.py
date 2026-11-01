"""Application configuration using Pydantic Settings."""
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    APP_NAME: str = "SmartPlot-AI"
    APP_ENV: str = "development"
    APP_HOST: str = "127.0.0.1"
    APP_PORT: int = 8000
    DEBUG: bool = True
    SOLVER_TIMEOUT_SECONDS: float = 10.0
    ALLOWED_ORIGINS: List[str] = ["http://localhost:5000", "http://127.0.0.1:5000"]
    INTERNAL_API_KEY: str = "smartplot-internal-dev-key"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
