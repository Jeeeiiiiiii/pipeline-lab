"""Not part of the app. Scanned only when PLANT_VULN=1, so the SAST gate
can be watched failing. Every line here is something Semgrep should catch."""

import subprocess

from flask import Flask, request

app = Flask(__name__)

AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"  # hardcoded credential
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"


@app.get("/run")
def run():
    cmd = request.args.get("cmd", "")
    return subprocess.check_output(cmd, shell=True)  # command injection
