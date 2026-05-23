--- Scrap pickup module.
-- Scrap drops from dead enemies and floats toward the player for collection.

local Collision = require("collision")

local Scrap = {}
Scrap.__index = Scrap

function Scrap.new()
  local self = setmetatable({}, Scrap)
  self.pickups = {}
  return self
end

--- Spawn a scrap pickup at (x, y) with a given value.
function Scrap:spawn(x, y, value)
  table.insert(self.pickups, {
    x = x, y = y, w = 10, h = 10,
    value = value or 1,
    time = 0,
    alive = true,
  })
end

function Scrap:update(dt, player)
  for i = #self.pickups, 1, -1 do
    local s = self.pickups[i]
    s.time = s.time + dt

    -- Drift slowly left and bob
    s.x = s.x - 20 * dt
    s.y = s.y + math.sin(s.time * 4) * 0.5

    -- Magnet: if close to player, pull toward them
    local dx = (player.x + player.w / 2) - (s.x + s.w / 2)
    local dy = (player.y + player.h / 2) - (s.y + s.h / 2)
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 80 then
      local pull = 300 * dt
      s.x = s.x + (dx / dist) * pull
      s.y = s.y + (dy / dist) * pull
    end

    -- Collect on overlap
    if player.alive and Collision.aabb(s, player) then
      player.scrap = player.scrap + s.value
      s.alive = false
    end

    -- Remove if offscreen or collected
    if not s.alive or s.x < -20 then
      table.remove(self.pickups, i)
    end
  end
end

function Scrap:draw()
  for _, s in ipairs(self.pickups) do
    -- Golden diamond shape
    love.graphics.setColor(1, 0.85, 0.1, 1)
    local cx = s.x + s.w / 2
    local cy = s.y + s.h / 2
    local r = s.w / 2
    love.graphics.polygon("fill",
      cx, cy - r,
      cx + r, cy,
      cx, cy + r,
      cx - r, cy
    )
    love.graphics.setColor(1, 1, 0.6, 0.6)
    love.graphics.polygon("fill",
      cx, cy - r + 2,
      cx + r - 2, cy,
      cx, cy + r - 2,
      cx - r + 2, cy
    )
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function Scrap:clear()
  self.pickups = {}
end

return Scrap
