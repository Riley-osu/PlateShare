from behave import given, when, then
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

from main import app

client = TestClient(app)

@given('an active listing exists with the ID "{listing_id}"')
def step_given_active_listing(context, listing_id):
    context.listing_id = listing_id
    context.headers = {"Authorization": "Bearer org_user_123"}

@when('I submit a DELETE request for the listing ID "{listing_id}"')
def step_when_delete_listing(context, listing_id):
    
    with patch('main.firebaseHelper.delete_listing') as mock_delete_listing:
        # Mock the helper returning a successful deletion status
        mock_delete_listing.return_value = {"status": 200, "message": "No Content"}
        
        context.response = client.delete(
            f"/api/listings/{listing_id}",
            headers=context.headers
        )

@then('the response status should be {status_code:d}')
def step_then_status_code(context, status_code):
    assert context.response.status_code == status_code, f"Expected {status_code}, got {context.response.status_code}"

@then('the API should return a success message confirming deletion')
def step_then_confirm_deletion(context):
    data = context.response.json()
    assert data.get("status") == "success"
    assert data.get("message") == f"Listing {context.listing_id} deleted"