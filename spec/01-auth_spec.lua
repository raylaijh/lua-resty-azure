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


function sleep(n)
  os.execute("sleep " .. tonumber(n))
end


describe("Azure Authentication interfaces ", function()
  it("Good client-credentials authentication", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    assert.is_nil(azure_client.credentials)

    local _, err = azure_client:authenticate()
    assert.is_nil(err)
    assert.is_not_nil(azure_client.credentials)

    local ok, token, _, err = azure_client.credentials:get()
    assert.is_truthy(ok)
    assert.is_nil(err)
    assert.not_nil(token)
  end)

  it("Overriding SDK-level client-credentials with empty strings should return nil credential", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "",
      client_secret = "",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })

    local _, err = azure_client:authenticate()
    assert.is_same("no authentication mechanism worked for azure", err)
    assert.is_nil(azure_client.credentials)
  end)

  it("Bad (401) client-credentials authentication", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      extra_auth_parameters = "?withcode=401",
      instance_metadata_host = "fakeazure:8081/fail",
    })

    local _, err = azure_client:authenticate()

    assert.same("no authentication mechanism worked for azure", err)
    assert.is_nil(azure_client.credentials)
  end)

  it("Good managed-identity authentication", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      instance_metadata_host = "fakeazure:8081",
    })

    local _, err = azure_client:authenticate()
    assert.is_nil(err)
    local ok, token, expiry, err = azure_client.credentials:get()
    assert.not_nil(token)
  end)

  it("Good managed-identity authentication overriding default client_id", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      instance_metadata_host = "fakeazure:8081",
    })

    local _, err = azure_client:authenticate()
    assert.is_nil(err)
    local ok, token, expiry, err = azure_client.credentials:get()
    assert.not_nil(token)
  end)

  it("Bad (401) managed-identity authentication", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      extra_auth_parameters = "?withcode=401",
      instance_metadata_host = "fakeazure:8081/fail",
    })

    local _, err = azure_client:authenticate()
    assert.is_not_nil(err)
    assert.is_nil(azure_client.credentials)
  end)

  it("Good workload-identity authentication", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
      federated_token_file = "/kong-plugin/spec/fixtures/azure-assertion-token",
      authority_host = "http://fakeazure:8081/authority/"
    })

    local _, err = azure_client:authenticate()
    assert.is_nil(err)

    local ok, token, expiry, err = azure_client.credentials:get()
    assert.not_nil(token)
  end)

  it("Token is same during cache window", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      extra_auth_parameters = "?withexpiry=3600",
      instance_metadata_host = "fakeazure:8081/fail",
    })

    local _, err = azure_client:authenticate()
    assert.is_nil(err)

    local ok, token_one, expiry, err = azure_client.credentials:get()
    assert.is_nil(err)
    assert.not_nil(token_one)

    -- get another token and test it is the same
    local ok, token_two, expiry, err = azure_client.credentials:get()
    assert.is_nil(err)
    assert.not_nil(token_two)

    ngx.log(ngx.INFO, fmt("Token one: %s | Token two: %s", token_one, token_two))
    assert.same(token_one, token_two)
  end)

  it("Token is re-loaded after cache expiry", function()
    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      extra_auth_parameters = "?withexpiry=2",
      instance_metadata_host = "fakeazure:8081/fail",
    })

    local _, err = azure_client:authenticate()
    assert.is_nil(err)

    local ok, token_one, expiry, err = azure_client.credentials:get()
    assert.not_nil(token_one)

    -- pausing to expire the token cache
    ngx.log(ngx.INFO, "pausing to expire the token cache...")
    sleep(2)

    -- get another token and test it has changed
    local ok, token_two, expiry, err = azure_client.credentials:get()

    assert.not_nil(token_two)

    ngx.log(ngx.INFO, fmt("Token one: %s | Token two: %s", token_one, token_two))
    assert.not_same(token_one, token_two)
  end)

end)
