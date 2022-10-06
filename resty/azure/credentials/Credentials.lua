--- Credentials class.
-- Manually sets credentials.
-- Also the base class for all credential classes.
-- @classmod Credentials
local parse_date = require("luatz").parse.rfc_3339
local semaphore = require "ngx.semaphore"


local SEMAPHORE_TIMEOUT = 30 -- semaphore timeout in seconds

-- Executes a xpcall but returns hard-errors as Lua 'nil+err' result.
-- Handles max of 10 return values.
-- @param f function to execute
-- @param ... parameters to pass to the function
local function safe_call(f, ...)
  local ok, result, err, r3, r4, r5, r6, r7, r8, r9, r10 = xpcall(f, debug.traceback, ...)
  if ok then
    return result, err, r3, r4, r5, r6, r7, r8, r9, r10
  end
  return nil, result
end


local Credentials = {}
Credentials.__index = Credentials

--- Constructor.
-- @function azure:Credentials
-- @param opts options table
-- @param opts.token (optional) only specify if you manually specify credentials
-- @param opts.expireTime (optional, number (epoch) or string (rfc3339)). This should
-- not be specified. Default: If any of the 3 secrets are given; 10yrs, otherwise 0
-- (forcing a refresh on the first call to `get`).
-- @usage
-- local my_creds = azure:Credentials {
--   token = "token",
-- }
function Credentials:new(opts)
  local self = {}  -- override 'self' to be the new object/class
  setmetatable(self, Credentials)

  opts = opts or {}
  if opts.azure then
    if getmetatable(opts.azure) ~= require("resty.azure") then
      error("'opts.azure' must be set to an Azure instance or nil")
    end
    self.azure = opts.azure
  end

  if opts.token then
    -- credentials provided, if no expire given then use 10 yrs
    self:set(opts.token, opts.expireTime or (ngx.now() + 10*365*24*60*60))
  else
    self.token = nil
    self.expireTime = 0  -- force refresh on next "get"
  end
  -- self.expired     -- not implemented
  self.expiryWindow = opts.expiryWindow or 15 -- time in seconds befoer expireTime creds should be refreshed

  return self
end

--- checks whether credentials have expired.
-- @return boolean
function Credentials:needsRefresh()
  ngx.update_time()

  return (self.expireTime or 0) < ngx.now()
end

--- Gets credentials, refreshes if required.
-- Returns current Azure token.
--
-- When a refresh is executed, it will be done within a semaphore to prevent
-- many simultaneous refreshes.
-- @return success(true) + token + expireTime or success(false) + error


function Credentials:get()
  local ok, sema, err
  while self:needsRefresh() do
    if self.semaphore then
      -- an update is in progress
      ok, err = self.semaphore:wait(SEMAPHORE_TIMEOUT)
      if not ok then
        ngx.log(ngx.ERR, "[Credentials ", self.type, "] waiting for semaphore failed: ", err)
        return false, nil, nil, "waiting for semaphore failed: " .. tostring(err)
      end
    else
      -- no update in progress
      sema, err = semaphore.new()
      self.semaphore = sema
      if not sema then
        return false, nil, nil, "create semaphore failed: " .. tostring(err)
      end

      ok, err = safe_call(self.refresh, self)

      -- release all waiting threads
      self.semaphore = nil
      sema:post(math.abs(sema:count())+1)

      if not ok then return
        false, nil, nil, err
      end
      break
    end
  end
  -- we always return a boolean successvalue, if we would rely on standard Lua
  -- "nil + err" behaviour, then if the accessKeyId happens to be 'nil' for some
  -- reason, we risk logging the secretAccessKey as the error message in some
  -- client code.
  return true, self.token, self.expireTime, err
end


--- Sets credentials.
-- additional to Azure SDK
-- @param token
-- @param expireTime (optional) number (unix epoch based), or string (valid rfc 3339)
-- @return true
function Credentials:set(token, expireTime)
  local expiration
  if type(expireTime) == "string" then
    expiration = parse_date(expireTime):timestamp()
  end
  if type(expireTime) == "number" then
    expiration = expireTime
  end
  if not expiration then
    error("expected expireTime to be a number (unix epoch based), or string (valid rfc 3339)", 2)
  end

  self.expireTime = expiration
  self.token = token
  return true
end

--- updates credentials.
-- override in subclasses, should call `set` to set the properties.
-- @return success, or nil+err
function Credentials:refresh()
  error("Not implemented")
end

-- not implemented
function Credentials:getPromise()
  error("Not implemented")
end
function Credentials:refreshPromise()
  error("Not implemented")
end

return Credentials
