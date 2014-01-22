Feature: Event
  In order to provide functionality
  As a user of the Vayacondios Api
  I want to document how an Event works

  Scenario: Retrieving an Event without an Id
    Given there are no Events under topic "topic" in the database
    When  the client sends a GET request to "/v2/organization/event/topic" with no body
    Then  the response status should be 400
    And   the response body should be:
    """
    {
      "error": "Cannot find an event without an ID"
    }
    """

  Scenario: Retrieving a non-Existent Event with an Id
    Given there are no Events under topic "topic" in the database
    When  the client sends a GET request to "/v2/organization/event/topic/id" with no body
    Then  the response status should be 404
    And   the response body should be:
    """
    {
      "error": "Event with topic <topic> and ID <id> not found"
    }
    """

  Scenario: Retrieving an Existing Event with an Id
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "time": "2012-02-13T12:34:42.452Z"
      }
    }
    """
    When  the client sends a GET request to "/v2/organization/event/topic/id" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": "id",
      "time": "2012-02-13T12:34:42.452Z"
    }
    """

  Scenario: Creating an Empty Event without an Id
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v2/organization/event/topic" with no body
    Then  the response status should be 200
    And   the response body should contain a generated timestamp
    And   the response body should contain a randomly assigned Id
    And   there is exactly one Event under topic "topic" in the database

  Scenario: Creating a Hash Event without an Id
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v2/organization/event/topic" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 200
    And   the response body should contain:
    """
    { 
      "foo": "bar"
    }
    """
    And   the response body should contain a generated timestamp
    And   the response body should contain a randomly assigned Id
    And   there is exactly one Event under topic "topic" in the database

  Scenario: Creating a Hash Event without an Id, specifying a time
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v2/organization/event/topic" with the following body:
    """
    {
      "foo": "bar",
      "time": "2012-02-13T12:34:42.452Z"
    }
    """
    Then  the response status should be 200
    And   the response body should contain:
    """
    { 
      "foo": "bar",
      "time": "2012-02-13T12:34:42.452Z"
    }
    """
    And   the response body should contain a randomly assigned Id
    And   there is exactly one Event under topic "topic" in the database

  Scenario: Creating a non-Hash Event without an Id
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v2/organization/event/topic" with the following body:
    """
    [
      "foo", 
      "bar"
    ]
    """
    Then  the response status should be 400
    And   the response body should be:
    """
    {
      "error": "Events must be Hash-like to create"
    }
    """
    And   there are no Events under topic "topic" in the database

  Scenario: Creating an Empty Event with an Id
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v2/organization/event/topic/id" with no body
    Then  the response status should be 200
    And   the response body should contain:
    """
    { 
      "id": "id"
    }
    """
    And   the response body should contain a generated timestamp
    And   there should be an Event with Id "id" under topic "topic" in the database

  Scenario: Creating a Hash Event with an Id
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v2/organization/event/topic/id" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 200
    And   the response body should contain:
    """
    { 
      "foo": "bar",
      "id": "id"
    }
    """
    And   the response body should contain a generated timestamp
    And   there should be an Event with Id "id" under topic "topic" in the database

  Scenario: Creating a Hash Event with an Id, specifying a time
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v2/organization/event/topic/id" with the following body:
    """
    {
      "foo": "bar",
      "time": "2012-02-13T12:34:42.452Z"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": "id",
      "foo": "bar",
      "time": "2012-02-13T12:34:42.452Z"
    }
    """
    And   the database should have the following Event under topic "topic":
    """
    {
      "_id": "id",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "foo": "bar"
      }
    }
    """

  Scenario: Creating a non-Hash Event with an Id
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v2/organization/event/topic/id" with the following body:
    """
    [
      "foo", 
      "bar"
    ]
    """
    Then  the response status should be 400
    And   the response body should be:
    """
    {
      "error": "Events must be Hash-like to create"
    }
    """
    And   there are no Events under topic "topic" in the database

  Scenario: Creating an Event with an Id that Already Exists
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "foo": "bar"
      }
    }
    """
    When  the client sends a POST request to "/v2/organization/event/topic/id" with the following body:
    """
    {
      "time": "2013-01-01T00:00:00.000Z",
      "new": "body"      
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": "id",
      "new": "body",
      "time": "2013-01-01T00:00:00.000Z"
    }
    """
    And   the database should have the following Event under topic "topic":
    """
    {
      "_id": "id",
      "_t": "2013-01-01T00:00:00.000Z",
      "_d": {
        "new": "body"
      }
    }
    """

  Scenario: Updating an Event without an Id
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": { }
    }
    """
    When  the client sends a PUT request to "/v2/organization/event/topic" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::EventHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """

  Scenario: Updating an Event with an Id
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "time": "2012-02-13T12:34:42.452Z"
      }
    }
    """
    When  the client sends a PUT request to "/v2/organization/event/topic/id" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::EventHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """

  Scenario: Deleting an Event
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "time": "2012-02-13T12:34:42.452Z"
      }
    }
    """
    When  the client sends a DELETE request to "/v2/organization/event/topic" with no body
    Then  the response status should be 400
    And   the response body should be:
    """
    {
      "error": "An <Id> is required to delete an Event"
    }
    """
    And   there should be an Event with Id "id" under topic "topic" in the database

  Scenario: Deleting an Event with an Id
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "time": "2012-02-13T12:34:42.452Z"
      }
    }
    """
    When  the client sends a DELETE request to "/v2/organization/event/topic/id" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "ok": true
    }
    """
    And   there are no Events under topic "topic" in the database
