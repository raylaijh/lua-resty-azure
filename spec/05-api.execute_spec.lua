local execute_request = require("resty.azure.api.request.execute")

describe("execute_request", function()
  it("should return an error if no url is provided", function()
    local res, _, err = execute_request(nil, {})
    assert.is_nil(res)
    assert.is_nil(_)
    assert.equal("cannot construct request without a url", err)
  end)

  it("should return an error if the request fails", function()
    local mock_httpc = {
      request_uri = function(_, _)
        return nil, "failed to connect"
      end
    }
    package.loaded["resty.luasocket.http"] = { new = function() return mock_httpc end }

    local url = "https://example.com"
    local request = { method = "GET", headers = { ["Content-Type"] = "application/json" } }
    local res, _, err = execute_request(url, request)

    assert.is_nil(res)
    assert.matches("making sdk request to azure failed: ", err)
  end)
end)
