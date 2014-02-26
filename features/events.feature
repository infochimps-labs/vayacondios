Feature: Events
  In order to provide functionality
  As a user of the Vayacondios Api
  I want to document how Events work

  Scenario: Retrieving non-Existent Events
    Given there are no Events under topic "topic" in the database
    When  the client sends a GET request to "/v3/organization/events/topic" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    [
    ]
    """

  Scenario: Retrieving Existing Events with a Time Query
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": { }
    }
    """
    And   the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id2",
      "_t": "2010-02-13T12:34:42.452Z",
      "_d": { }
    }
    """
    When  the client sends a GET request to "/v3/organization/events/topic" with the following body:
    """
    {
      "after": "2012-01-01T00:00:00.000Z"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    [
      {
        "id": "id1",
        "time": "2012-02-13T12:34:42.452Z"
      }
    ]
    """

  Scenario: Retrieving Existing Events with a Data Query
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment": "good"
      }
    }
    """
    And   the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id2",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment": "evil"
      }
    }
    """
    When  the client sends a GET request to "/v3/organization/events/topic" with the following body:
    """
    {
      "alignment": "good"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    [
      {
        "id": "id1",
        "time": "2012-02-13T12:34:42.452Z",
        "alignment": "good"
      }
    ]
    """

  Scenario: Retrieving Existing Events with a Limit Query
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment": "good"
      }
    }
    """
    And   the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id2",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment": "evil"
      }
    }
    """
    When  the client sends a GET request to "/v3/organization/events/topic" with the following body:
    """
    {
      "sort": "alignment",
      "order": "desc",
      "limit": 1
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    [
      {
        "id": "id1",
        "time": "2012-02-13T12:34:42.452Z",
        "alignment": "good"
      }
    ]
    """

  Scenario: Retrieving Existing Events with a Sort Query
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:43.452Z",
      "_d": {
        "alignment": "good"
      }
    }
    """
    And   the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id2",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment": "neutral"
      }
    }
    """
    And   the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id3",
      "_t": "2012-02-13T12:34:45.452Z",
      "_d": {
        "alignment": "evil"
      }
    }
    """
    When  the client sends a GET request to "/v3/organization/events/topic" with the following body:
    """
    {
      "sort": "alignment",
      "order": "asc"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    [
      {
        "id": "id3",
        "time": "2012-02-13T12:34:45.452Z",
        "alignment": "evil"
      },
      {
        "id": "id1",
        "time": "2012-02-13T12:34:43.452Z",
        "alignment": "good"
      },
      {
        "id": "id2",
        "time": "2012-02-13T12:34:42.452Z",
        "alignment": "neutral"
      }
    ]
    """

  Scenario: Retrieving Existing Events with a Fields Query
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment": "good"
      }
    }
    """
    And   the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id2",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment": "evil"
      }
    }
    """
    When  the client sends a GET request to "/v3/organization/events/topic" with the following body:
    """
    {
      "alignment": "good",
      "fields": ["alignment", "id"]
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    [
      {
        "id": "id1",
        "alignment": "good"
      }
    ]
    """

  Scenario: Creating Events
    Given there are no Events under topic "topic" in the database
    When  the client sends a POST request to "/v3/organization/events/topic" with no body
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation create not allowed for Vayacondios::Server::EventsHandler. Valid operations are [\"search\", \"retrieve\", \"delete\"]"
    }
    """
    And   there are no Events under topic "topic" in the database

  Scenario: Updating Events
    Given there are no Events under topic "topic" in the database
    When  the client sends a PUT request to "/v3/organization/events/topic" with no body
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::EventsHandler. Valid operations are [\"search\", \"retrieve\", \"delete\"]"
    }
    """
    And   there are no Events under topic "topic" in the database

  Scenario: Deleting Events
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": { }
    }
    """
    And the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id2",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": { }
    }
    """
    When  the client sends a DELETE request to "/v3/organization/events/topic" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "ok": true
    }
    """
    And   there are no Events under topic "topic" in the database

  Scenario: Deleting Events with a Time Query
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": { }
    }
    """
    And the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id2",
      "_t": "2010-02-13T12:34:42.452Z",
      "_d": { }
    }
    """
    When  the client sends a DELETE request to "/v3/organization/events/topic" with the following body:
    """
    {
      "after": "2012-01-01T00:00:00.000Z"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "ok": true
    }
    """
    And   there should not be an Event with Id "id1" under topic "topic" in the database
    And   there should be an Event with Id "id2" under topic "topic" in the database

  Scenario: Deleting Events with a Data Query
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment":"good"
      }
    }
    """
    And the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id2",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "alignment":"evil"
      }
    }
    """
    When  the client sends a DELETE request to "/v3/organization/events/topic" with the following body:
    """
    {
      "alignment":"good"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "ok": true
    }
    """
    And   there should not be an Event with Id "id1" under topic "topic" in the database
    And   there should be an Event with Id "id2" under topic "topic" in the database
