local cjson = require("cjson.safe")

-- Builds a request object to be used with the Azure REST API.
-- @param method (string) The HTTP method to use for the request.
-- @param body (table) The request body to send with the request.
-- @param token (string) The Azure access token to use for authentication.
-- @param ssl (boolean) Whether or not to use SSL for the request. Defaults to true.
-- @return (table) The request object to be used with the Azure REST API.
local function build_request(method, body, token, ssl)
  assert(method, "no method defined")
  assert(token, "no token defined")
  assert(method == "GET" or
    method == "POST" or
    method == "PUT" or
    method == "PATCH" or
    method == "DELETE",
    "invalid HTTP method")

  local ssl_verify = ssl ~= false

  local headers = {
    ["Authorization"] = "Bearer " .. token,
    ["Content-Type"] = "application/json; charset=utf-8"
  }
  local body_str = cjson.encode(body)

  return {
    method = method,
    headers = headers,
    body = body_str,
    ssl_verify = ssl_verify
  }
end

return build_request
