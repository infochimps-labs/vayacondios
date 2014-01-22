Feature: Stash
  In order to provide functionality
  As a user of the Vayacondios Api
  I want to document how the Stream works

  Scenario: Retrieving Events as a stream
    Given the following Event exists under topic "topic" in the database:
    """
    {
      "_id": "id1",
      "_t": "2012-02-13T12:34:42.452Z",
      "_d": {
        "time": "2012-02-13T12:34:42.452Z"
      }
    }
    """
    # When  the client open a stream request to "/v2/organization/stream/topic" with the following body:
    # """
    # {
    #   "from":"2012-01-01T00:00:00.000Z"
    # }
    # """
    # Then  the response status should be 200
    # And   the stream response body should be:
    # """
    # {
    #   "id":"id1",
    #   "time": "2012-02-13T12:34:42.452Z"      
    # }    
    # """
