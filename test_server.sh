#!/bin/bash

# Test script for Emotion Resonance API Server

echo "🧪 Testing Emotion Resonance API Server..."
echo ""

# Check if server is running
echo "1️⃣ Health Check..."
curl -s http://localhost:8080/health | jq .
echo ""

# Send test data
echo "2️⃣ Sending test data..."
curl -X POST http://localhost:8080/api/staytime \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "test_device",
    "corner_times": {
      "top-left": 10,
      "top-right": 20,
      "bottom-left": 5,
      "bottom-right": 15
    }
  }' | jq .
echo ""

# Get all data
echo "3️⃣ Getting all data..."
curl -s http://localhost:8080/api/staytime | jq .
echo ""

# Get specific device data
echo "4️⃣ Getting test_device data..."
curl -s http://localhost:8080/api/staytime/test_device | jq .
echo ""

echo "✅ Test complete!"
