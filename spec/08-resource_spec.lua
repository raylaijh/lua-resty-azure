local keyvault = require "resty.azure.api.keyvault"

describe("keyvault", function()
  local parent_client = {
    global_config = {
      AZURE_DEFAULTS_KEYVAULT_URI = "https://myvault.vault.azure.net",
      API_VERSION = "7.4"
    },
    make_request = function() end
  }

  describe(":get_resource", function()
    it("returns an error if the request fails", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 400, nil, "request failed" end
      local res, err = kv:get_resource("secrets", "mysecret")
      assert.is_nil(res)
      assert.is_equal(err, "failed to make azure request: request failed")
    end)

    it("returns an error if the response is empty", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 400, {}, nil end
      local res, err = kv:get_resource("secrets", "mysecret")
      assert.is_nil(res)
      assert.is_equal(err, "no `value` or `error` attribute in response")
    end)

    it("returns an error if the response does not contain a value attribute", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 400, {}, nil end
      local res, err = kv:get_resource("secrets", "mysecret")
      assert.is_nil(res)
      assert.is_equal(err, "no `value` or `error` attribute in response")
    end)

    it("returns the response if successful", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 200, { value = "mysecretvalue" } end
      local res, err = kv:get_resource("secrets", "mysecret")
      assert.is_not_nil(res)
      assert.is_equal(res.value, "mysecretvalue")
      assert.is_nil(err)
    end)
  end)

  describe(":delete_resource", function()
    it("returns an error if the request fails", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 204, nil, "request failed" end
      local res, err = kv:delete_resource("secrets", "mysecret")
      assert.is_nil(res)
      assert.is_equal(err, "failed to make azure request: request failed")
    end)

    it("returns the response if successful", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 200, { value = "mysecretvalue" } end
      local res, err = kv:delete_resource("secrets", "mysecret")
      assert.is_not_nil(res)
      assert.is_equal(res.value, "mysecretvalue")
      assert.is_nil(err)
    end)
  end)

  describe(":post_resource", function()
    it("returns an error if the request fails", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 400, nil, "request failed" end
      local res, err = kv:post_resource("secrets", "mysecret")
      assert.is_nil(res)
      assert.is_equal(err, "failed to make azure request: request failed")
    end)

    it("returns the response if successful", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 200, { value = "mysecretvalue" } end
      local res, err = kv:post_resource("secrets", "mysecret")
      assert.is_not_nil(res)
      assert.is_equal(res.value, "mysecretvalue")
      assert.is_nil(err)
    end)
  end)

  describe(":put_resource", function()
    it("returns an error if the request fails", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 400, nil, "request failed" end
      local res, err = kv:put_resource("secrets", "mysecret", "mysecretvalue")
      assert.is_nil(res)
      assert.is_equal(err, "failed to make azure request: request failed")
    end)

    it("returns the response if successful", function()
      local kv = keyvault:new(parent_client)
      parent_client.make_request = function() return 200, { value = "mysecretvalue" } end
      local res, err = kv:put_resource("secrets", "mysecret", "mysecretvalue")
      assert.is_not_nil(res)
      assert.is_equal(res.value, "mysecretvalue")
      assert.is_nil(err)
    end)
  end)
end)
