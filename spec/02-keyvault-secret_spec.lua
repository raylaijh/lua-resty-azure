local cjson = require("cjson.safe").new()
local fmt = string.format

function getTableSize(t)
  local count = 0
  for _, __ in pairs(t) do
      count = count + 1
  end
  return count
end


function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
      return tostring(o)
  end
end


describe("Test all Key Vault Secrets interfaces #", function()
  it("Good client-credentials authentication and Good Existing secret", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    secret, err = keyvault_client:get_secret("demo")

    if err then
      assert.has_no.errors(function() error("error getting Key Vault secret: " .. err) end)
    else
      assert.same(secret.value, "This is the fake secret value")
      assert.not_nil(keyvault_client.parent_client.credentials:get())
    end
  end)

  it("Good client-credentials authentication and Good Existing secret of specific version", function()
    local requested_version = "123-456-789"

    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    secret, err = keyvault_client:get_secret("demo", requested_version)

    if err then
      assert.has_no.errors(function() error("error getting Key Vault secret: " .. err) end)
    else
      assert.same(secret.value, "This is the fake secret value")
      assert.not_nil(keyvault_client.parent_client.credentials:get())
      assert.same(secret.id, fmt("http://fakeazure:8081/keyvault/jack-vault/secrets/demo/%s", requested_version))
    end
  end)

  it("Good client-credentials authentication and secret not found", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    secret, err = keyvault_client:get_secret("demo", nil, { extra_query_args = "&withcode=404" })

    if err then
      assert.same('failed to make azure request: azure call failed with error: secret demo version 9bdcdbefc49446dd9a28e04f55e10340 not found in this keyvault, status: 404', err)
    else
      assert.has_no.errors(function() error("expected an error!") end)
    end
  end)

  it("Good instance-metadata credentials with Bad client-credentials authentication and Good Existing secret", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      extra_auth_parameters = "?withcode=401",
      instance_metadata_host = "fakeazure:8081",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    secret, err = keyvault_client:get_secret("demo")

    if err then
      assert.has_no.errors(function() error("error getting Key Vault secret: " .. err) end)
    else
      assert.same(secret.value, "This is the fake secret value")
      assert.not_nil(keyvault_client.parent_client.credentials:get())
    end
  end)

  it("Bad authentication (unauthorized) and Good Existing secret", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      extra_auth_parameters = "?withcode=401",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    secret, err = keyvault_client:get_secret("demo")

    if err then
      assert.same('failed to make azure request: no azure authentication mechanisms in chain returned any token', err)
    else
      assert.has_no.errors(function() error("expected an error!") end)
    end
  end)

  it("Internal Server Error when getting secret with good authentication", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    secret, err = keyvault_client:get_secret("demo", nil, { extra_query_args = "&withcode=500" })

    if err then
      assert.same('failed to make azure request: azure call failed with error: error retrieving secret, status: 500', err)
    else
      assert.has_no.errors(function() error("expected an error!") end)
    end
  end)

  it("Internal Server Error when getting secret with non-JSON syntax and good authentication", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    secret, err = keyvault_client:get_secret("demo", nil, { extra_query_args = "&withcode=501" })

    if err then
      assert.same('failed to make azure request: failed to decode Azure keyvault response: Expected value but found invalid token at character 1, status: 500', err)
    else
      assert.has_no.errors(function() error("expected an error!") end)
    end
  end)

  it("Internal Server Error when getting secret with bad JSON message format and good authentication", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    secret, err = keyvault_client:get_secret("demo", nil, { extra_query_args = "&withcode=502" })

    if err then
      assert.same('failed to make azure request: azure call failed with error: {"fault":{"msg":"good json syntax but badly formatted error message"}}\n, status: 500', err)
    else
      assert.has_no.errors(function() error("expected an error!") end)
    end
  end)

  it("Internal Server Error when authenticating", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      extra_auth_parameters = "?withcode=500",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault?withcode=500")
    secret, err = keyvault_client:get_secret("demo")

    if err then
      assert.same('failed to make azure request: no azure authentication mechanisms in chain returned any token',err)
    else
      assert.has_no.errors(function() error("expected an error!") end)
    end
  end)
end)
