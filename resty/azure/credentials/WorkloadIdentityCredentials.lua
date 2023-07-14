--- WorkloadIdentityCredentials class.
-- @classmod WorkloadIdentityCredentials


-- Create class
local Super = require "resty.azure.credentials.Credentials"
local WorkloadIdentityCredentials = setmetatable({}, Super)
local json = require "cjson.safe"
local fmt = string.format

local pl_file = require "pl.file"
local pl_path = require "pl.path"
local pl_dir = require "pl.dir"

WorkloadIdentityCredentials.__index = WorkloadIdentityCredentials


--- Constructor, inherits from `Credentials`.
--
-- @function azure:WorkloadIdentityCredentials
-- @param opt options table, additional fields to the `Credentials` class:
-- @param opt.envPrefix prefix to use when looking for environment variables, defaults to "AZURE".
function WorkloadIdentityCredentials:new(global_config, opts)
  local self = Super:new(opts)  -- override 'self' to be the new object/class
  setmetatable(self, WorkloadIdentityCredentials)

  opts = opts or {}
  self.envPrefix = opts.envPrefix or "AZURE"
  self.global_config = global_config
  self.opts = opts

  local okay, token, ttl, err = self:get() -- force immediate refresh

  return self, err
end


-- updates credentials.
-- @return success, or nil+err
function WorkloadIdentityCredentials:refresh()
  local time_now = ngx.time()

  -- use JWT assertion grant to exchange injected serviceaccount token for Azure services bearer
  -- Single-shot requests use the `request_uri` interface.
  local httpc = require "resty.luasocket.http".new()
  local instance_metadata_host = self.opts.instance_metadata_host or self.global_config.AZURE_INSTANCE_METADATA_HOST or os.getenv(self.envPrefix .. "_INSTANCE_METADATA_HOST") or os.getenv("AZURE_INSTANCE_METADATA_HOST")
  
  -- check for injects env location of assertion token, then check for token presence on disk
  local azure_federated_token_file = self.opts.federated_token_file or self.global_config.AZURE_FEDERATED_TOKEN_FILE or os.getenv("AZURE_FEDERATED_TOKEN_FILE")
  if not azure_federated_token_file or azure_federated_token_file == "" then
    ngx.log(ngx.ERR, "Couldn't find AZURE_FEDERATED_TOKEN_FILE env variable")
    return false, "Couldn't find AZURE_FEDERATED_TOKEN_FILE env variable"
  end

  local azure_authority_host = self.opts.authority_host or self.global_config.AZURE_AUTHORITY_HOST or os.getenv("AZURE_AUTHORITY_HOST")
  if not azure_authority_host or azure_authority_host == "" then
    ngx.log(ngx.ERR, "Couldn't find AZURE_AUTHORITY_HOST env variable")
    return false, "Couldn't find AZURE_AUTHORITY_HOST env variable"
  end

  local azure_client_id = self.opts.client_id or self.global_config.AZURE_CLIENT_ID or os.getenv("AZURE_CLIENT_ID")
  if not azure_client_id or azure_client_id == "" then
    ngx.log(ngx.ERR, "Couldn't find AZURE_CLIENT_ID env variable")
    return false, "Couldn't find AZURE_CLIENT_ID env variable"
  end

  local azure_tenant_id = self.opts.tenant_id or self.global_config.AZURE_TENANT_ID or os.getenv("AZURE_TENANT_ID")
  if not azure_tenant_id or azure_tenant_id == "" then
    ngx.log(ngx.ERR, "Couldn't find AZURE_TENANT_ID env variable")
    return false, "Couldn't find AZURE_TENANT_ID env variable"
  end

  -- check for the injected azure assertion token on the filesystem
  if not pl_path.exists(azure_federated_token_file) then
    ngx.log(ngx.ERR, "Couldn't find federated token file on filesystem")
    return false, "Couldn't find federated token file on filesystem"
  end

  local assertion_token = pl_file.read(azure_federated_token_file)
  if not assertion_token then
    ngx.log(ngx.ERR, "Couldn't read federated token file from filesystem")
    return false, "Couldn't read federated token file from filesystem"
  end

  local httpc = require "resty.luasocket.http".new()
  ngx.update_time()
  local time_now = ngx.now()

  local url = fmt("%s%s/oauth2/v2.0/token", azure_authority_host, azure_tenant_id)
  ngx.log(ngx.WARN, "making jwt-assertion auth POST to ", url)

  -- TODO remove hard-coded token audience - support many audiences, depending on the target Azure service
  local res, err = httpc:request_uri(
    url,
    {
      method = "POST",
      body = fmt("client_id=%s&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&grant_type=client_credentials&client_assertion=%s&scope=https://vault.azure.net/.default", azure_client_id, assertion_token),
      headers = {
          ["Content-Type"] = "application/x-www-form-urlencoded",
      },
      ssl_verify = self.opts.ssl_verify or self.global_config.AZURE_SSL_VERIFY,
      keepalive = false,
    }
  )

  if not res then
    ngx.log(ngx.ERR, "oauth client_credentials grant request failed: ", err)
    return false, err
  end

  if res.status ~= 200 then
    ngx.log(ngx.ERR, "request failed, status: ", res.status)
    return false, res.body
  end

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

return WorkloadIdentityCredentials
