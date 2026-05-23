--- Seeded RNG wrapper using love.math.newRandomGenerator
-- All game randomness flows through this module so runs are reproducible.

local RNG = {}
RNG.__index = RNG

--- Create a new seeded RNG.
-- @param seed number|nil  If nil, generates a random seed from os.time + os.clock.
-- @return RNG instance
function RNG.new(seed)
  local self = setmetatable({}, RNG)
  self.seed = seed or (os.time() * 1000 + math.floor(os.clock() * 1000))
  -- love.math may not exist in test environment
  if love and love.math and love.math.newRandomGenerator then
    self.gen = love.math.newRandomGenerator(self.seed)
  else
    -- Fallback for unit tests (plain Lua)
    self.gen = nil
    self._state = self.seed
  end
  return self
end

--- Return the seed this RNG was created with.
function RNG:getSeed()
  return self.seed
end

--- Generate a random number.
-- No args: float in [0,1). One arg (n): integer in [1,n]. Two args (lo,hi): integer in [lo,hi].
function RNG:random(lo, hi)
  if self.gen then
    if lo and hi then
      return self.gen:random(lo, hi)
    elseif lo then
      return self.gen:random(lo)
    else
      return self.gen:random()
    end
  else
    -- Simple LCG fallback for tests without LÖVE
    self._state = (self._state * 1103515245 + 12345) % (2^31)
    local r = self._state / (2^31)
    if lo and hi then
      return math.floor(r * (hi - lo + 1)) + lo
    elseif lo then
      return math.floor(r * lo) + 1
    else
      return r
    end
  end
end

return RNG
