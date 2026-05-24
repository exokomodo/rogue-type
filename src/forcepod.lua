--- Force Pod module.
-- A detachable companion pod that orbits the player, absorbs enemy bullets,
-- and can be launched as a projectile. Signature R-Type homage mechanic.

local Config = require("config")

local ForcePod = {}
ForcePod.__index = ForcePod

local ORBIT_RADIUS   = 30
local ORBIT_SPEED    = 3.0    -- radians per second
local LAUNCH_SPEED   = 400
local RETURN_SPEED   = 350
local BASE_HIT_RADIUS = 20
local BASE_DAMAGE     = 3
local ABSORB_REWARD   = 2     -- scrap per bullet absorbed

function ForcePod.new()
  local self = setmetatable({}, ForcePod)
  self.state = "orbiting"   -- "orbiting", "launched", "returning"
  self.x = 0
  self.y = 0
  self.radius = 12          -- visual/draw radius
  self.hit_radius = BASE_HIT_RADIUS
  self.damage = BASE_DAMAGE
  self.orbit_angle = 0
  self.upgrade_level = 0
  self.glow_time = 0        -- for pulsing glow effect
  return self
end

--- Toggle launch/recall. Called when player presses X.
function ForcePod:toggle(_player)
  if self.state == "orbiting" then
    self.state = "launched"
  elseif self.state == "launched" then
    self.state = "returning"
  end
  -- If already returning, pressing X again does nothing extra
end

function ForcePod:update(dt, player, screen_w)
  self.glow_time = self.glow_time + dt

  if self.state == "orbiting" then
    self.orbit_angle = self.orbit_angle + ORBIT_SPEED * dt
    local cx = player.x + player.w / 2
    local cy = player.y + player.h / 2
    self.x = cx + ORBIT_RADIUS * math.cos(self.orbit_angle)
    self.y = cy + ORBIT_RADIUS * math.sin(self.orbit_angle)

  elseif self.state == "launched" then
    self.x = self.x + LAUNCH_SPEED * dt
    -- Hit right edge → start returning
    if self.x > screen_w + self.radius then
      self.state = "returning"
    end

  elseif self.state == "returning" then
    local cx = player.x + player.w / 2
    local cy = player.y + player.h / 2
    local dx = cx - self.x
    local dy = cy - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 10 then
      self.state = "orbiting"
    else
      local nx, ny = dx / dist, dy / dist
      self.x = self.x + nx * RETURN_SPEED * dt
      self.y = self.y + ny * RETURN_SPEED * dt
    end
  end
end

--- Check pod vs enemy bullets. Absorbs bullets within hit_radius.
-- Returns scrap earned from absorption.
function ForcePod:absorb_bullets(enemy_bullets)
  local scrap_earned = 0
  for _, b in ipairs(enemy_bullets) do
    if b.alive then
      local bx = b.x + b.w / 2
      local by = b.y + b.h / 2
      local dx = bx - self.x
      local dy = by - self.y
      if dx * dx + dy * dy < self.hit_radius * self.hit_radius then
        b.alive = false
        scrap_earned = scrap_earned + ABSORB_REWARD
      end
    end
  end
  return scrap_earned
end

--- Check pod vs enemies (only while launched or returning).
-- Damages enemies the pod passes through.
function ForcePod:check_hits_on_enemies(enemies)
  if self.state == "orbiting" then return end
  for _, e in ipairs(enemies) do
    if e.alive then
      -- Circle vs AABB: find closest point on enemy rect to pod center
      local closest_x = math.max(e.x, math.min(self.x, e.x + e.w))
      local closest_y = math.max(e.y, math.min(self.y, e.y + e.h))
      local dx = closest_x - self.x
      local dy = closest_y - self.y
      if dx * dx + dy * dy < self.radius * self.radius then
        e.hp = e.hp - self.damage
        if e.hp <= 0 then
          e.alive = false
        end
      end
    end
  end
end

--- Check pod vs boss (only while launched or returning).
function ForcePod:check_hits_on_boss(boss)
  if self.state == "orbiting" then return end
  if not boss or not boss.alive then return end
  local closest_x = math.max(boss.x, math.min(self.x, boss.x + boss.w))
  local closest_y = math.max(boss.y, math.min(self.y, boss.y + boss.h))
  local dx = closest_x - self.x
  local dy = closest_y - self.y
  if dx * dx + dy * dy < self.radius * self.radius then
    boss.hp = boss.hp - self.damage
    if boss.hp <= 0 then
      boss.alive = false
    end
  end
end

--- Apply an upgrade: increases damage and absorption radius.
function ForcePod:upgrade()
  self.upgrade_level = self.upgrade_level + 1
  self.damage = BASE_DAMAGE + self.upgrade_level * 2
  self.hit_radius = BASE_HIT_RADIUS + self.upgrade_level * 5
end

function ForcePod:draw()
  local glow = 0.6 + math.sin(self.glow_time * 4) * 0.4

  -- Outer glow
  love.graphics.setColor(0, 1, 1, 0.15 * glow)
  love.graphics.circle("fill", self.x, self.y, self.radius + 6)

  -- Main body: diamond shape, cyan
  love.graphics.setColor(0, 0.9, 0.9, glow)
  local r = self.radius
  love.graphics.polygon("fill",
    self.x, self.y - r,
    self.x + r, self.y,
    self.x, self.y + r,
    self.x - r, self.y
  )

  -- Inner highlight
  love.graphics.setColor(0.6, 1, 1, 0.8)
  local ir = r * 0.5
  love.graphics.polygon("fill",
    self.x, self.y - ir,
    self.x + ir, self.y,
    self.x, self.y + ir,
    self.x - ir, self.y
  )

  love.graphics.setColor(1, 1, 1, 1)

  -- Debug draw
  if Config.DEBUG_DRAW then
    love.graphics.setColor(0, 1, 1, 1)
    -- AABB around the pod (using radius as half-size)
    local r = self.radius
    love.graphics.rectangle("line", self.x - r, self.y - r, r * 2, r * 2)
    love.graphics.circle("fill", self.x, self.y, 2)
    love.graphics.print("pod", self.x - r, self.y - r - 12)
    -- Orbit radius circle around player center (needs player ref)
    -- Drawn from main.lua since we need player position
    love.graphics.setColor(1, 1, 1, 1)
  end
end

--- Draw orbit radius circle (called from main with player ref).
function ForcePod:draw_debug_orbit(player)
  if not Config.DEBUG_DRAW then return end
  love.graphics.setColor(0, 1, 1, 0.5)
  local cx = player.x + player.w / 2
  local cy = player.y + player.h / 2
  love.graphics.circle("line", cx, cy, ORBIT_RADIUS)
  love.graphics.setColor(1, 1, 1, 1)
end

return ForcePod
