#!/usr/bin/env bash
# Manual curl snippets for quick testing (replace tokens and IDs)
BASE="http://localhost:3000"

echo "1) Register passenger"
curl -s -X POST "$BASE/api/auth/register" -H "Content-Type: application/json" -d '{
  "first_name":"Test","last_name":"Passenger","phone":"+905001234567","password":"password123","role":"passenger"
}' | jq

echo "2) Login passenger"
curl -s -X POST "$BASE/api/auth/login" -H "Content-Type: application/json" -d '{
  "phone":"+905001234567","password":"password123"
}' | jq

echo "3) Register driver"
curl -s -X POST "$BASE/api/auth/register" -H "Content-Type: application/json" -d '{
  "first_name":"Test","last_name":"Driver","phone":"+905001234568","password":"password123","role":"driver"
}' | jq

echo "4) Login driver"
curl -s -X POST "$BASE/api/auth/login" -H "Content-Type: application/json" -d '{
  "phone":"+905001234568","password":"password123"
}' | jq

echo "5) Create ride (use passenger token in Authorization header)"
# Example body:
# {
#  "start": {"lat": 41.016, "lng": 28.98, "address": "Start"},
#  "end": {"lat": 41.02, "lng": 28.99, "address": "End"},
#  "vehicle_type": "sari",
#  "options": {"meterOn":true},
#  "payment_method": "nakit"
# }