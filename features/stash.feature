Feature: Stash
  In order to provide functionality
  As a user of the Vayacondios Api
  I want to document how a Stash works

  Scenario: Retrieving a non-Existent Stash
    Given there are no matching Stashes in the database
    When  the client sends a GET request to "/v3/organization/stash/topic" with no body
    Then  the response status should be 404
    And   the response body should be:
    """
    {
      "error": "Stash with topic <topic> not found"
    }
    """

  Scenario: Retrieving an Existing Stash
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a GET request to "/v3/organization/stash/topic" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "foo": "bar"
    }
    """

  Scenario: Retrieving a non-Existent Stash with an Id
    Given there are no matching Stashes in the database
    When  the client sends a GET request to "/v3/organization/stash/topic/id" with no body
    Then  the response status should be 404
    And   the response body should be:
    """
    {
      "error": "Stash with topic <topic> not found"
    }
    """

  Scenario: Retrieving an Existing Stash with an Id
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "sub": {
        "foo": "bar"
      }
    }
    """
    When  the client sends a GET request to "/v3/organization/stash/topic/sub" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "foo":"bar"
    }
    """

  Scenario: Creating an Empty Stash without an Id
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v3/organization/stash/topic" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
    }
    """
    And   the database should have the following Stash:
    """
    {
      "_id": "topic"
    }
    """

  Scenario: Creating a Stash without an Id
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v3/organization/stash/topic" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "foo": "bar"
    }
    """
    And   the database should have the following Stash:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """

  Scenario: Creating a non-Hash Stash without an Id
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v3/organization/stash/topic" with the following body:
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
      "error": "If not including an Id, the document must be a Hash"
    }
    """

  Scenario: Creating a Stash without an Id when one Already Exists
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a POST request to "/v3/organization/stash/topic" with the following body:
    """
    {
      "new": "body"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "new": "body"
    }
    """
    And   the database should have the following Stash:
    """
    {
      "_id": "topic",
      "new": "body"
    }
    """

  Scenario: Creating an Empty Stash With an Id
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v3/organization/stash/topic/id" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": {}
    }
    """
    And the database should have the following Stash:
    """
    {
      "_id": "topic",
      "id": {}      
    }
    """

  Scenario: Creating a Stash With an Id
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v3/organization/stash/topic/id" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": {
        "foo": "bar"
      }
    }
    """
    And the database should have the following Stash:
    """
    {
      "_id": "topic",
      "id": {
        "foo": "bar" 
      }
    }
    """

  Scenario: Creating an Array Stash With an Id
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v3/organization/stash/topic/id" with the following body:
    """
    [
      "foo",
      "bar"
    ]
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": [
        "foo", 
        "bar"
      ]
    }
    """
    And the database should have the following Stash:
    """
    {
      "_id": "topic",
      "id": [
        "foo",
        "bar" 
      ]
    }
    """

  Scenario: Creating an String Stash With an Id
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v3/organization/stash/topic/id" with the following body:
    """
    "HELLO"
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": "HELLO"
    }
    """
    And the database should have the following Stash:
    """
    {
      "_id": "topic",
      "id": "HELLO"
    }
    """

  Scenario: Creating an nil Stash With an Id
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v3/organization/stash/topic/id" with the following body:
    """
    "null"
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": "null"
    }
    """
    And the database should have the following Stash:
    """
    {
      "_id": "topic",
      "id": "null"
    }
    """

  Scenario: Creating a Stash With an Id when one Already Exists
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "id": {
        "foo": "bar"
      }
    }
    """
    When  the client sends a POST request to "/v3/organization/stash/topic/id" with the following body:
    """
    {
      "new": "body"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "id": {
        "new": "body"
      }
    }
    """
    And   the database should have the following Stash:
    """
    {
      "_id": "topic",
      "id": {
        "new": "body"
      }
    }
    """

  Scenario: Updating a non-Existent Stash with a Hash
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v3/organization/stash/topic" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "foo": "bar"
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "foo": "bar"
    # }
    # """

  Scenario: Updating an Existing Stash with a Hash
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a PUT request to "/v3/organization/stash/topic" with the following body:
    """
    {
      "baz": "qix"
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "foo": "bar",
    #   "baz": "qix"
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "foo": "bar",
    #   "baz": "qix"
    # }
    # """

  Scenario: Updating an Stash with a non-Hash
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v3/organization/stash/topic" with the following body:
    """
    [
      "foo",
      "bar"
    ]
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 400
    # And   the response body should be:
    # """
    # {
    #   "error": "If not including an id the document must be a Hash"
    # }
    # """
    # And   there are no Stashes in the database

  Scenario: Updating an non-Existent Stash Using an Id with an Empty Hash
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with no body
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": {}
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": {}      
    # }
    # """

  Scenario: Updating an Existing Stash Using an Id with an Empty Hash
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "id": "yolo"
    }
    """
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with no body
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": {}
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": {}      
    # }
    # """

  Scenario: Updating an non-Existent Stash Using an Id with a Hash
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": {
    #     "foo": "bar"
    #   }
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": {
    #     "foo": "bar" 
    #   }
    # }
    # """

  Scenario: Updating an Existing Stash Using an Id with a Hash
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "id": "yolo"
    }
    """
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": {
    #     "foo": "bar"
    #   }
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": {
    #     "foo": "bar" 
    #   }
    # }
    # """

  Scenario: Updating an non-Existent Stash Using an Id with an Array
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with the following body:
    """
    [
      "foo",
      "bar"
    ]
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": [
    #     "foo", 
    #     "bar"
    #   ]
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": [
    #     "foo",
    #     "bar" 
    #   ]
    # }
    # """

  Scenario: Updating an Existing Stash Using an Id with an Array
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "id": "yolo",
      "foo": "bar"
    }
    """
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with the following body:
    """
    [
      "foo",
      "bar"
    ]
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": [
    #     "foo", 
    #     "bar"
    #   ],
    #   "foo": "bar"
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": [
    #     "foo",
    #     "bar" 
    #   ],
    #   "foo": "bar"
    # }
    # """

  Scenario: Updating an non-Existent Stash Using an Id with a String
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with the following body:
    """
    "HELLO"
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": "HELLO"
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": "HELLO"
    # }
    # """

  Scenario: Updating an Existing Stash Using an Id with a String
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "id": "yolo"
    }
    """
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with the following body:
    """
    "HELLO"
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": "HELLO"
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": "HELLO"
    # }
    # """

  Scenario: Updating an non-Existent Stash Using an Id with a nil
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with the following body:
    """
    "null"
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": "null"
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": "null"
    # }
    # """

  Scenario: Updating an Existing Stash Using an Id with a nil
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "id": "yolo"
    }
    """
    When  the client sends a PUT request to "/v3/organization/stash/topic/id" with the following body:
    """
    "null"
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error":"Operation update not allowed for Vayacondios::Server::StashHandler. Valid operations are [\"create\", \"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "id": "null"
    # }
    # """
    # And the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "id": "null"
    # }
    # """

  Scenario: Deleting a non-Existent Stash
    Given there are no matching Stashes in the database
    When  the client sends a DELETE request to "/v3/organization/stash/topic" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "ok": true
    }
    """    

  Scenario: Deleting an Existing Stash without an Id
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a DELETE request to "/v3/organization/stash/topic" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "ok": true
    }
    """
    And   there are no Stashes in the database

  Scenario: Deleting a non-Existent Stash with an Id
    Given there are no matching Stashes in the database
    When  the client sends a DELETE request to "/v3/organization/stash/topic/id" with no body
    Then  the response status should be 501
    And   the response body should be:
    """
    {
      "error": "Deleting an Id from a Stash is not supported"
    }
    """

    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "ok": true
    # }
    # """

  Scenario: Deleting a Existent Stash with a non-Existent Id
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a DELETE request to "/v3/organization/stash/topic/id" with no body
    Then  the response status should be 501
    And   the response body should be:
    """
    {
      "error": "Deleting an Id from a Stash is not supported"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "ok": true
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "foo": "bar"
    # }
    # """

  Scenario: Deleting a Existent Stash with an Existent Id
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "id": "data",
      "foo": "bar"
    }
    """
    When  the client sends a DELETE request to "/v3/organization/stash/topic/id" with no body
    Then  the response status should be 501
    And   the response body should be:
    """
    {
      "error": "Deleting an Id from a Stash is not supported"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    #   "ok": true
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic",
    #   "foo": "bar"
    # }
    # """
