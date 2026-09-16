import os

from fastapi import FastAPI, HTTPException

from app.routers import audit, auth, compras, juegos, personas

app = FastAPI(
    title="ADAII UT2 - API de Juegos",
    version=os.getenv("API_VERSION", "dev"),
)

app.include_router(auth.router)
app.include_router(personas.router)
app.include_router(juegos.router)
app.include_router(compras.router)
app.include_router(audit.router)


@app.get("/")
def root():
    return {
        "message": "API funcionando",
        "version": os.getenv("API_VERSION", "dev"),
    }


@app.get("/health")
def health():
    if os.getenv("FORCE_UNHEALTHY", "false").lower() == "true":
        raise HTTPException(
            status_code=503,
            detail="Version marcada como defectuosa para demostrar rollback",
        )

    return {"status": "ok"}


@app.get("/version")
def version():
    return {
        "version": os.getenv("API_VERSION", "dev"),
        "force_unhealthy": os.getenv("FORCE_UNHEALTHY", "false").lower() == "true",
    }
