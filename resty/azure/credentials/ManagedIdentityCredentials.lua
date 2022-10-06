--- ManagedIdentityCredentials class.
-- @classmod ManagedIdentityCredentials


-- Create class
local Super = require "resty.azure.credentials.Credentials"
local ManagedIdentityCredentials = setmetatable({}, Super)
local json = require "cjson.safe"
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
  local instance_metadata_host = self.opts.instance_metadata_host or self.global_config.AZURE_INSTANCE_METADATA_HOST or os.getenv(self.envPrefix .. "_INSTANCE_METADATA_HOST") or os.getenv("AZURE_INSTANCE_METADATA_HOST")

  -- get the token
  -- Single-shot requests use the `request_uri` interface.
  local httpc = require "resty.azure.request.http.http".new()

  -- read the managed identity details
  -- TODO remove hard-coded token audience
  local res, err = httpc:request_uri("http://" .. instance_metadata_host .. "/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net")
  if not res then
    ngx.log(ngx.ERR, "managed identity credentials request failed: ", err)
    return false, err
  end

  -- parse out the token and expiry
  local auth_response, err = json.decode(res.body)
  if err then return false, err end
  
  self:set(auth_response.access_token, auth_response.expires_in)

  return true, nil
end

return ManagedIdentityCredentials
