"""
server.py — Backend API server for the 4 to 8 fine dining app.

Runs inside the Cloud Run container alongside nginx.
Uses Application Default Credentials (the Cloud Run service account)
automatically — no credentials need to be embedded in code.

Environment variables:
  ADMIN_SECRET  - Required. A strong secret string that the admin
                  panel sends as the X-Admin-Secret header to
                  authenticate write operations.
  GCS_BUCKET    - GCS bucket name (default: four-to-eight-fine-dine)
  FIRESTORE_DB  - Firestore database ID (default: finedine)
  GCP_PROJECT   - GCP project ID (default: four2eight-eb841)
"""

import os
import re
import secrets
from datetime import datetime, timezone
from typing import List

from dotenv import load_dotenv
import uvicorn
from fastapi import FastAPI, HTTPException, Header, UploadFile, File, Form
from google.cloud import firestore, storage as gcs
from pydantic import BaseModel, field_validator

# Load .env when running locally; on Cloud Run the vars are injected directly.
load_dotenv()

# ── Config ────────────────────────────────────────────────────────────────────

def _require(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"Required environment variable '{name}' is not set")
    return value

GCS_BUCKET   = _require("GCS_BUCKET")
FIRESTORE_DB = _require("FIRESTORE_DB")
GCP_PROJECT  = _require("GCP_PROJECT")
ADMIN_SECRET = _require("ADMIN_SECRET")
COLLECTION   = "menu"

# ── Upload constraints ────────────────────────────────────────────────────────
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
ALLOWED_EXTENSIONS    = {"jpg", "jpeg", "png", "webp", "gif"}
MAX_FILE_SIZE         = 10 * 1024 * 1024  # 10 MB
_SAFE_FOLDER          = re.compile(r'^[a-zA-Z0-9][a-zA-Z0-9\-]*$')

app = FastAPI(docs_url=None, redoc_url=None)  # disable public docs

# ── GCP client singletons (reused across requests) ────────────────────────────

_db: firestore.Client | None = None
_storage: gcs.Client | None = None

def _get_db() -> firestore.Client:
    global _db
    if _db is None:
        _db = firestore.Client(project=GCP_PROJECT, database=FIRESTORE_DB)
    return _db

def _get_storage() -> gcs.Client:
    global _storage
    if _storage is None:
        _storage = gcs.Client(project=GCP_PROJECT)
    return _storage

# ── Helpers ───────────────────────────────────────────────────────────────────

def _verify(secret: str) -> None:
    if not secrets.compare_digest(secret, ADMIN_SECRET):
        raise HTTPException(status_code=401, detail="Unauthorized")

def _date_key() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")

# ── Public endpoint: customer-facing menu read ────────────────────────────────

@app.get("/api/menu")
def get_menu():
    """Returns today's 4 dishes from Firestore. No auth required."""
    db = _get_db()
    doc = db.collection(COLLECTION).document(_date_key()).get()
    if not doc.exists:
        return {"dishes": []}
    data = doc.to_dict() or {}
    return {"dishes": data.get("dishes", [])}

# ── Admin: upload a dish image to GCS ────────────────────────────────────────

@app.post("/api/upload-image")
async def upload_image(
    dish_folder: str = Form(...),
    file: UploadFile = File(...),
    x_admin_secret: str = Header(...),
):
    """
    Uploads an image to:
      gs://{GCS_BUCKET}/{YYYY-MM-DD}/{dish_folder}/photo.{ext}

    Returns the public URL.
    """
    _verify(x_admin_secret)

    if not _SAFE_FOLDER.match(dish_folder):
        raise HTTPException(status_code=400, detail="Invalid dish_folder name")

    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail="Only image files are allowed")

    original_name = file.filename or "photo.jpg"
    ext = original_name.rsplit(".", 1)[-1].lower() if "." in original_name else "jpg"
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="File extension not allowed")

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail="File too large (max 10 MB)")

    date_key = _date_key()
    object_path = f"{date_key}/{dish_folder}/photo.{ext}"

    blob = _get_storage().bucket(GCS_BUCKET).blob(object_path)
    blob.upload_from_string(content, content_type=file.content_type)

    public_url = f"https://storage.googleapis.com/{GCS_BUCKET}/{object_path}"
    return {"url": public_url}

# ── Admin: publish today's menu to Firestore ─────────────────────────────────

class Dish(BaseModel):
    name: str
    description: str
    price: str
    imageUrl: str = ""

    @field_validator('name', 'description', 'price')
    @classmethod
    def must_not_be_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError('Field must not be blank')
        return v

    @field_validator('imageUrl')
    @classmethod
    def validate_image_url(cls, v: str) -> str:
        if v and not v.startswith(("https://storage.googleapis.com/", "https://firebasestorage.googleapis.com/")):
            raise ValueError('imageUrl must be a Google Cloud Storage URL')
        return v

class PublishPayload(BaseModel):
    dishes: List[Dish]

@app.post("/api/publish-menu")
def publish_menu(
    payload: PublishPayload,
    x_admin_secret: str = Header(...),
):
    """
    Writes today's menu to Firestore:
      Collection : menu
      Document   : YYYY-MM-DD
      Fields     : dishes (array), publishedAt (ISO string)
    """
    _verify(x_admin_secret)
    date_key = _date_key()

    db = _get_db()
    db.collection(COLLECTION).document(date_key).set({
        "dishes": [d.model_dump() for d in payload.dishes],
        "publishedAt": datetime.now(timezone.utc).isoformat(),
    })

    return {"status": "ok", "date": date_key}


# ── Local dev: serve Flutter web build as static files ────────────────────────
# In production nginx handles this. Locally, FastAPI serves build/web directly
# so the Flutter app and the API share the same origin (no CORS issues).

import pathlib
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

_WEB_BUILD = pathlib.Path(__file__).parent / "build" / "web"

if _WEB_BUILD.exists():
    # Serve Flutter assets; must come AFTER all /api/* routes
    app.mount("/", StaticFiles(directory=str(_WEB_BUILD), html=True), name="static")


if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8080, reload=True)
