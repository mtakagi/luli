local _  -- luli: noqa

-- 5.1
_ = module
_ = setfenv
_ = getfenv
_ = loadstring
_ = unpack

-- 5.2
_ = _ENV

local v = false
::start::
if not v then
  v = true
  goto start
end
