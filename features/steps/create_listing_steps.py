from behave import given, when, then
from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock

from main import app 

client = TestClient(app)

@given('a valid organization ID "{org_id}"')
def step_given_valid_org(context, org_id):
    context.org_id = org_id

@when('I submit a new food listing for "{food_name}" at "{location}"')
def step_when_submit_listing(context, food_name, location):
    
    with patch('main.geocodeAddress', new_callable=AsyncMock) as mock_geocode, \
         patch('main.firebaseHelper.create_listing') as mock_create_listing:
        
        mock_geocode.return_value = (40.7128, -74.0060)
        
        mock_create_listing.return_value = {
            "status": 200, 
            "message": "mocked_listing_id_999"
        }
        
        form_data = {
            "foodName": food_name,
            "description": "fresh pasta",
            "createdAt": "2026-11-10T12:00:00Z",
            "location": location,
            "organizationID": context.org_id,
            "pickupStart": "2026-11-10T14:00:00Z",
            "pickupEnd": "2026-11-10T16:00:00Z", # Added this to fix the missing variable
            "quantity": 10,
            "reservationCount": 1,
            "status": "available"
        }

        context.response = client.post("/api/listings", data=form_data)

@then('the response status should be {status_code:d}')
def step_then_status_code(context, status_code):
    assert context.response.status_code == status_code, f"Expected {status_code}, got {context.response.status_code}. Detail: {context.response.text}"

@then('the response should return a success status with a new listing ID')
def step_then_response_content(context):
    data = context.response.json()
    
    assert data["status"] == "success"
    assert data["listingID"] == "mocked_listing_id_999"
    assert data["aiResponse"]["safe"] is True  

    