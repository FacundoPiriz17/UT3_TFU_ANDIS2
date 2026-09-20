# TFU 3 - API de juegos

## Requisitos e inicio

Docker Desktop/Engine iniciado, Docker Compose y Python 3.10+ en el host.

- Windows: PowerShell
- Linux/macOS: Bash. Los scripts usan únicamente la biblioteca estándar de Python en el host; las dependencias de la API se instalan en la imagen.
- Si Python no está en PATH, definir `PYTHON` con la ruta del ejecutable.
- Copiar `.env.example` a `.env`.
- El inicio también crea este archivo si falta.
- Los SQL iniciales usan `db_games`: mantener ese nombre en `.env`. 
- No modificar `API_VERSION` ni `FORCE_UNHEALTHY` en `.env`: provienen de la imagen construida.

Windows (Powershell):

```powershell
.\run.ps1
```

Linux / MacOS (Bash)

```bash
bash run.sh
```

El inicio construye `api:1.0`, espera los cuatro healthchecks, valida Nginx,
consulta HTTP desde el host y exige observar ambas instancias antes de guardar
`.deploy/current_version`. Los scripts funcionan desde cualquier directorio.

- API: http://localhost:8000
- Swagger: http://localhost:8000/docs
- Usuario demo: `demo@adaii.local` / `Demo123!`
