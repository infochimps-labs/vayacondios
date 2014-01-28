Feature: Stashes
  In order to provide functionality
  As a user of the Vayacondios Api
  I want to document how Stashes work

  Scenario: Retrieving Missing Stashes
    Given there are no matching Stashes in the database
    When  the client sends a GET request to "/v2/organization/stashes" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    [
    ]
    """

  Scenario: Retrieving Existing Stashes
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    And   the following Stash exists in the database:
    """
    {
      "_id": "un_topic",
      "baz": "qix"
    }
    """
    When  the client sends a GET request to "/v2/organization/stashes" with no body
    Then  the response status should be 200
    And   the response body should be:
    """
    [
      {
        "topic": "topic",
        "foo":"bar"
      },
      {
        "topic": "un_topic",
        "baz": "qix"
      }
    ]
    """

  Scenario: Retrieving Nested Stashes
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "root": { 
        "b": 1
      }
    }
    """
    When  the client sends a GET request to "/v2/organization/stashes" with the following body:
    """
    { 
      "root.b": 1 
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    [ 
      {
        "topic": "topic",
        "root": {
          "b": 1
        }
      }
    ]
    """

  Scenario: Retrieving Nested Stashes using Projection
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "root": {
        "a": {
          "foo": "bar"
        },
        "b": 1
      }
    }
    """
    When  the client sends a GET request to "/v2/organization/stashes" with the following body:
    """
    { 
      "root.b": 1,
      "fields": ["root.a"]
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    [
      {
        "topic": "topic",
        "root": {
          "a": {
            "foo": "bar"
          }
        }
      }
    ]
    """

  Scenario: Creating Stashes without a Query
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v2/organization/stashes" with no body
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation create not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    And   there are no Stashes in the database
    # Then  the response status should be 400
    # And   the response body should be:
    # """
    # {
    #   "error": "Query cannot be empty"
    # }
    # """
    # And   there are no Stashes in the database

  Scenario: Creating Stashes with a Malformed Query
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v2/organization/stashes" with the following body:
    """
    {
      "query": "busted"
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation create not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    And   there are no Stashes in the database
    # Then  the response status should be 400
    # And   the response body should be:
    # """
    # {
    #   "error": "Query must be a Hash"
    # }
    # """
    # And   there are no Stashes in the database

  Scenario: Creating Stashes with an Empty Query
    Given there are no matching Stashes in the database
    When  the client sends a POST request to "/v2/organization/stashes" with the following body:
    """
    {
      "query": { }
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation create not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    And   there are no Stashes in the database
    # Then  the response status should be 400
    # And   the response body should be:
    # """
    # {
    #   "error": "Query cannot be empty"
    # }
    # """
    # And   there are no Stashes in the database

  Scenario: Creating Stashes when the Query does not Match
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a POST request to "/v2/organization/stashes" with the following body:
    """
    {
      "query": {
        "foo": "baz"
      },
      "update": {
        "foo": "qix"
      }
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation create not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic"
    #   "foo": "bar"
    # }
    # """

  Scenario: Creating Stashes when the Query does Match
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a POST request to "/v2/organization/stashes" with the following body:
    """
    {
      "query": {
        "foo": "bar"
      },
      "update": {
        "foo": "qix"
      }
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation create not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic"
    #   "foo": "qix"
    # }
    # """

  Scenario: Updating a non-Existent Stash with an Empty Hash
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v2/organization/stashes" with no body
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic"
    # }
    # """

  Scenario: Updating non-Existent Stashes without a Query
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v2/organization/stashes" with no body
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 400
    # And   the response body should be:
    # """
    # {
    #   "error": "Query cannot be empty"
    # }
    # """
    # And   there are no Stashes in the database

  Scenario: Updating non-Existent Stashes with a Malformed Query
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v2/organization/stashes" with the following body:
    """
    {
      "query": "busted"
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 400
    # And   the response body should be:
    # """
    # {
    #   "error": "Query must be a Hash"
    # }
    # """
    # And   there are no Stashes in the database

  Scenario: Updating non-Existent Stashes with an Empty Query
    Given there are no matching Stashes in the database
    When  the client sends a PUT request to "/v2/organization/stashes" with the following body:
    """
    {
      "query": { }
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 400
    # And   the response body should be:
    # """
    # {
    #   "error": "Query cannot be empty"
    # }
    # """
    # And   there are no Stashes in the database

  Scenario: Updating Existent Stashes when the Query does not Match
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a PUT request to "/v2/organization/stashes" with the following body:
    """
    {
      "query": {
        "foo": "baz"
      },
      "update": {
        "foo": "qix"
      }
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic"
    #   "foo": "bar"
    # }
    # """

  Scenario: Updating Existing Stashes when the Query does Match
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a PUT request to "/v2/organization/stashes" with the following body:
    """
    {
      "query": {
        "foo": "bar"
      },
      "update": {
        "foo": "qix"
      }
    }
    """
    Then  the response status should be 405
    And   the response body should be:
    """
    {
      "error": "Operation update not allowed for Vayacondios::Server::StashesHandler. Valid operations are [\"retrieve\", \"delete\"]"
    }
    """
    # Then  the response status should be 200
    # And   the response body should be:
    # """
    # {
    # }
    # """
    # And   the database should have the following Stash:
    # """
    # {
    #   "_id": "topic"
    #   "foo": "qix"
    # }
    # """

  Scenario: Deleting Stashes with an Empty Query
    Given there are no matching Stashes in the database
    When  the client sends a DELETE request to "/v2/organization/stashes" with no body
    Then  the response status should be 400
    And   the response body should be:
    """
    {
      "error": "Query cannot be empty"
    }
    """

  Scenario: Deleting Stashes when the Query Does Not Match
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a DELETE request to "/v2/organization/stashes" with the following body:
    """
    {
      "foo": "baz"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "ok": true
    }
    """
    And   the database should have the following Stash:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """

  @focus
  Scenario: Deleting Stashes when the Query Does Match
    Given the following Stash exists in the database:
    """
    {
      "_id": "topic",
      "foo": "bar"
    }
    """
    When  the client sends a DELETE request to "/v2/organization/stashes" with the following body:
    """
    {
      "foo": "bar"
    }
    """
    Then  the response status should be 200
    And   the response body should be:
    """
    {
      "ok": true
    }
    """
    And   there are no Stashes in the database
