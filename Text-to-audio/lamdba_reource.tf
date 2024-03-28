resource "aws_iam_policy" "policy_one" {
  name = "posts_policy"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Perm1",
          "Effect" : "Allow",
          "Action" : [
            "polly:SynthesizeSpeech",
            "s3:GetBucketLocation",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "Perm2",
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"

          ],
          "Resource" : "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:table/posts"
        },
        {
          "Sid" : "Perm3",
          "Effect" : "Allow",
          "Action" : [
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:GetBucketLocation"
          ],
          "Resource" : "arn:aws:s3:::audioposts-${random_id.id.hex}/*"
        },
        {
          "Sid" : "Perm4",
          "Effect" : "Allow",
          "Action" : [
            "sns:Publish"
          ],
          "Resource" : "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:new_posts"
        }
      ]
    }
  )
}

resource "aws_iam_role" "LambdaReaderRole" {
  name = "LambdaReaderRole"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "role-policy-attach" {
  role       = aws_iam_role.LambdaReaderRole.name
  policy_arn = aws_iam_policy.policy_one.arn
}

resource "aws_lambda_function" "PostReader" {
  filename      = "${path.module}/Python/PostReader.zip"
  function_name = "PostReader"
  role          = aws_iam_role.LambdaReaderRole.arn
  handler       = "PostReader.lambda_handler"
  runtime       = "python3.12"
  depends_on    = [aws_iam_role_policy_attachment.role-policy-attach]

  environment {
    variables = {
      SNS_TOPIC     = "${aws_sns_topic.post_updates.arn}"
      DB_TABLE_NAME = "posts"
    }
  }
}

resource "aws_lambda_function" "PostReader_ConvertToAudio" {
  filename      = "${path.module}/Python/PostReader_ConvertToAudio.zip"
  function_name = "PostReader_ConvertToAudio"
  role          = aws_iam_role.LambdaReaderRole.arn
  handler       = "PostReader_ConvertToAudio.lambda_handler"
  runtime       = "python3.12"
  depends_on    = [aws_iam_role_policy_attachment.role-policy-attach]
  timeout       = 300

  environment {
    variables = {
      DB_TABLE_NAME = "posts"
      BUCKET_NAME   = "audioposts-${random_id.id.hex}"
    }
  }
}

resource "aws_lambda_function" "GetPost" {
  filename      = "${path.module}/Python/GetPost.zip"
  function_name = "GetPost"
  role          = aws_iam_role.LambdaReaderRole.arn
  handler       = "GetPost.lambda_handler"
  runtime       = "python3.12"
  depends_on    = [aws_iam_role_policy_attachment.role-policy-attach]

  environment {
    variables = {
      DB_TABLE_NAME = "posts"
    }
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.PostReader.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.textToAudioAPI.execution_arn}/*/*"
}