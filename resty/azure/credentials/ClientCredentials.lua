--- ClientCredentials class.
-- @classmod ClientCredentials


-- Create class
local Super = require "resty.azure.credentials.Credentials"
local ClientCredentials = setmetatable({}, Super)
local json = require "cjson.safe"
ClientCredentials.__index = ClientCredentials

--- Constructor, inherits from `Credentials`.
--
-- @function azure:ClientCredentials
-- @param opt options table, additional fields to the `Credentials` class:
-- @param opt.envPrefix prefix to use when looking for environment variables, defaults to "AZURE".
function ClientCredentials:new(global_config, opts)
  local self = Super:new(opts)  -- override 'self' to be the new object/class
  setmetatable(self, ClientCredentials)

  opts = opts or {}
  self.envPrefix = opts.envPrefix or "AZURE"
  self.global_config = global_config
  self.opts = opts

  local okay, token, ttl, err = self:get() -- force immediate refresh

  return self, err
end


-- updates credentials.
-- @return success, or nil+err
function ClientCredentials:refresh()
  local clientId = self.opts.client_id or self.global_config.AZURE_CLIENT_ID or os.getenv(self.envPrefix .. "_CLIENT_ID") or os.getenv("AZURE_CLIENT_ID")
  if not clientId or clientId == "" then
    ngx.log(ngx.ERR, "Couldn't find " .. self.envPrefix .. "_CLIENT_ID env variable")
    return false, "Couldn't find " .. self.envPrefix .. "_CLIENT_ID env variable"
  end

  local clientSecret = self.opts.client_secret or self.global_config.AZURE_CLIENT_SECRET or os.getenv(self.envPrefix .. "_CLIENT_SECRET") or os.getenv("AZURE_CLIENT_SECRET")
  if not clientSecret or clientSecret == "" then
    ngx.log(ngx.ERR, "Couldn't find " .. self.envPrefix .. "_CLIENT_SECRET env variable")
    return false, "Couldn't find " .. self.envPrefix .. "_CLIENT_SECRET env variable"
  end

  local tenantId = self.opts.tenant_id or self.global_config.AZURE_TENANT_ID or os.getenv(self.envPrefix .. "_TENANT_ID") or os.getenv("AZURE_TENANT_ID")
  if not tenantId or tenantId == "" then
    ngx.log(ngx.ERR, "Couldn't find " .. self.envPrefix .. "_TENANT_ID env variable")
    return false, "Couldn't find " .. self.envPrefix .. "_TENANT_ID env variable"
  end

  -- get the token
  -- Single-shot requests use the `request_uri` interface.
  local httpc = require "resty.azure.request.http.http".new()
  
  local time_now = ngx.now()

  -- TODO remove hard-coded token audience - support many audiences, depending on the target Azure service
  local res, err = httpc:request_uri((self.opts.auth_base_url or "https://login.microsoftonline.com/") .. tenantId .. "/oauth2/v2.0/token" .. (self.opts.extra_auth_parameters or ""), {
    method = "POST",
    body = "grant_type=client_credentials&client_id=" .. clientId .. "&client_secret=" .. clientSecret .. "&scope=https://vault.azure.net/.default",
    headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
    },
    ssl_verify = self.opts.ssl_verify or self.global_config.AZURE_SSL_VERIFY,
    keepalive = false,
  })

  if not res then
    ngx.log(ngx.ERR, "oauth client_credentials grant request failed: ", err)
    return false, err
  end

  if res.status ~= 200 then
    ngx.log(ngx.ERR, "request failed, status: ", res.status)
    return false, res.body
  end

  local auth_response = json.decode(res.body)

  if not auth_response.access_token then
    ngx.log(ngx.ERR, "access token not in response body")
    return false, "access token not in response body"
  end

  self:set(auth_response.access_token, auth_response.expires_in + time_now)
  return true, nil
end

return ClientCredentials
