# S3 웹사이트 정책 정의 (퍼블릭 읽기 허용)
data "aws_iam_policy_document" "s3_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.site.arn,
      "${aws_s3_bucket.site.arn}/*",
    ]
  }
}

# 1. 정적 웹사이트 콘텐츠를 저장할 S3 버킷 생성
resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name # 버킷 이름은 전역적으로 고유해야 함

  tags = {
    Name = "Static Content Storage"
  }
}

# 2. S3 버킷에 대한 Public Access 차단 설정
resource "aws_s3_bucket_public_access_block" "site_block" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3. 버킷 정책 적용
resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# 4. 버킷 버전 관리 활성화
resource "aws_s3_bucket_versioning" "site_versioning" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 5. 웹사이트 호스팅 설정
resource "aws_s3_bucket_website_configuration" "site_website" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}