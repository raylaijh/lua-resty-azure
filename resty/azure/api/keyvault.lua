local keyvault = {}
keyvault.__index = keyvault


local cjson = require("cjson.safe")
local fmt = string.format


function keyvault:new(parent_client, vault_uri)
  local self = {}  -- override 'self' to be the new object/class
  setmetatable(self, keyvault)
  
  self.parent_client = parent_client
  self.vault_uri = vault_uri or parent_client.global_config.AZURE_DEFAULTS_KEYVAULT_URI

  return self
end


function keyvault:get_secret(secret_name, secret_version, opts)
  ngx.log(ngx.DEBUG, "getting secret from azure key vault: ", secret_name, " #", (secret_version or "latest-version"))

  opts = opts or {}
  secret_version = secret_version and "/" .. secret_version or ""

  local response, err = self.parent_client.make_request({
    url = fmt("%s/secrets/%s%s?api-version=%s%s", self.vault_uri, secret_name, secret_version, self.parent_client.global_config.API_VERSION, (opts.extra_query_args or "")),
    method = "GET",
  })

  if err then
    return nil, fmt("failed to make azure request: %s", err)
  end

  return response, nil
end


function keyvault:get_certificate(certificate_name, certificate_version, opts)
  ngx.log(ngx.DEBUG, "getting certificate from azure key vault: ", certificate_name, " #", (certificate_version or "latest-version"))

  opts = opts or {}
  certificate_version = certificate_version and "/" .. certificate_version or ""

  local response, err = self.parent_client.make_request({
    url = fmt("%s/certificates/%s%s?api-version=%s%s", self.vault_uri, certificate_name, certificate_version, self.parent_client.global_config.API_VERSION, (opts.extra_query_args or "")),
    method = "GET",
  })

  if err then
    return nil, fmt("failed to make azure request: %s", err)
  end
  
  return response, nil
end


function keyvault:get_key(key_name, key_version, opts)
  ngx.log(ngx.DEBUG, "getting certificate from azure key vault: ", key_name, " #", (key_version or "latest-version"))

  opts = opts or {}
  key_version = key_version and "/" .. key_version or ""

  local response, err = self.parent_client.make_request({
    url = fmt("%s/keys/%s%s?api-version=%s%s", self.vault_uri, key_name, key_version, self.parent_client.global_config.API_VERSION, (opts.extra_query_args or "")),
    method = "GET",
  })

  if err then
    return nil, fmt("failed to make azure request: %s", err)
  end
  
  return response, nil
end

return keyvault
