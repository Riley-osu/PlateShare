from behave import given, when, then
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

from main import app 

client = TestClient(app)

@given('I am logged in as a valid student user')
def step_given_logged_in_user(context):
    # In a real API, this might set a mocked JWT token
    context.user_id = "student_user_123"
    context.headers = {"Authorization": f"Bearer {context.user_id}"}

@given('a food listing for "{food_name}" is visible')
def step_given_food_listing(context, food_name):
    # This represents the listing the user intends to reserve
    context.listing_id = f"listing_{food_name.lower().replace(' ', '_')}_001"
    context.food_name = food_name

@when('I tap the "Reserve Slot" button on the "{food_name}" listing')
def step_when_reserve_slot(context, food_name):
    # We patch the database helper functions that control reservations
    with patch('firebaseHelper._change_reservations') as mock_change_reservations:
        
        # Simulate a successful decrement of the quantity to 1 remaining
        mock_change_reservations.return_value = {
            "status": 200, 
            "message": 1  # 1 slot remaining
        }
        
        # Submitting to the backend API reservation endpoint
        # (Assuming you expose `add_reservation` via POST /api/listings/{id}/reserve)
        form_data = {"amount": 1}
        context.response = client.post(
            f"/api/listings/{context.listing_id}/reserve", 
            json=form_data,
            headers=context.headers
        )

@then('I should see a success snackbar "{message}"')
def step_then_success_snackbar(context, message):
    data = context.response.json()
    assert data.get("status") == "success", f"Expected success status, got: {data}"
    # The message assertion checks that the API returned the expected success string
    assert data.get("message") == message

@then('the "{food_name}" listing should display {count:d} slots remaining')
def step_then_remaining_slots(context, food_name, count):
    data = context.response.json()
    assert data.get("remaining_spots") == count, f"Expected {count} spots, got {data.get('remaining_spots')}"