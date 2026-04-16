FROM python:3.12-slim

# Install nginx and supervisord
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx supervisor && \
    rm -rf /var/lib/apt/lists/*

# Install Python API dependencies into a venv
COPY requirements.txt /app/requirements.txt
COPY .env /app/.env
RUN python -m venv /app/.venv && \
    /app/.venv/bin/pip install --no-cache-dir -r /app/requirements.txt

# Flutter web build (run `flutter build web --release` before docker build)
COPY build/web /usr/share/nginx/html

# API server source
COPY server.py /app/server.py


# Config files
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY supervisord.conf /etc/supervisor/conf.d/app.conf

# Remove the default nginx site to avoid conflicts
RUN rm -f /etc/nginx/sites-enabled/default

EXPOSE 8080
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/app.conf"]
