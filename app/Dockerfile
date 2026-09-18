FROM python:3.12-slim

# PLANT_VULN=1 installs a PyYAML with a CRITICAL CVE (CVE-2020-14343) that
# the app never imports. It exists so the image-scan gate can be watched
# failing. Default builds do not include it.
ARG PLANT_VULN=0

# Take the base image's security updates. The image scan fails on any
# CRITICAL that has a fix, and the first run of this pipeline found three
# in perl-base that this line fixes.
RUN apt-get update && apt-get upgrade -y --no-install-recommends && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
 && if [ "$PLANT_VULN" = "1" ]; then pip install --no-cache-dir "pyyaml==5.3.1"; fi

COPY app.py .

# Not root. The scanners flag it otherwise, and they are right to.
RUN useradd --system --uid 10001 app
USER app

EXPOSE 8080
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--access-logfile", "-", "app:app"]
