# ---------------------------------------------------------------------------
# Secrets. Generated here, stored in Secrets Manager, never written to git
# or to a values file. The cluster pulls them at runtime through the
# External Secrets Operator (see platform/external-secrets.yaml), which
# turns each one into a Kubernetes Secret the workload mounts.
#
# In Terraform state the values are present (state is itself a secret and
# belongs in an encrypted backend in a real account). In the console they are
# hidden until you ask.
# ---------------------------------------------------------------------------

resource "random_password" "app_api_key" {
  length  = 32
  special = false
}

resource "random_password" "grafana_admin" {
  length  = 20
  special = false
}

resource "random_password" "dast_token" {
  length  = 32
  special = false
}

# The app refuses /work without this key. It is how the demo shows the
# secret arrived: the request works only if ESO delivered it.
resource "aws_secretsmanager_secret" "app_api_key" {
  name                    = "${var.name}/app/api-key"
  description             = "API key the app requires on /work"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_api_key" {
  secret_id     = aws_secretsmanager_secret.app_api_key.id
  secret_string = random_password.app_api_key.result
}

resource "aws_secretsmanager_secret" "grafana_admin" {
  name                    = "${var.name}/grafana/admin"
  description             = "Grafana admin credentials, as the key/value pair the chart expects"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = aws_secretsmanager_secret.grafana_admin.id
  secret_string = jsonencode({
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  })
}

# What the DAST stage sends as its bearer token so the scan can reach the
# authenticated endpoints. Same value as the app key would also work; a
# separate secret means the scanner's credential can be rotated alone.
resource "aws_secretsmanager_secret" "dast_token" {
  name                    = "${var.name}/dast/token"
  description             = "Bearer token the DAST scan uses against /work"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "dast_token" {
  secret_id     = aws_secretsmanager_secret.dast_token.id
  secret_string = random_password.dast_token.result
}
