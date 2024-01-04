locals {
  BUCKET_NAME = "${var.PROJECT_NAME}-${var.ENV}-${var.RESOURCE_SUFFIX}"
}

#### Bucket S3 ####

resource "aws_s3_bucket" "bucket" {
  bucket = local.BUCKET_NAME
  tags = merge(var.AWS_TAGS, {
    Bucket = local.BUCKET_NAME
  })
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket     = aws_s3_bucket.bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_sse" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecicyle_configuration" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "expires_versioned_objects"
    status = var.ENABLE_EXPIRES_VERSIONED_OBJECTS

    expiration {
      expired_object_delete_marker = true
      days                         = var.DAYS_TO_EXPIRE_VERSIONED_OBJECTS
    }
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }

  rule {
    id     = "move_objects_to_infrequent_access_class"
    status = var.ENABLE_TRANSITION_TO_INFREQUENT_ZONE

    filter {
      prefix = var.TRANSITION_TO_INFREQUENT_ZONE_SETTINGS["prefix"]
    }

    transition {
      days          = var.TRANSITION_TO_INFREQUENT_ZONE_SETTINGS["first_transition_days"]
      storage_class = var.TRANSITION_TO_INFREQUENT_ZONE_SETTINGS["first_transition_storage_class"]
    }

    transition {
      days          = var.TRANSITION_TO_INFREQUENT_ZONE_SETTINGS["second_transition_days"]
      storage_class = var.TRANSITION_TO_INFREQUENT_ZONE_SETTINGS["second_transition_storage_class"]
    }
  }

  rule {
    id     = "archiving"
    status = var.ENABLE_ARCHIVING

    filter {
      prefix = var.ARCHIVING_SETTINGS["prefix"]
    }

    transition {
      days          = var.ARCHIVING_SETTINGS["archiving_days"]
      storage_class = var.ARCHIVING_SETTINGS["archiving_storage_class"]
    }
  }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.ENABLE_VERSIONING
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count = var.CREATE_S3_NOTIFICATION_TOPIC == true ? 1 : 0

  bucket = aws_s3_bucket.bucket.id
  queue {
    queue_arn     = var.S3_NOTIFICATION_QUEUE_ARN
    events        = var.S3_NOTIFICATION_EVENT_LIST
    filter_prefix = var.S3_NOTIFICATION_FILTER_PREFIX
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  count  = var.CREATE_BUCKET_POLICY == true ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  policy = var.BUCKET_POLICY_DOCUMENT
}


