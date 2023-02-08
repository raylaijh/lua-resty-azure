-- environment static config
local pl_path = require "pl.path"
local pl_config = require "pl.config"

-- globals
local stringtoboolean={ ["true"]=true, ["false"]=false }

-- The variables that do not have an equivalent in the config file get the
-- environment variable name (in all-caps).
local env_vars = {
  -- configuration files and settings
  AZURE_CONFIG_FILE = { name = "AZURE_CONFIG_FILE", default = "~/.azure/config" },

  -- credentials
  AZURE_CLIENT_ID = { name = "client_id", default = nil },
  AZURE_CLIENT_SECRET = { name = "client_secret", default = nil },
  AZURE_TENANT_ID = { name = "tenant_id", default = nil },

  -- cloud
  AZURE_DEFAULTS_LOCATION = { name = "defaults_location", default = nil },
  AZURE_DEFAULTS_KEYVAULT_URI = { name = "defaults_keyvault_uri", default = nil },
  AZURE_INSTANCE_METADATA_HOST = { name = "instance_metadata_host", default = "169.254.169.254" },
  AZURE_AUTH_BASE_URL = { name = "auth_base_url", default = nil },
  AZURE_AUTHORITY_HOST = { name = "authority_host", default = nil },
  AZURE_FEDERATED_TOKEN_FILE = { name = "federated_token_file", default = nil },

  -- resty.http
  AZURE_SSL_VERIFY = { name = "ssl_verify", default = false, type = "boolean" },
}

-- populate the env vars with their values, or defaults
for var_name, var in pairs(env_vars) do
  var.value = os.getenv(var_name) or var.default
  if var.type == "boolean" and type(var.value) == "string" then var.value = stringtoboolean[var.value] end
end

local fixed_vars = {
  API_VERSION = "7.1",
}

local config = {
  env_vars = env_vars,
  fixed_vars = fixed_vars,
}

do
  -- load a config file. If section given returns section only, otherwise full file.
  -- returns an empty table if the section does not exist
  local function load_file(filename, section)
    assert(type(filename) == "string", "expected filename to be a string")
    if not pl_path.isfile(filename) then
      return nil, "not a file: '"..filename.."'"
    end

    local contents, err = pl_config.read(filename, { variabilize = false })
    if not contents then
      return nil, "failed reading file '"..filename.."': "..tostring(err)
    end

    if not section then
      return contents
    end

    assert(type(section) == "string", "expected section to be a string or falsy")
    if not contents[section] then
      ngx.log(ngx.DEBUG, "section '",section,"' does not exist in file '",filename,"'")
      return {}
    end

    ngx.log(ngx.DEBUG, "loaded section '",section,"' from file '",filename,"'")
    return contents[section]
  end

  function config.load_configfile(filename)
    return load_file(filename)
  end
end

function config.load_config()
  if not pl_path.isfile(env_vars.AZURE_CONFIG_FILE.value) then
    -- file doesn't exist
    return {}
  end
  return config.load_configfile(env_vars.AZURE_CONFIG_FILE.value)
end

function config.get_config()
  local cfg = config.load_config() or {}   -- ignore error, already logged

  -- add environment variables
  for var_name, var in pairs(env_vars) do
    if cfg[var_name] == nil then  -- add the environment variable name with value
      cfg[var_name] = var.value
    end
    if cfg[var.name] == nil then  -- add the config file name with value
      cfg[var.name] = var.value
    end
  end

  for var_name, var_value in pairs(fixed_vars) do
    cfg[var_name] = var_value
  end

  if cfg.location == nil then
    cfg.location = cfg.AZURE_DEFAULTS_LOCATION
  end

  return cfg
end


--- returns the credentials from config file, credential file, or environment variables.
-- Reads the configuration files (config + credentials) and overrides them with
-- any environment variables specified.
-- @return table with credentials (`azure_client_id`, `azure_client_secret`, and `azure_tenant_id`)
function config.get_credentials()
  local creds = {
    azure_client_id = env_vars.AZURE_CLIENT_ID.value,
    azure_client_secret = env_vars.AZURE_CLIENT_SECRET.value,
    azure_tenant_id = env_vars.AZURE_TENANT_ID.value,
  }
  if next(creds) then
    -- isn't empty, so return it
    return creds
  end

  -- nothing in env-vars, so return config file data
  return config.load_credentials()
end

-- @field global configuration
-- @table somename
config.global = {}  -- trick LuaDoc
config.global = nil

return setmetatable(config, {
  __index = function(self, key)
    if key ~= "global" then
      return nil
    end
    -- Build the global config on demand since there is a recursive relation
    -- between this module and the utils module.
    self.global = assert(self.get_config())

    return self.global
  end
})
