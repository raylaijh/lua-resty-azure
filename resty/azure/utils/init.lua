local utils = {}

--- Logs an error message and returns a nil response with the error message.
-- @param msg (string) The error message to log.
-- @return (nil) A nil response.
function utils.log_error(msg)
  ngx.log(ngx.ERR, msg)
  return nil, nil, msg
end


return utils
