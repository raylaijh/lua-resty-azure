local log_and_error = require("resty.azure.utils").log_error

local authenticate = function(global_config, opts)
  local creds, err

  -- try each implemented authentication class, find the first one that gives us a token
  for _, class_name in ipairs {
    "ClientCredentials",
    "WorkloadIdentityCredentials",
    "ManagedIdentityCredentials",
  } do
    local ok, cred_class = xpcall(require, debug.traceback, "resty.azure.credentials." .. class_name)
    if ok then
      creds, err = cred_class:new(global_config, opts)

      if not err then
        ngx.log(ngx.DEBUG, "authenticated to azure with ", class_name, " mechanism")
        return creds
      else
        ngx.log(ngx.WARN, "could not authenticate to azure with ", class_name, " class, error: ", err)
      end
    else
      ngx.log(ngx.WARN, "could not instantiate auth method class ", class_name, ", ", debug.traceback())
    end
  end

  return nil, "no authentication mechanism worked for azure"
end

--- Retrieves an access token from the given credentials object.
-- @param credentials The credentials object to retrieve the token from.
-- @return The access token, its expiry time, and any error encountered during retrieval.
local get_token = function(credentials)
  local ok, token, expiry, err = credentials:get()
  if not ok then
    return log_and_error("error refreshing token: " .. err)
  end
  return token, expiry, nil
end


return {
  authenticate = authenticate,
  get_token = get_token,
}
