"""The smallest app that can prove a platform works.

Four routes, each there to light up one part of the stack:

  GET /          hello, the deploy landed
  GET /work      needs the API key from Secrets Manager; sleeps a random
                 amount so latency histograms and traces have a shape
  GET /boom      returns 500, so the error-rate alert can be tripped on demand
  GET /healthz   liveness/readiness
  GET /metrics   Prometheus scrape target (prometheus-flask-exporter)

Every request is traced (OpenTelemetry -> Tempo) and logged as one JSON
line carrying the trace id (stdout -> Promtail -> Loki), so Grafana can jump
from a log line to its trace and from a trace to the logs around it.
"""

import json
import logging
import os
import random
import sys
import time
from datetime import datetime, timezone

from flask import Flask, jsonify, request
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_flask_exporter import PrometheusMetrics

SERVICE = os.environ.get("SERVICE_NAME", "pipeline-lab-app")
VERSION = os.environ.get("APP_VERSION", "dev")
OTLP_ENDPOINT = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT")  # unset = no traces

# Accepted bearer tokens. Both come from Secrets Manager via ESO; neither is
# in the image or the chart.
ACCEPTED_TOKENS = {t for t in (os.environ.get("API_KEY"), os.environ.get("DAST_TOKEN")) if t}

# --- tracing ---------------------------------------------------------------

provider = TracerProvider(resource=Resource.create({SERVICE_NAME: SERVICE, "service.version": VERSION}))
if OTLP_ENDPOINT:
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=OTLP_ENDPOINT, insecure=True)))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(SERVICE)

# --- logging: one JSON line per event, trace id attached -----------------


class JsonFormatter(logging.Formatter):
    def format(self, record):
        span = trace.get_current_span().get_span_context()
        entry = {
            "ts": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
            "level": record.levelname,
            "service": SERVICE,
            "msg": record.getMessage(),
        }
        if span.is_valid:
            entry["trace_id"] = format(span.trace_id, "032x")
            entry["span_id"] = format(span.span_id, "016x")
        if hasattr(record, "fields"):
            entry.update(record.fields)
        return json.dumps(entry)


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=logging.INFO, handlers=[handler])
log = logging.getLogger(SERVICE)


def log_event(msg, **fields):
    log.info(msg, extra={"fields": fields})


# --- app -------------------------------------------------------------------

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app, excluded_urls="healthz,metrics")
metrics = PrometheusMetrics(app, group_by="endpoint", default_labels={"version": VERSION})
metrics.info("app_info", "Application info", version=VERSION)


@app.after_request
def security_headers(resp):
    # The first DAST run flagged every one of these as missing. For a JSON
    # API they cost nothing and close four of its five warnings; the fifth
    # (non-storable content) is a property, not a problem.
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
    resp.headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()"
    resp.headers["Cross-Origin-Resource-Policy"] = "same-origin"
    resp.headers["Cache-Control"] = "no-store"
    return resp


def authorized():
    auth = request.headers.get("Authorization", "")
    return auth.startswith("Bearer ") and auth[7:] in ACCEPTED_TOKENS


@app.get("/")
def index():
    log_event("hello", path="/")
    return jsonify(service=SERVICE, version=VERSION, message="hello from the pipeline")


@app.get("/work")
def work():
    if not authorized():
        log_event("unauthorized", path="/work")
        return jsonify(error="bearer token required"), 401

    with tracer.start_as_current_span("do-work") as span:
        delay = random.uniform(0.05, 0.4)
        span.set_attribute("work.delay_ms", round(delay * 1000))
        time.sleep(delay)

    log_event("work done", delay_ms=round(delay * 1000))
    return jsonify(done=True, delay_ms=round(delay * 1000))


@app.get("/boom")
def boom():
    log_event("boom", path="/boom", level="ERROR")
    return jsonify(error="deliberate failure"), 500


@app.get("/healthz")
@metrics.do_not_track()
def healthz():
    return jsonify(status="ok")
