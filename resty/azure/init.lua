--- AZURE class.
-- @classmod AZURE

local cjson = require "cjson.safe"
local fmt = string.format
local global_config = require("resty.azure.config").global

local AZURE = {}


function AZURE:new(opts)
  local azure_methods = {}
  azure_methods["opts"] = {}

  self.__index = self
  self.global_config = global_config
  self.opts = opts
  -- inject global Azure config
  for k,v in pairs(opts or {}) do
    azure_methods.opts[k] = v
  end

  -- expose function called at the base of every Azure request that ensures we have a credential
  azure_methods.authenticate = function()
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
          azure_methods.credentials = creds
          return nil
        else
          ngx.log(ngx.WARN, "could not authenticate to azure with ", class_name, " class, error: ", err)
        end
      else
        ngx.log(ngx.WARN, "could not instantiate auth method class ", class_name, ", ", debug.traceback())
      end
    end

    return "no authentication mechanism worked for azure"
  end

  -- expose function for simplifying api calls via different sdk classes
  azure_methods.make_request = function(parameters)
    local httpc = require "resty.azure.request.http.http".new()
    
    -- validate the request
    if not parameters.url then
      err = "request sent to sdk without a url"
      ngx.log(ngx.ERR, err)
      return nil, err
    end
    if not parameters.method then
      err = "request sent to sdk without a method"
      ngx.log(ngx.ERR, err)
      return nil, err
    end

    -- check parent client is authenticated for this audience
    if not azure_methods.credentials then
      ngx.log(ngx.WARN, "no cached credential for Azure - refreshing")
      local err = azure_methods:authenticate()

      if err then
        err = "no azure authentication mechanisms in chain returned any token"
        ngx.log(ngx.ERR, err)
        return nil, err
      end
    end

    local ok, token, expiry, err = azure_methods.credentials:get()

    if not ok then
      ngx.log(ngx.ERR, "error refreshing token: ", err)
      return nil, err
    end

    ngx.log(ngx.DEBUG, fmt("azure sdk making %s request to %s", parameters.method, parameters.url))

    -- make the request
    local res, err = httpc:request_uri(parameters.url, {
      method = "GET",
      headers = {
          ["Accept"] = "application/json",
          ["Authorization"] = "Bearer " .. token
      },
      ssl_verify = azure_methods.global_config.AZURE_SSL_VERIFY,
    })
    if not res then
      ngx.log(ngx.ERR, "making sdk request to azure failed: ", err)
      return nil, err
    end

    local decoded, err = cjson.decode(res.body)
    if err then
      return nil, fmt("failed to decode Azure keyvault response: %s, status: %d",
                      err, res.status)
    end

    if res.status ~= 200 then
      local error_message = decoded.error and decoded.error.message or res.body
      return nil, fmt("azure call failed with error: %s, status: %d",
                      error_message, res.status)
    end

    return decoded, nil
  end

  -- export all service clients here - TODO: automate scanning the package for all implemented services
  azure_methods.keyvault = function(self, vault_uri)
    local keyvault = require("resty.azure.api.keyvault"):new(self, vault_uri)
    return keyvault
  end

  local azure_instance = setmetatable(azure_methods, AZURE)

  return azure_instance
end


return setmetatable(
  AZURE,
  {
    __call = function(self, ...)
      return self:new(...)
    end,
  }
)
