--- PodIdentityCredentials class.
-- @classmod PodIdentityCredentials


-- Create class
local Super = require "resty.azure.credentials.Credentials"
local PodIdentityCredentials = setmetatable({}, Super)
local json = require "cjson.safe"
PodIdentityCredentials.__index = PodIdentityCredentials


--- Constructor, inherits from `Credentials`.
--
-- @function azure:PodIdentityCredentials
-- @param opt options table, additional fields to the `Credentials` class:
-- @param opt.envPrefix prefix to use when looking for environment variables, defaults to "AZURE".
function PodIdentityCredentials:new(global_config, opts)
  local self = Super:new(opts)  -- override 'self' to be the new object/class
  setmetatable(self, PodIdentityCredentials)

  return self, "PodIdentityCredentials class not yet implemented"
end


-- updates credentials.
-- @return success, or nil+err
function PodIdentityCredentials:refresh()
  return false, "PodIdentityCredentials class not yet implemented"
end

return PodIdentityCredentials
