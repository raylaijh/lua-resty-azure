--- Module for interacting with Azure Key Vault keys API.
-- @module resty.azure.api.secrets
local keyvault = require "api.keyvault"

local keys = {}
keys.__index = keys
setmetatable(keys, keyvault)

--- Constructor function for keys object.
-- @function new
-- @tparam table parent_client Azure Key Vault client object.
-- @tparam string vault_uri URI of the Azure Key Vault.
-- @treturn table keys object.
function keys:new(parent_client, vault_uri)
  local self = keyvault:new(parent_client, vault_uri)
  setmetatable(self, keys)
  return "not implemented"
end
