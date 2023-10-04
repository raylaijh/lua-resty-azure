--- Module for interacting with Azure Key Vault secrets API.
-- @module resty.azure.api.secrets
local keyvault = require "resty.azure.api.keyvault"

local secrets = {}
secrets.__index = secrets
setmetatable(secrets, keyvault)

--- Constructor for creating a new secrets object.
-- @function new
-- @param parent_client The parent client object.
-- @param vault_uri The URI of the Key Vault.
-- @return A new secrets object.
function secrets:new(parent_client, vault_uri)
  local self = keyvault:new(parent_client, vault_uri)
  setmetatable(self, secrets)
  return self
end

--- Retrieves a secret from the Key Vault.
-- @function get
-- @param secret_name The name of the secret.
-- @param secret_version The version of the secret.
-- @return The secret value.
function secrets:get(secret_name, secret_version, opts)
  return self:get_resource(self.vault_types.SECRETS, secret_name, secret_version, opts)
end

--- Sets a secret in the Key Vault.
-- @function set
-- @param secret_name The name of the secret.
-- @param secret_value The value of the secret.
-- @return The updated secret object.
function secrets:create(secret_name, secret_value)
  local body = {
    value = secret_value
  }
  return self:put_resource(self.vault_types.SECRETS, secret_name, body)
end

--- Updates a secret in the Key Vault.
-- @function update
-- @param secret_name The name of the secret.
-- @param secret_version The version of the secret.
-- @param secret_value The new value of the secret.
-- @return The updated secret object.
function secrets:update(secret_name, secret_version)
  return self:update_resource(self.vault_types.SECRETS, secret_name, secret_version)
end

--- Deletes a secret from the Key Vault.
-- @function delete
-- @param secret_name The name of the secret.
-- @param secret_version The version of the secret.
-- @return The deleted secret object.
function secrets:delete(secret_name, secret_version)
  return self:delete_resource(self.vault_types.SECRETS, secret_name, secret_version)
end

--- Purges a secret by name and version.
-- @param secret_name The name of the secret to purge.
-- @param secret_version The version of the secret to purge.
-- @return The result of the delete_resource method.
function secrets:purge(secret_name, secret_version)
  return self:delete_resource("deletedsecrets", secret_name, secret_version)
end

return secrets
