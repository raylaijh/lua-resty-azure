local handle_response = require("resty.azure.api.response.handle")

describe("handle_response", function()
  it("should return the JSON body if the response is valid", function()
    local response = {
      status = 200,
      body = [[
        {
          "value": "mysecretvalue",
          "id": "https://myvault.vault.azure.net/secrets/mysecretname/4387e9f3d6e14c459867679a90fd0f79",
          "attributes": {
            "enabled": true,
            "created": 1493938410,
            "updated": 1493938410,
            "recoveryLevel": "Recoverable+Purgeable"
          }
        }
      ]]
    }

    local status, json_body, err = handle_response(response)
    assert.is_nil(err)
    assert.is_equal(200, status)
    assert.is_table(json_body)
    assert.is_equal("mysecretvalue", json_body.value)
    assert.is_equal("https://myvault.vault.azure.net/secrets/mysecretname/4387e9f3d6e14c459867679a90fd0f79", json_body.id)
    assert.is_table(json_body.attributes)
    assert.is_true(json_body.attributes.enabled)
    assert.is_equal(1493938410, json_body.attributes.created)
    assert.is_equal(1493938410, json_body.attributes.updated)
    assert.is_equal("Recoverable+Purgeable", json_body.attributes.recoveryLevel)
  end)

  it("should return nil, nil, and an error message if the response is not valid JSON", function()
    local response = {
      status = 200,
      body = "not valid json"
    }

    local _, _, err = handle_response(response)
    assert.is_string(err)
    assert.matches("azure sdk response body is not valid json", err)
  end)

  it("should return nil, nil, and an error message if the response contains an error attribute", function()
    local response = {
      status = 400,
      body = [[
        {
          "error": {
            "code": "BadArgument",
            "message": "The request was invalid or malformed.",
            "innererror": {
              "code": "InvalidParameter",
              "message": "The parameter 'secretName' is invalid."
            }
          }
        }
      ]]
    }

    local status, response, err = handle_response(response)
    assert.is_equal(400, status)
    assert.is_not_nil(response.error)
  end)

  it("should return nil, nil, and an error message if the response body is empty", function()
    local response = {
      status = 200,
      body = ""
    }

    local status, _, err = handle_response(response)
    assert.is_nil(status)
    assert.is_string(err)
    assert.matches("azure sdk response body is not valid json", err)
  end)

  it("should return nil, nil, and an error message if the response error is not nil", function()
    local response = {
      status = 200,
      body = [[
        {
          "value": "mysecretvalue",
        }
      ]]
    }
    local _, _, err = handle_response(response, "request error")
    assert.is_string(err)
    assert.matches("making sdk request to azure failed: request error", err)
  end)
end)
