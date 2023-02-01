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


function random_string(length)
	local res = ""
	for i = 1, length do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end


describe("Test all Key Vault Keys interfaces", function()
  it("Good client-credentials authentication and Good existing key", function()
    local key_name = random_string(20)

    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    key, err = keyvault_client:get_key(key_name)

    if err then
      assert.has_no.errors(function() error("error getting Key Vault secret: " .. err) end)
    else
      assert.same(key.key.n, "ruqZAvsEEnCJqpNmVZbi...==")
      assert.same(key.key.kid, fmt("http://fakeazure:8081/keyvault/jack-vault/keys/%s/9bdcdbefc49446dd9a2a9b3f55e10340", key_name))
      assert.not_nil(keyvault_client.parent_client.credentials:get())
    end
  end)

  it("Good client-credentials authentication and Good Existing key of specific version", function()
    local key_name = random_string(20)
    local requested_version = random_string(10)

    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    key, err = keyvault_client:get_key(key_name, requested_version)

    if err then
      assert.has_no.errors(function() error("error getting Key Vault certificate: " .. err) end)
    else
      assert.same(key.key.n, "ruqZAvsEEnCJqpNmVZbi...==")
      assert.not_nil(keyvault_client.parent_client.credentials:get())
      assert.same(key.key.kid, fmt("http://fakeazure:8081/keyvault/jack-vault/keys/%s/%s", key_name, requested_version))
    end
  end)
end)
