local keyvault = {}
keyvault.__index = keyvault

local fmt = string.format

local METHODS = {
  GET = "GET",
  PATCH = "PATCH",
  PUT = "PUT",
  DELETE = "DELETE"
}

--- Creates a new KeyVault object.
--- @param parent_client string: The parent client object.
--- @param vault_uri string: The URI of the KeyVault to use. If not provided, the default URI from the parent client's global configuration will be used.
--- @return table: The new KeyVault object.
function keyvault:new(parent_client, vault_uri)
  local self = {} -- override 'self' to be the new object/class
  setmetatable(self, keyvault)

  self.vault_types = {
    SECRETS = "secrets",
    CERTIFICATES = "certificates",
    KEYS = "keys"
  }

  self.parent_client = parent_client
  self.vault_uri = vault_uri or parent_client.global_config.AZURE_DEFAULTS_KEYVAULT_URI

  return self
end

--- Builds a URL for a given Azure Key Vault resource.
-- @param resource_type string: The type of the resource (e.g. "secrets", "keys", "certificates").
-- @param resource_name string: The name of the resource.
-- @param resource_version string: The version of the resource (optional).
-- @param opts[opt] table: Extra options to include in the URL (optional).
-- @return string: The URL for the given resource.
function keyvault:build_url(resource_type, resource_name, resource_version, opts)
  resource_version = resource_version and "/" .. resource_version or ""

  return string.format("%s/%s/%s%s?api-version=%s%s",
    self.vault_uri,
    resource_type,
    resource_name,
    resource_version,
    self.parent_client.global_config.API_VERSION,
    opts and opts.extra_query_args or "")
end

--- Makes a request to Azure API using the provided parent client, URL, method, and body.
-- @param parent_client The parent client object used to make the request.
-- @param url The URL to send the request to.
-- @param method The HTTP method to use for the request.
-- @param body The request body.
-- @return The response from the Azure API, or nil and an error message if the request failed.
function keyvault:query_resource(url, method, body, opts)
  local status, response, response_error = self.parent_client:make_request({
    url = url,
    method = method,
    body = body
  })

  if status and status >= 500 then
    return nil, "internal server error"
  end

  if response_error then
    return nil, fmt("failed to make azure request: %s", response_error)
  end

  -- Check that the response contains either a `value` or an `error` attribute
  -- If both attributes are missing, return an error message
  if not response.value and not response.error then
    return nil, "no `value` or `error` attribute in response"
  end
  return response
end

-- This function retrieves a resource from Azure Key Vault.
-- @param resource_type (string) The type of the resource to retrieve.
-- @param resource_name (string) The name of the resource to retrieve.
-- @param resource_version (string) The version of the resource to retrieve. Defaults to "latest-version".
-- @return (table) The response from the Azure Key Vault API.
function keyvault:get_resource(resource_type, resource_name, resource_version, opts)
  ngx.log(ngx.DEBUG, "getting resource from azure key vault: ", resource_type, " ", resource_name, " #",
    (resource_version or "latest-version"))

  local url = self:build_url(resource_type, resource_name, resource_version, opts)
  return self:query_resource(url, METHODS.GET, opts)
end

-- This function puts a resource to Azure Key Vault.
-- @param resource_type (string) The type of the resource to put.
-- @param resource_name (string) The name of the resource to put.
-- @param resource_body (table) The body of the resource to put.
-- @param resource_version (string) The version of the resource to put. Defaults to "latest-version".
-- @return (table) The response from the Azure Key Vault API.
function keyvault:put_resource(resource_type, resource_name, resource_body, resource_version)
  ngx.log(ngx.DEBUG, "putting resource to azure key vault: ", resource_type, " ", resource_name, " #",
    (resource_version or "latest-version"))

  local url = self:build_url(resource_type, resource_name, resource_version)
  return self:query_resource(url, METHODS.PUT, resource_body)
end

-- This function posts a resource to Azure Key Vault.
-- @param resource_type (string) The type of the resource to post.
-- @param resource_name (string) The name of the resource to post.
-- @param resource_version (string) The version of the resource to post. Defaults to "latest-version".
-- @return (table) The response from the Azure Key Vault API.
function keyvault:post_resource(resource_type, resource_name, resource_version)
  ngx.log(ngx.DEBUG, "posting resource to azure key vault: ", resource_type, " ", resource_name, " #",
    (resource_version or "latest-version"))

  local url = self:build_url(resource_type, resource_name, resource_version)
  return self:query_resource(url, METHODS.PATCH)
end

-- This function updates a resource in Azure Key Vault.
-- @param resource_type (string) The type of the resource to update.
-- @param resource_name (string) The name of the resource to update.
-- @param resource_body (table) The body of the resource to update.
-- @param resource_version (string) The version of the resource to update. Defaults to "latest-version".
-- @return (table) The response from the Azure Key Vault API.
function keyvault:update_resource(resource_type, resource_name, resource_body, resource_version)
  ngx.log(ngx.DEBUG, "updating resource in azure key vault: ", resource_type, " ", resource_name, " #",
    (resource_version or "latest-version"))

  local url = self:build_url(resource_type, resource_name, resource_version)
  return self:query_resource(url, METHODS.UPDATE, resource_body)
end

-- This function deletes a resource from Azure Key Vault.
-- @param resource_type (string) The type of the resource to delete.
-- @param resource_name (string) The name of the resource to delete.
-- @param resource_version (string) The version of the resource to delete. Defaults to "latest-version".
-- @return (table) The response from the Azure Key Vault API.
function keyvault:delete_resource(resource_type, resource_name, resource_version)
  ngx.log(ngx.DEBUG, "deleting resource from azure key vault: ", resource_type, " ", resource_name, " #",
    (resource_version or "latest-version"))

  local url = self:build_url(resource_type, resource_name, resource_version)
  return self:query_resource(url, METHODS.DELETE)
end

return keyvault
