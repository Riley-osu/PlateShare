Feature: Create Food Listing

  Scenario: A valid organization creates a food listing without an image
    Given a valid organization ID "org_12345"
    When I submit a new food listing for "Fresh Pasta" at "Student Union"
    Then the response status should be 200
    And the response should return a success status with a new listing ID