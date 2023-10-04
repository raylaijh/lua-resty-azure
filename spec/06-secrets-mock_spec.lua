local secrets = require "resty.azure.api.secrets"
local keyvault = require "resty.azure.api.keyvault"

describe("resty.azure.api.secrets", function()
  describe("new", function()
    it("creates a new secrets object", function()
      local parent_client = {}
      local vault_uri = "https://myvault.vault.azure.net/"
      local s = secrets:new(parent_client, vault_uri)
      assert.is_not_nil(s)
      assert.is_true(getmetatable(s) == secrets)
      assert.is_true(getmetatable(getmetatable(s)) == keyvault)
      assert.is_true(s.parent_client == parent_client)
      assert.is_true(s.vault_uri == vault_uri)
    end)
  end)

  describe("get", function()
    it("retrieves a secret from the Key Vault", function()
      local s = secrets:new({}, "https://myvault.vault.azure.net/")
      local secret_name = "mysecret"
      local secret_version = "abc123"
      local secret_value = "mysecretvalue"
      local get_resource_stub = stub(s, "get_resource")
      get_resource_stub.returns = { value = secret_value }
      s:get(secret_name, secret_version)
      assert.stub(get_resource_stub).was_called_with(s, s.vault_types.SECRETS, secret_name, secret_version, nil)
    end)
  end)

  describe("create", function()
    it("sets a secret in the Key Vault", function()
      local s = secrets:new({}, "https://myvault.vault.azure.net/")
      local secret_name = "mysecret"
      local secret_value = "mysecretvalue"
      local put_resource_stub = stub(s, "put_resource")
      put_resource_stub.returns = { value = secret_value }
      s:create(secret_name, secret_value)
      assert.stub(put_resource_stub).was_called_with(s, s.vault_types.SECRETS, secret_name, { value = secret_value })
    end)
  end)

  describe("update", function()
    it("updates a secret in the Key Vault", function()
      local s = secrets:new({}, "https://myvault.vault.azure.net/")
      local secret_name = "mysecret"
      local secret_version = "abc123"
      local secret_value = "mysecretvalue"
      local update_resource_stub = stub(s, "update_resource")
      update_resource_stub.returns = { value = secret_value }
      s:update(secret_name, secret_version, secret_value)
      assert.stub(update_resource_stub).was_called_with(s, s.vault_types.SECRETS, secret_name, secret_version)
    end)
  end)

  describe("delete", function()
    it("deletes a secret from the Key Vault", function()
      local s = secrets:new({}, "https://myvault.vault.azure.net/")
      local secret_name = "mysecret"
      local secret_version = "abc123"
      local delete_resource_stub = stub(s, "delete_resource")
      delete_resource_stub.returns = { value = "mysecretvalue" }
      s:delete(secret_name, secret_version)
      assert.stub(delete_resource_stub).was_called_with(s, s.vault_types.SECRETS, secret_name, secret_version)
    end)
  end)
end)
