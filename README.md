# Text-to-Audio-Converter

This project idea is to convert text to audio using polly and other aws services deployed only using terraform.
Required aws services1.

1.S3 Bucket (to store the text data , audio files and for static website hosting)

2.lambda functions (for converting the text to audio and also another function to retrieve the data)

3.DynamoDB

4.Amazon SNS

5.Amazon Polly

6.Amazon API Gateway services

Architecture:

![image](https://github.com/RajKamal-chirala/Text-to-Audio-Converter/assets/109870153/513fa027-30b4-46ee-88c7-67def6ac4e22)
