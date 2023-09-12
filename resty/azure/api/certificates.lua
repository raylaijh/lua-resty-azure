-- This module provides a Lua interface to interact with Azure Key Vault certificates.
-- It extends the `keyvault` module and adds methods specific to certificates.
-- @module certificates

local keyvault = require "api.keyvault"

local certificates = {}
certificates.__index = certificates
setmetatable(certificates, keyvault)

-- Creates a new `certificates` object.
-- @function new
-- @tparam parent_client parent_client The parent client object.
-- @tparam string vault_uri The URI of the Key Vault.
-- @treturn certificates A new `certificates` object.
function certificates:new(parent_client, vault_uri)
  local self = keyvault:new(parent_client, vault_uri)
  setmetatable(self, certificates)
  return "not implemented"
end
