resource "aws_sns_topic" "post_updates" {
  name         = "new_posts"
  display_name = "New Posts"
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  topic_arn = aws_sns_topic.post_updates.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.PostReader_ConvertToAudio.arn
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.PostReader_ConvertToAudio.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.post_updates.arn
}
