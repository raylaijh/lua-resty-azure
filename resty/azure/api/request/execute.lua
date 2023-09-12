-- This module provides a function for executing HTTP requests to the Azure API.
-- It takes a URL and a request object as input, and returns the response object.
-- If an error occurs during the request, it returns nil and an error message.
-- The handle_response function is used to handle the response object.
-- This function is exposed for simplifying API calls via different SDK classes.

local handle_response = require("resty.azure.api.response.handle")
local http = require "resty.luasocket.http"
local fmt = string.format
local utils = require("resty.azure.utils")
local log_error = utils.log_error

-- This function executes an HTTP request to a given URL using the provided request object.
-- @param url (string) The URL to send the request to.
-- @param request (table) The request object containing the HTTP method, headers, and body.
-- @return (table) The response object containing the HTTP status code, headers, and body.
local execute_request = function(url, request)
  -- Load the LuaSocket HTTP client library.
  local httpc = http.new()

  -- If no URL is provided, log an error and return nil.
  if not url then
    return log_error("cannot construct request without a url")
  end

  ngx.log(ngx.DEBUG, fmt("azure sdk making %s request to %s", request.method, request.url))

  -- Make the HTTP request using the LuaSocket HTTP client.
  local res, req_err = httpc:request_uri(url, request)

  -- If the request failed, log an error and return nil.
  if not res then
    return log_error("making sdk request to azure failed: " .. req_err)
  end

  -- If the request succeeded, handle the response and return the response object.
  return handle_response(res, req_err)
end

return execute_request
