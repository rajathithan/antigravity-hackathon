import json
import pytest
from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient

# Patch GCP clients before importing the app so no real credentials are required.
_mock_db = MagicMock()
_mock_storage = MagicMock()

with patch("server._get_db", return_value=_mock_db), \
     patch("server._get_storage", return_value=_mock_storage):
    from server import app, ADMIN_SECRET

client = TestClient(app)


# ── /api/menu ─────────────────────────────────────────────────────────────────

def test_get_menu_returns_dishes_when_document_exists():
    doc_mock = MagicMock()
    doc_mock.exists = True
    doc_mock.to_dict.return_value = {"dishes": [{"name": "Samosa", "description": "Crispy", "price": "$6", "imageUrl": ""}]}
    _mock_db.collection.return_value.document.return_value.get.return_value = doc_mock

    with patch("server._get_db", return_value=_mock_db):
        response = client.get("/api/menu")

    assert response.status_code == 200
    assert response.json() == {"dishes": [{"name": "Samosa", "description": "Crispy", "price": "$6", "imageUrl": ""}]}


def test_get_menu_returns_empty_when_no_document():
    doc_mock = MagicMock()
    doc_mock.exists = False
    _mock_db.collection.return_value.document.return_value.get.return_value = doc_mock

    with patch("server._get_db", return_value=_mock_db):
        response = client.get("/api/menu")

    assert response.status_code == 200
    assert response.json() == {"dishes": []}


# ── /api/upload-image ─────────────────────────────────────────────────────────

def test_upload_image_unauthorized():
    response = client.post(
        "/api/upload-image",
        headers={"x-admin-secret": "wrong_secret"},
        data={"dish_folder": "dish-1"},
        files={"file": ("photo.jpg", b"fake", "image/jpeg")},
    )
    assert response.status_code == 401


def test_upload_image_rejects_invalid_folder():
    response = client.post(
        "/api/upload-image",
        headers={"x-admin-secret": ADMIN_SECRET},
        data={"dish_folder": "../evil"},
        files={"file": ("photo.jpg", b"fake", "image/jpeg")},
    )
    assert response.status_code == 400


def test_upload_image_rejects_non_image_content_type():
    response = client.post(
        "/api/upload-image",
        headers={"x-admin-secret": ADMIN_SECRET},
        data={"dish_folder": "dish-1"},
        files={"file": ("script.html", b"<script>", "text/html")},
    )
    assert response.status_code == 400


def test_upload_image_rejects_oversized_file():
    big = b"x" * (10 * 1024 * 1024 + 1)
    response = client.post(
        "/api/upload-image",
        headers={"x-admin-secret": ADMIN_SECRET},
        data={"dish_folder": "dish-1"},
        files={"file": ("photo.jpg", big, "image/jpeg")},
    )
    assert response.status_code == 413


def test_upload_image_success():
    blob_mock = MagicMock()
    _mock_storage.bucket.return_value.blob.return_value = blob_mock

    with patch("server._get_storage", return_value=_mock_storage):
        response = client.post(
            "/api/upload-image",
            headers={"x-admin-secret": ADMIN_SECRET},
            data={"dish_folder": "dish-1"},
            files={"file": ("photo.jpg", b"imgdata", "image/jpeg")},
        )

    assert response.status_code == 200
    assert response.json()["url"].startswith("https://storage.googleapis.com/")


# ── /api/publish-menu ─────────────────────────────────────────────────────────

def test_publish_menu_unauthorized():
    response = client.post(
        "/api/publish-menu",
        headers={"x-admin-secret": "wrong_secret"},
        json={"dishes": []},
    )
    assert response.status_code == 401
    assert response.json() == {"detail": "Unauthorized"}


def test_publish_menu_rejects_invalid_image_url():
    response = client.post(
        "/api/publish-menu",
        headers={"x-admin-secret": ADMIN_SECRET},
        json={"dishes": [{"name": "A", "description": "B", "price": "$1", "imageUrl": "https://evil.com/x.jpg"}]},
    )
    assert response.status_code == 422


def test_publish_menu_success():
    with patch("server._get_db", return_value=_mock_db):
        response = client.post(
            "/api/publish-menu",
            headers={"x-admin-secret": ADMIN_SECRET},
            json={"dishes": [{"name": "Samosa", "description": "Crispy pyramids", "price": "$6.49", "imageUrl": ""}]},
        )
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
