--- Procedural bullet pattern grammar system.
-- Each verb constructs a firing function: (cx, cy, bullets, player, rng, screen_h)
-- The PatternGrammar assembles verb sequences per enemy based on RNG + sector.

local Patterns = {}

----------------------------------------------------------------------
-- Pattern verbs
----------------------------------------------------------------------

--- Aimed: fires bullet(s) directly at the player's current position.
function Patterns.aimed(params)
  params = params or {}
  local speed = params.speed or 200
  local count = params.count or 1
  return function(cx, cy, bullets, player, _rng, _screen_h)
    local dx = player.x - cx
    local dy = (player.y + player.h / 2) - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= 0 then return end
    local nx, ny = dx / dist, dy / dist
    for i = 1, count do
      local offset = (i - (count + 1) / 2) * 0.08
      bullets:fire_enemy(cx, cy,
        (nx + ny * offset) * speed,
        (ny - nx * offset) * speed
      )
    end
  end
end

--- Burst: fires N bullets in a fan spread around a direction.
function Patterns.burst(params)
  params = params or {}
  local count = params.count or 5
  local spread = params.spread or (math.pi / 3)
  local speed = params.speed or 180
  local aim = params.aim ~= false  -- default: aim at player
  return function(cx, cy, bullets, player, _rng, _screen_h)
    local base_angle
    if aim then
      local dx = player.x - cx
      local dy = (player.y + player.h / 2) - cy
      base_angle = math.atan2(dy, dx)
    else
      base_angle = math.pi  -- straight left
    end
    for i = 0, count - 1 do
      local frac = count > 1 and (i / (count - 1)) or 0.5
      local a = base_angle - spread / 2 + frac * spread
      bullets:fire_enemy(cx, cy,
        math.cos(a) * speed,
        math.sin(a) * speed,
        { w = 7, h = 7 }
      )
    end
  end
end

--- Spiral: fires bullets rotating around a center point at intervals.
-- Each call advances the rotation angle.
function Patterns.spiral(params)
  params = params or {}
  local count = params.count or 3
  local speed = params.speed or 160
  local step = params.step or (math.pi / 6)
  local state = { angle = 0 }
  return function(cx, cy, bullets, _player, _rng, _screen_h)
    for i = 0, count - 1 do
      local a = state.angle + (i / count) * math.pi * 2
      bullets:fire_enemy(cx, cy,
        math.cos(a) * speed,
        math.sin(a) * speed,
        { w = 6, h = 6 }
      )
    end
    state.angle = state.angle + step
  end
end

--- Wall: fires a row of evenly-spaced bullets across the screen height.
-- One gap is left for the player to dodge through.
function Patterns.wall(params)
  params = params or {}
  local count = params.count or 7
  local speed = params.speed or 180
  return function(cx, _cy, bullets, _player, rng, screen_h)
    local gap = rng:random(0, count - 1)
    local spacing = screen_h / (count + 1)
    for i = 0, count - 1 do
      if i ~= gap then
        local y = spacing * (i + 1)
        bullets:fire_enemy(cx, y,
          -speed, 0,
          { w = 10, h = 4 }
        )
      end
    end
  end
end

--- Random: fires bullets in random directions (seeded).
function Patterns.random(params)
  params = params or {}
  local count = params.count or 4
  local speed = params.speed or 180
  return function(cx, cy, bullets, _player, rng, _screen_h)
    for _ = 1, count do
      local angle = rng:random() * math.pi * 2
      bullets:fire_enemy(cx, cy,
        math.cos(angle) * speed,
        math.sin(angle) * speed
      )
    end
  end
end

----------------------------------------------------------------------
-- PatternGrammar — assembles verb sequences per enemy
----------------------------------------------------------------------

local PatternGrammar = {}
PatternGrammar.__index = PatternGrammar

--- Create a new PatternGrammar for a given sector.
-- @param rng  RNG instance (seeded)
-- @param sector  current sector number (1+)
function PatternGrammar.new(rng, sector)
  local self = setmetatable({}, PatternGrammar)
  self.rng = rng
  self.sector = sector
  return self
end

