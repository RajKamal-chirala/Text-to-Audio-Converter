resource "aws_api_gateway_rest_api" "textToAudioAPI" {
  name = "textToAudioAPI"
}

resource "aws_api_gateway_resource" "textToAudioAPIresource" {
  parent_id   = aws_api_gateway_rest_api.textToAudioAPI.root_resource_id
  path_part   = "textToAudio"
  rest_api_id = aws_api_gateway_rest_api.textToAudioAPI.id
}

resource "aws_api_gateway_method" "get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.textToAudioAPIresource.id
  rest_api_id   = aws_api_gateway_rest_api.textToAudioAPI.id
}

resource "aws_api_gateway_method" "post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.textToAudioAPIresource.id
  rest_api_id   = aws_api_gateway_rest_api.textToAudioAPI.id
}

resource "aws_api_gateway_integration" "getintegration" {
  integration_http_method = "GET"
  http_method             = aws_api_gateway_method.get.http_method
  resource_id             = aws_api_gateway_resource.textToAudioAPIresource.id
  rest_api_id             = aws_api_gateway_rest_api.textToAudioAPI.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.GetPost.invoke_arn

}

resource "aws_api_gateway_integration" "postintegration" {
  integration_http_method = "POST"
  http_method             = aws_api_gateway_method.post.http_method
  resource_id             = aws_api_gateway_resource.textToAudioAPIresource.id
  rest_api_id             = aws_api_gateway_rest_api.textToAudioAPI.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.PostReader.invoke_arn

}


resource "aws_api_gateway_deployment" "apiDeployment" {
  rest_api_id = aws_api_gateway_rest_api.textToAudioAPI.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.textToAudioAPIresource.id,
      aws_api_gateway_method.get.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.getintegration.id,
      aws_api_gateway_integration.postintegration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.apiDeployment.id
  rest_api_id   = aws_api_gateway_rest_api.textToAudioAPI.id
  stage_name    = "dev"
}