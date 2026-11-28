Feature: Delete Listing
  As an organization
  I want to delete my active food listing
  So that users stop attempting to reserve food that is no longer available

  Scenario: Successfully deleting a listing cleans up associated data
    Given an active listing exists with the ID "mocked_delete_target"
    When I submit a DELETE request for the listing ID "mocked_delete_target"
    Then the response status should be 200
    And the API should return a success message confirming deletion