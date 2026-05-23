--- Enemy module.
-- Enemies move in from the right side, fire at the player, and drop scrap on death.

local Config = require("config")

local Enemy = {}
Enemy.__index = Enemy

--- Create a single enemy.
-- @param fire_fn  optional firing function(enemy, bullets, player) from PatternGrammar
-- @param screen_h  screen height (needed by wall patterns)
function Enemy.new(x, y, rng, fire_fn, screen_h)
  local self = setmetatable({}, Enemy)
  self.x = x
  self.y = y
  self.w = 24
  self.h = 18
  self.hp = 2
  self.alive = true
  self.speed = 60 + rng:random(0, 40)
  self.fire_timer = 1.0 + rng:random() * 2.0  -- stagger initial shot
  self.fire_rate = 1.5 + rng:random() * 1.0
  self.scrap_value = 1
  self.sin_offset = rng:random() * math.pi * 2
  self.sin_amp = 20 + rng:random(0, 30)
  self.base_y = y
  self.time = 0
  self.fire_fn = fire_fn  -- pattern grammar firing function
  self.screen_h = screen_h or 540
  return self
end

function Enemy:update(dt, bullets, player)
  if not self.alive then return end

  self.time = self.time + dt

  -- Move left with a sinusoidal weave
  self.x = self.x - self.speed * dt
  self.y = self.base_y + math.sin(self.time * 2 + self.sin_offset) * self.sin_amp

  -- Fire at the player using pattern grammar or fallback aimed shot
  self.fire_timer = self.fire_timer - dt
  if self.fire_timer <= 0 and player.alive then
    self.fire_timer = self.fire_rate
    if self.fire_fn then
      self.fire_fn(self, bullets, player)
    else
      -- Fallback: simple aimed bullet
      local dx = player.x - self.x
      local dy = (player.y + player.h / 2) - (self.y + self.h / 2)
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist > 0 then
        local bspeed = 200
        bullets:fire_enemy(
          self.x, self.y + self.h / 2 - 3,
          dx / dist * bspeed, dy / dist * bspeed
        )
      end
    end
  end
end

function Enemy:draw()
  if not self.alive then return end
  -- Body
  love.graphics.setColor(0.9, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
  -- Eye/cockpit
  love.graphics.setColor(1, 1, 0.3, 1)
  love.graphics.circle("fill", self.x + 6, self.y + self.h / 2, 4)
  love.graphics.setColor(1, 1, 1, 1)

  -- Debug draw
  if Config.DEBUG_DRAW then
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
    love.graphics.circle("fill", self.x + self.w / 2, self.y + self.h / 2, 2)
    love.graphics.print("enemy", self.x, self.y - 12)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

--- Check if the enemy has scrolled off the left side.
function Enemy:is_offscreen()
  return self.x < -self.w - 20
end

return Enemy
