# ---------------------------------------------------------------------------
# Artifact stores. Two kinds of pipeline output, two stores.
#
#   ECR  the image -- the thing that gets deployed. Immutable tags: a tag is
#        a commit SHA and can never be re-pushed to mean something else.
#   S3   everything the pipeline learned about that image -- SBOM, SAST and
#        vulnerability reports, the DAST report. Versioned, so a re-run of
#        the same commit does not overwrite what the first run found.
# ---------------------------------------------------------------------------

resource "aws_ecr_repository" "app" {
  name                 = "${var.name}/app"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.name}-app" }
}

# Keep the last 20 images. The pipeline pushes one per commit to main.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep the 20 most recent images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_s3_bucket" "reports" {
  bucket        = "${var.name}-reports"
  force_destroy = true

  tags = { Name = "${var.name}-reports" }
}

resource "aws_s3_bucket_versioning" "reports" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "reports" {
  description             = "${var.name} report bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.reports.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
