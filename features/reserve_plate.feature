Feature: Plate Reservation
  As a hungry user
  I want to reserve an available plate from a posting
  So that I can secure a meal before it runs out

  Scenario: Successfully reserving a plate updates inventory
    Given a posting exists with 2 available plates
    And I am authenticated as a consumer
    When I request to reserve 1 plate from the posting
    Then the reservation is confirmed successfully
    And the posting inventory updates to 1 available plate