--- Helper: pick n items from a list using rng.
local function pick(rng, list, n)
  local result = {}
  -- Copy and shuffle-pick
  local pool = {}
  for i, v in ipairs(list) do pool[i] = v end
  for _ = 1, math.min(n, #pool) do
    local idx = rng:random(1, #pool)
    table.insert(result, pool[idx])
    table.remove(pool, idx)
  end
  return result
end

--- Scale a parameter value by sector progression.
local function scale(base, sector, factor)
  return base + (sector - 1) * factor
end

--- Build a firing function for a regular enemy.
-- Returns function(enemy, bullets, player) called by enemy's fire timer.
function PatternGrammar:build_enemy_pattern()
  local sector = self.sector
  local rng = self.rng

  -- Speed and count scale with sector
  local speed_mult = 1.0 + (sector - 1) * 0.12
  local base_speed = math.floor(180 * speed_mult)

  -- Available verb pool depends on sector
  local verb_pool
  if sector <= 2 then
    verb_pool = { "aimed", "burst" }
  elseif sector <= 4 then
    verb_pool = { "aimed", "burst", "spiral", "wall" }
  else
    verb_pool = { "aimed", "burst", "spiral", "wall", "random" }
  end

  -- Pick 1-3 verbs for this enemy's pattern sequence
  local num_verbs = math.min(#verb_pool, 1 + math.floor(sector / 2))
  if num_verbs > 3 then num_verbs = 3 end
  local chosen = pick(rng, verb_pool, num_verbs)

  -- Build each verb into a fire function with sector-scaled params
  local sequence = {}
  for _, verb in ipairs(chosen) do
    local fn
    if verb == "aimed" then
      fn = Patterns.aimed({
        speed = base_speed,
        count = math.min(3, 1 + math.floor(sector / 3)),
      })
    elseif verb == "burst" then
      fn = Patterns.burst({
        speed = base_speed,
        count = scale(3, sector, 1),
        spread = math.pi / 4 + (sector - 1) * 0.05,
      })
    elseif verb == "spiral" then
      fn = Patterns.spiral({
        speed = math.floor(150 * speed_mult),
        count = scale(2, sector, 1),
        step = math.pi / (7 - math.min(sector, 4)),
      })
    elseif verb == "wall" then
      fn = Patterns.wall({
        speed = base_speed,
        count = scale(5, sector, 1),
      })
    elseif verb == "random" then
      fn = Patterns.random({
        speed = base_speed,
        count = scale(3, sector, 1),
      })
    end
    table.insert(sequence, fn)
  end

  -- Return cycling fire function matching (enemy, bullets, player) signature
  local idx = 0
  return function(enemy, bullets, player)
    idx = (idx % #sequence) + 1
    local cx = enemy.x
    local cy = enemy.y + enemy.h / 2
    sequence[idx](cx, cy, bullets, player, rng, enemy.screen_h or 540)
  end
end

--- Build a firing function for the boss, given a specific phase.
-- Returns function(cx, cy, bullets, player) for direct use in boss:fire_pattern.
function PatternGrammar:build_boss_phase(phase)
  local sector = self.sector
  local rng = self.rng
  local speed_mult = 1.0 + (sector - 1) * 0.1

  if phase == 1 then
    -- Phase 1: burst aimed at player
    local burst_fn = Patterns.burst({
      speed = math.floor(220 * speed_mult),
      count = scale(3, sector, 1),
      spread = math.pi / 4,
      aim = true,
    })
    return function(cx, cy, bullets, player)
      burst_fn(cx, cy, bullets, player, rng, 540)
    end

  elseif phase == 2 then
    -- Phase 2: spiral + aimed combo
    local spiral_fn = Patterns.spiral({
      speed = math.floor(200 * speed_mult),
      count = scale(3, sector, 1),
      step = math.pi / 5,
    })
    local aimed_fn = Patterns.aimed({
      speed = math.floor(240 * speed_mult),
      count = 2,
    })
    local toggle = { state = false }
    return function(cx, cy, bullets, player)
      if toggle.state then
        aimed_fn(cx, cy, bullets, player, rng, 540)
      else
        spiral_fn(cx, cy, bullets, player, rng, 540)
      end
      toggle.state = not toggle.state
    end

  else
    -- Phase 3: wall + spiral + aimed — all combined for chaos
    local wall_fn = Patterns.wall({
      speed = math.floor(200 * speed_mult),
      count = scale(6, sector, 1),
    })
    local spiral_fn = Patterns.spiral({
      speed = math.floor(180 * speed_mult),
      count = scale(4, sector, 1),
      step = math.pi / 4,
    })
    local aimed_fn = Patterns.aimed({
      speed = math.floor(260 * speed_mult),
      count = scale(2, sector, 1),
    })
    local step = { idx = 0 }
    return function(cx, cy, bullets, player)
      local choice = step.idx % 3
      if choice == 0 then
        wall_fn(cx, cy, bullets, player, rng, 540)
      elseif choice == 1 then
        spiral_fn(cx, cy, bullets, player, rng, 540)
      else
        aimed_fn(cx, cy, bullets, player, rng, 540)
      end
      step.idx = step.idx + 1
    end
  end
end

Patterns.PatternGrammar = PatternGrammar

return Patterns
