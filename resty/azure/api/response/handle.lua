local cjson = require("cjson.safe")
local log_error = require("resty.azure.utils").log_error

-- Handles the response from an Azure SDK request.
-- If the response is not valid, logs an error and returns nil, nil, and an error message.
-- If the response contains an error attribute, logs an error and returns nil, nil, and the error message.
-- Otherwise, returns the JSON body of the response.
-- @param res The response object from the Azure SDK request.
-- @param req_err The error message from the Azure SDK request, if any.
-- @return The status of the request, The JSON body of the response, or nil, nil, and an error message.
local function handle_response(response, req_err)
  if not response then
    return log_error("making sdk request to azure failed: " .. req_err)
  end

  if req_err then
    return log_error("making sdk request to azure failed: " .. req_err)
  end

  local body = response.body
  if not body then
    return log_error("azure sdk response body is empty")
  end

  local json_body, json_err = cjson.decode(body)
  if not json_body then
    return log_error("azure sdk response body is not valid json: " .. json_err)
  end

  return response.status, json_body
end



return handle_response
