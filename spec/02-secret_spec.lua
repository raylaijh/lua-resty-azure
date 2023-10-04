local fmt = string.format

describe("Test all Key Vault Secrets interfaces #", function()
  it("valid credentials and existing secret", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    local secret_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault")
    local secret_object, err = secret_client:get("demo")

    assert.is_nil(err)
    assert.is_not_nil(secret_object)
    assert.same(secret_object.value, "This is the fake secret value")
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
    local secret_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault")
    local secret, err = secret_client:get("demo", requested_version)

    if err then
      assert.has_no.errors(function() error("error getting Key Vault secret: " .. err) end)
    else
      assert.same(secret.value, "This is the fake secret value")
      assert.not_nil(secret_client.parent_client.credentials:get())
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
    local secret_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault")
    local response, err = secret_client:get("demo", nil, { extra_query_args = "&withcode=404" })
    assert.is_not_nil(response.error.code)
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
    local secret_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault")
    local secret_object, err = secret_client:get("demo")

    assert.same(secret_object.value, "This is the fake secret value")
    assert.not_nil(secret_client.parent_client.credentials:get())
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
    local secret_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault")
    local secret_object, err = secret_client:get("demo")
    assert.is_nil(secret_object)
    assert.is_not_nil(err)
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
    local secret_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault")
    local secret_object, err = secret_client:get("demo", nil, { extra_query_args = "&withcode=500" })
    assert.is_nil(secret_object)
    assert.is_same(err, "internal server error")
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
    local secrets_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault")
    local _, err = secrets_client:get("demo", nil, { extra_query_args = "&withcode=501" })
    assert.matches('failed to make azure request: azure sdk response body is not valid json: Expected value but found invalid token at character 1', err)
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
    local secrets_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault")
    local _, err = secrets_client:get("demo", nil, { extra_query_args = "&withcode=502" })

    assert.matches('internal server error', err)
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
    local keyvault_client = azure_client:secrets("http://fakeazure:8081/keyvault/jack-vault?withcode=500")
    local _, err = keyvault_client:get("demo")

    assert.same('failed to make azure request: could not authenticate. no authentication mechanism worked for azure', err)
  end)
end)
