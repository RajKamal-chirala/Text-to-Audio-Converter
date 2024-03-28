resource "random_id" "id2" {
  byte_length = 16
}
resource "aws_s3_bucket" "StaticWebsiteBucket" {
  bucket = "texttoaudiostaticbucket-${random_id.id2.hex}"
}

resource "aws_s3_bucket_ownership_controls" "StaticWebsiteBucket" {
  bucket = aws_s3_bucket.StaticWebsiteBucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "StaticWebsiteBucket" {
  bucket = aws_s3_bucket.StaticWebsiteBucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "StaticWebsiteBucket" {
  depends_on = [aws_s3_bucket_ownership_controls.StaticWebsiteBucket,
    aws_s3_bucket_public_access_block.StaticWebsiteBucket,
  ]

  bucket = aws_s3_bucket.StaticWebsiteBucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "host_bucket_policy" {
  bucket = aws_s3_bucket.StaticWebsiteBucket.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicReadGetObject",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : [
            "s3:GetObject"
          ],
          "Resource" : [
            "arn:aws:s3:::texttoaudiostaticbucket-${random_id.id2.hex}/*"
          ]
        }
      ]
  })
}

module "template_files" {
  source   = "hashicorp/dir/template"
  base_dir = "${path.module}/web files"
}

resource "aws_s3_bucket_website_configuration" "web-config" {
  bucket = aws_s3_bucket.StaticWebsiteBucket.id

  index_document {
    suffix = "index.html"
  }

}

resource "aws_s3_object" "Bucket_files" {
  bucket       = aws_s3_bucket.StaticWebsiteBucket.id
  for_each     = module.template_files.files
  key          = each.key
  content_type = each.value.content_type
  source       = each.value.source_path
  content      = each.value.content

  # etag is known as entity tag
  etag = each.value.digests.md5
  acl = "public-read"
}
