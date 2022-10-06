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


describe("Test all Key Vault Certificates interfaces", function()
  it("Good client-credentials authentication and Good Existing certificate", function()
    local cert_name = random_string(20)

    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081/",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    certificate, err = keyvault_client:get_certificate(cert_name)

    if err then
      assert.has_no.errors(function() error("error getting Key Vault secret: " .. err) end)
    else
      assert.same(certificate.cer, "MIIDPDCC...==")
      assert.same(certificate.id, fmt("http://fakeazure:8081/keyvault/jack-vault/certificates/%s/9bdcdbefc49446dd9a2a9b3f55e10340", cert_name))
      assert.not_nil(keyvault_client.parent_client.credentials:get())
    end
  end)

  it("Good client-credentials authentication and Good Existing certificate of specific version", function()
    local cert_name = random_string(20)
    local requested_version = "456-789-0ab"

    -- get an azure client, override all environment defaults
    local azure_client = require("resty.azure"):new({
      auth_base_url = "http://fakeazure:8081/",
      client_id = "fake_client",
      client_secret = "fake_secret",
      tenant_id = "fake_tenant",
      instance_metadata_host = "fakeazure:8081/fail",
    })
    keyvault_client = azure_client:keyvault("http://fakeazure:8081/keyvault/jack-vault")
    certificate, err = keyvault_client:get_certificate(cert_name, requested_version)

    if err then
      assert.has_no.errors(function() error("error getting Key Vault certificate: " .. err) end)
    else
      assert.same(certificate.cer, "MIIDPDCC...==")
      assert.not_nil(keyvault_client.parent_client.credentials:get())
      assert.same(certificate.id, fmt("http://fakeazure:8081/keyvault/jack-vault/certificates/%s/%s", cert_name, requested_version))
    end
  end)
end)
