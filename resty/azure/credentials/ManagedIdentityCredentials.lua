--- ManagedIdentityCredentials class.
-- @classmod ManagedIdentityCredentials


-- Create class
local Super = require "resty.azure.credentials.Credentials"
local ManagedIdentityCredentials = setmetatable({}, Super)
local json = require "cjson.safe"
local fmt = string.format
ManagedIdentityCredentials.__index = ManagedIdentityCredentials


--- Constructor, inherits from `Credentials`.
--
-- @function azure:ManagedIdentityCredentials
-- @param opt options table, additional fields to the `Credentials` class:
-- @param opt.envPrefix prefix to use when looking for environment variables, defaults to "AZURE".
function ManagedIdentityCredentials:new(global_config, opts)
  local self = Super:new(opts)  -- override 'self' to be the new object/class
  setmetatable(self, ManagedIdentityCredentials)

  opts = opts or {}
  self.envPrefix = opts.envPrefix or "AZURE"
  self.global_config = global_config
  self.opts = opts

  local okay, token, ttl, err = self:get() -- force immediate refresh

  return self, err
end


-- updates credentials.
-- @return success, or nil+err
function ManagedIdentityCredentials:refresh()
  local time_now = ngx.time()

  -- get the token
  -- Single-shot requests use the `request_uri` interface.
  local httpc = require "resty.azure.request.http.http".new()
  local instance_metadata_host = self.opts.instance_metadata_host or self.global_config.AZURE_INSTANCE_METADATA_HOST or os.getenv(self.envPrefix .. "_INSTANCE_METADATA_HOST") or os.getenv("AZURE_INSTANCE_METADATA_HOST")
  
  -- offer the option to override the client_id, in case the instance/pod has multiple attached identities
  local clientId = self.opts.client_id or self.global_config.AZURE_CLIENT_ID or os.getenv(self.envPrefix .. "_CLIENT_ID") or os.getenv("AZURE_CLIENT_ID")
  if clientId then
    ngx.log(ngx.INFO, "using managed identity client_id ", clientId)
    clientId = fmt("&client_id=%s", clientId)
  else
    clientId = ""
  end

  -- read the instance/pod identity details
  -- TODO remove hard-coded token audience
  local url = fmt("http://%s/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net%s", instance_metadata_host, clientId)
  ngx.log(ngx.DEBUG, "making managed identity auth GET to ", url)

  local res, err = httpc:request_uri(url,
    {
      headers = {
        ["Metadata"] = "true",
      },
      keepalive = false,
    }
  )
  if not res then
    ngx.log(ngx.ERR, "managed identity credentials request failed: ", err)
    return false, err
  end

  if res.status ~= 200 then
    ngx.log(ngx.ERR, "request failed, status: ", res.status)
    return false, res.body
  end

  -- parse out the token and expiry
  local auth_response, err = json.decode(res.body)
  if err then
    ngx.log(ngx.ERR, "cannot parse auth response body")
    return false, "access token not in response body"
  end
  
  if not auth_response.access_token then
    ngx.log(ngx.ERR, "access token not in response body")
    return false, "access token not in response body"
  end
  
  self:set(auth_response.access_token, auth_response.expires_in + time_now)

  return true, nil
end

return ManagedIdentityCredentials
