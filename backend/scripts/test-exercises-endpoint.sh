#!/bin/bash

# Test the exercises endpoint
echo "Testing /api/exercises endpoint..."
echo ""

# First login as John
echo "Logging in as john@example.com..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Failed to login. Response:"
  echo $LOGIN_RESPONSE
  exit 1
fi

echo "✅ Login successful, got token"
echo ""

# Test exercises endpoint
echo "Testing GET /api/exercises..."
EXERCISES_RESPONSE=$(curl -s -X GET http://localhost:3001/api/exercises \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "Response:"
echo $EXERCISES_RESPONSE | jq . 2>/dev/null || echo $EXERCISES_RESPONSE
