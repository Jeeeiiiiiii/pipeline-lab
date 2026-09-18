# The self-hosted GitHub Actions runner, with every tool the pipeline uses
# installed. The same image is the "toolbox" for running the pipeline by
# hand, so a stage behaves identically on a push and on the laptop.
#
# Tools that need the host Docker daemon (build, push, ZAP) use the socket
# mounted by docker-compose.yml. Everything else is a plain binary here.
FROM myoung34/github-runner:ubuntu-noble

ARG KUBECTL_VERSION=v1.31.4
ARG HELM_VERSION=v3.16.4
ARG TRIVY_VERSION=0.74.0
ARG SEMGREP_VERSION=1.177.0
ARG TERRAFORM_VERSION=1.10.3

USER root
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip unzip \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar -xz -C /tmp \
 && mv /tmp/linux-amd64/helm /usr/local/bin/helm && rm -rf /tmp/linux-amd64

RUN curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" | tar -xz -C /usr/local/bin trivy

RUN curl -fsSLo /tmp/tf.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
 && unzip -q /tmp/tf.zip -d /usr/local/bin && rm /tmp/tf.zip

# The AWS CLI v2 is already in the base image.

RUN pip3 install --no-cache-dir --break-system-packages "semgrep==${SEMGREP_VERSION}" \
 || pip3 install --no-cache-dir "semgrep==${SEMGREP_VERSION}"

# Trivy's vulnerability database, so the first scan does not spend a minute
# downloading it. Refreshed automatically when stale.
RUN trivy image --download-db-only --quiet || true
