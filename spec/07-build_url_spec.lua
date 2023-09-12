local keyvault = require "resty.azure.api.keyvault"

describe("keyvault", function()
  local parent_client = {
    global_config = {
      AZURE_DEFAULTS_KEYVAULT_URI = "https://myvault.vault.azure.net",
      API_VERSION = "7.4"
    },
    make_request = function() end
  }

  describe(":build_url", function()
    it("builds a URL for a resource without a version", function()
      local kv = keyvault:new(parent_client)
      local url = kv:build_url("secrets", "mysecret")
      assert.is_equal(url, "https://myvault.vault.azure.net/secrets/mysecret?api-version=7.4")
    end)

    it("builds a URL for a resource with a version", function()
      local kv = keyvault:new(parent_client)
      local url = kv:build_url("secrets", "mysecret", "1.0")
      assert.is_equal(url, "https://myvault.vault.azure.net/secrets/mysecret/1.0?api-version=7.4")
    end)

    it("builds a URL with extra query args", function()
      local kv = keyvault:new(parent_client)
      local url = kv:build_url("secrets", "mysecret", nil, { extra_query_args = "&foo=bar" })
      assert.is_equal(url, "https://myvault.vault.azure.net/secrets/mysecret?api-version=7.4&foo=bar")
    end)
    it("builds a URL for a resource with a version and extra query args", function()
      local kv = keyvault:new(parent_client)
      local url = kv:build_url("secrets", "mysecret", "1.0", { extra_query_args = "&foo=bar" })
      assert.is_equal(url, "https://myvault.vault.azure.net/secrets/mysecret/1.0?api-version=7.4&foo=bar")
    end)

    it("builds a URL for a resource with a version and extra query args containing special characters", function()
      local kv = keyvault:new(parent_client)
      local url = kv:build_url("secrets", "mysecret", "1.0", { extra_query_args = "&foo=bar&baz=qux" })
      assert.is_equal(url, "https://myvault.vault.azure.net/secrets/mysecret/1.0?api-version=7.4&foo=bar&baz=qux")
    end)

    it("builds a URL for a resource with a version and extra query args containing encoded characters", function()
      local kv = keyvault:new(parent_client)
      local url = kv:build_url("secrets", "mysecret", "1.0", { extra_query_args = "&foo=bar%20baz" })
      assert.is_equal(url, "https://myvault.vault.azure.net/secrets/mysecret/1.0?api-version=7.4&foo=bar%20baz")
    end)

    it("builds a URL for a resource with a version and extra query args containing multiple encoded characters",
      function()
        local kv = keyvault:new(parent_client)
        local url = kv:build_url("secrets", "mysecret", "1.0", { extra_query_args = "&foo=bar%20baz&baz=qux%20quux" })
        assert.is_equal(url,
          "https://myvault.vault.azure.net/secrets/mysecret/1.0?api-version=7.4&foo=bar%20baz&baz=qux%20quux")
      end)
  end)
end)
