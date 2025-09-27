package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
)

var logger = GetLogger()

var (
	ErrMalformedHeader = errors.New("Malformed or missing authentication header")
	ErrInvalidToken    = errors.New("Token is invalid or expired")
)

func CreateResponseWithStatus(status int) events.APIGatewayProxyResponse {
	return events.APIGatewayProxyResponse{StatusCode: status}
}

func GetAuthenticatedUserEmail(token string) (string, bool) {
	dynamoDBClient := GetDynamoDBClient()
	result, err := dynamoDBClient.GetItem(&dynamodb.GetItemInput{
		TableName: aws.String("token-email-lookup"),
		Key: map[string]*dynamodb.AttributeValue{
			"token": {S: aws.String(token)},
		},
	})

	if err != nil {
		logger.Println("DynamoDB GetItem Error:", err)
		return "", false
	}

	if result.Item == nil {
		return "", false
	}

	var item TokenLookupItem
	if err := dynamodbattribute.UnmarshalMap(result.Item, &item); err != nil {
		logger.Println("Unmarshal Error:", err)
		return "", false
	}

	if item.Token == token {
		return item.Email, true
	}
	return "", false
}

func parseStartKey(startKeyStr, email string) (map[string]*dynamodb.AttributeValue, error) {
  if startKeyStr == ""{
    return nil, nil
  }
	var data map[string]string
	if err := json.Unmarshal([]byte(startKeyStr), &data); err != nil {
		return nil, err
	}

	createDate, ok := data["create_date"]
	if !ok || createDate == "" {
		return nil, errors.New("missing create_date in startKey")
	}

	return map[string]*dynamodb.AttributeValue{
		"user":        {S: aws.String(email)},
		"create_date": {S: aws.String(createDate)},
	}, nil
}

func QueryUserNotes(email string) ([]UserNote, error) {
	dynamoDBClient := GetDynamoDBClient()

	input := &dynamodb.QueryInput{
		TableName:              aws.String("user-notes"),
		KeyConditionExpression: aws.String("#usr = :email"),
		ExpressionAttributeNames: map[string]*string{
			"#usr": aws.String("user"), 
		},
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":email": {S: aws.String(email)},
		},
		ScanIndexForward: aws.Bool(false),
		Limit:            aws.Int64(10),
	}

	result, err := dynamoDBClient.Query(input)
	if err != nil {
		logger.Println("Error querying user notes:", err)
		return nil, err
	}

	var notes []UserNote
	if err := dynamodbattribute.UnmarshalListOfMaps(result.Items, &notes); err != nil {
		logger.Println("Unmarshal Error:", err)
		return nil, err
	}

  return notes, nil
}

func AuthenticateUser(headers map[string]string) (string, error) {
	authHeader, ok := headers["Authentication"]
	if !ok || !strings.HasPrefix(authHeader, "Bearer ") {
		return "", ErrMalformedHeader
	}

	token := strings.TrimPrefix(authHeader, "Bearer ")
	if token == "" {
		return "", ErrInvalidToken
	}

	email, ok := GetAuthenticatedUserEmail(token)
	if !ok {
		return "", ErrInvalidToken
	}
	return email, nil
}

func Handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	email, err := AuthenticateUser(request.Headers)
	if err != nil {
		if errors.Is(err, ErrMalformedHeader) {
			return CreateResponseWithStatus(400), nil
		}
		return CreateResponseWithStatus(403), nil
	}

	notes, err := QueryUserNotes(email)
	if err != nil {
		return CreateResponseWithStatus(500), nil
	}

	body, err := json.Marshal(notes)
	if err != nil {
		return CreateResponseWithStatus(500), nil
	}

	var buf bytes.Buffer
	json.HTMLEscape(&buf, body)

	return events.APIGatewayProxyResponse{
		StatusCode:      200,
		Body:            buf.String(),
		IsBase64Encoded: false,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
	}, nil
}

func main() {
	lambda.Start(Handler)
}
