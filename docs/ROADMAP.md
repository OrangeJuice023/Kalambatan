# Build Roadmap

## Phase 1 — Foundation ✅ (this commit)
- Repo structure, README, zero-cost policy
- Next.js frontend: landing page + about page (Kalambatan design system)
- FastAPI skeleton: /health, /manifest
- Local AI setup docs

## Phase 2 — Data Layer ✅ (2A complete)
- Synthetic telecom dataset generator (Python, free) ✅
- PostgreSQL + DuckDB local setup ✅
- dbt project: Bronze → Silver → Gold models, star schema ✅
- Airflow DAG for the pipeline (2B — optional, may be cut in schema review)

## Phase 3 — Machine Learning
- Feature store tables
- Churn models: XGBoost, LightGBM, Random Forest
- SHAP explainability outputs
- Model evaluation report

## Phase 4 — Dashboards
- Executive Command Center (Recharts)
- Customer Intelligence Hub
- Churn Prediction Engine UI + Explainable AI views

## Phase 5 — Decision Support
- Retention Strategy Simulator
- AI Insights Assistant (Ollama, read-only, rate-limited, cached)
