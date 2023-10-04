--- AZURE class.
-- This class provides methods for interacting with Azure services, such as secrets, keys, and certificates.
-- @classmod AZURE

local fmt = string.format
local global_config = require("resty.azure.config").global
local auth = require("resty.azure.api.auth").authenticate
local get_token = require("resty.azure.api.auth").get_token
local build_request = require("resty.azure.api.request.build")
local execute_request = require("resty.azure.api.request.execute")

local AZURE = {}

--- Creates a new instance of the AZURE class.
-- @param opts (table) A table of options to configure the instance. Supported options are:
--   * `tenant_id` (string) The Azure tenant ID.
--   * `client_id` (string) The Azure client ID.
--   * `client_secret` (string) The Azure client secret.
--   * `subscription_id` (string) The Azure subscription ID.
--   * `resource_group` (string) The Azure resource group.
--   * `location` (string) The Azure location.
-- @return (table) A new instance of the AZURE class.
function AZURE:new(opts)
  local azure_methods = {}
  azure_methods["opts"] = {}

  self.__index = self
  self.global_config = global_config
  self.opts = opts
  -- inject global Azure config
  for k, v in pairs(opts or {}) do
    azure_methods.opts[k] = v
  end

  -- Authenticates the Azure client using the provided credentials.
  -- If `credentials` are not set, runs `auth()` to get them.
  -- Caches the credentials for future use.
  azure_methods.authenticate = function()
    local credentials, err = auth(self.global_config, self.opts)
    if err or not credentials then
      return nil, err
    end
    azure_methods.credentials = credentials
  end

  -- Sends a request to Azure using the provided options.
  -- @param opts A table containing the request options (url, method, body).
  -- @return response The response from the Azure API.
  -- @return response_error An error message if the request fails.
  azure_methods.make_request = function(self, r_opts)
    local _, err = azure_methods.authenticate()
    if err then
      return nil, nil, fmt("could not authenticate. %s", err)
    end
    -- todo: check if token is expired
    local token, expiry, err = get_token(azure_methods.credentials)
    if not token then
      return nil, nil, fmt("could not get token. %s", err)
    end
    local url = r_opts.url
    local request = build_request(r_opts.method, r_opts.body, token, self.global_config.SSL_VERIFY)
    return execute_request(url, request)
  end
  -- Defines methods for accessing Azure Key Vault secrets
  -- @param self The object instance
  -- @param vault_uri The URI of the Azure Key Vault
  -- @return An object instance for accessing the specified Azure Key Vault resource
  azure_methods.secrets = function(self, vault_uri)
    local secrets = require("resty.azure.api.secrets"):new(self, vault_uri)
    return secrets
  end

  -- Defines methods for accessing Azure Key Vault keys.
  -- @param self The object instance
  -- @param vault_uri The URI of the Azure Key Vault
  -- @return An object instance for accessing the specified Azure Key Vault resource
  azure_methods.keys = function(self, vault_uri)
    local keys = require("resty.azure.api.keys"):new(self, vault_uri)
    return keys
  end

  -- Defines methods for accessing Azure Key Vault certificates.
  -- @param self The object instance
  -- @param vault_uri The URI of the Azure Key Vault
  -- @return An object instance for accessing the specified Azure Key Vault resource
  azure_methods.certificates = function(self, vault_uri)
    local certificates = require("resty.azure.api.certificates"):new(self, vault_uri)
    return certificates
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
