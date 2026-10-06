---
version: 1
slug: "ops-index-html"
primary_target: "ops/index.html"
related_targets: ["ops/server.py"]
---

Scope: ops/index.html, the pipeline-lab operating theatre. Mode: Operate.
Audience: the lab's owner, a DevOps engineer learning CI/CD gates and observability; job: run the pipeline and watch each stage, plant a vulnerability and watch the gates refuse it, break the app and watch the alert fire.

## Direction contract

THESIS: A deployment is an operation. The scans are the sign-in checklist with a GO / NO-GO each; build, push and deploy are the procedure, each step timed and signed; the running app is the patient on a bedside monitor whose error-rate trace sets off the alarm. Refuses the category default of stage boxes with a log pane and Grafana-style charts.

OWN-WORLD: A theatre whiteboard and a printed WHO-style checklist on clinical green-grey, ruled tick boxes signed with the stage's own outcome; a black bedside monitor with a phosphor trace, numeric readouts and the alarm colours (yellow warning, red alarm) reserved for the alert; scrub-blue for the one primary action.

STORY: Choose the procedure (full run, or scan-only with the planted vulnerability); watch each checklist line tick GO or stop at NO-GO with the finding that stopped it; nothing pushed after a NO-GO; then on the monitor, induce failure (/boom) and watch the trace climb, the warning, then the alarm after 1m.

FIRST VIEWPORT: Theatre header with the patient's chart (image tag, release, ECR, cluster); the checklist (sign in: prepare, sast, iac, build, image-scan; procedure: push, deploy; sign out: dast, publish) on the left; the bedside monitor on the right with the error-rate trace, request rate, alert state, and the controls to send traffic or failures.

FORM: Operating Theatre, 6 of 7 on the ordered list. Seed key 75e57958.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
