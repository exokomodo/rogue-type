--- Player ship module.
-- Handles movement, shooting, health, and drawing.

local ForcePod = require("forcepod")

local Player = {}
Player.__index = Player

function Player.new(bullets)
  local self = setmetatable({}, Player)
  self.x = 80
  self.y = 270 / 2
  self.w = 28
  self.h = 20
  self.speed = 280
  self.hp = 5
  self.max_hp = 5
  self.fire_rate = 0.12       -- seconds between shots
  self.fire_timer = 0
  self.bullet_speed = 600
  self.bullet_damage = 1
  self.scrap = 0
  self.invuln_time = 0        -- brief invulnerability after taking damage
  self.bullets = bullets      -- reference to shared Bullets manager
  self.alive = true
  self.pod = ForcePod.new()
  return self
end

function Player:update(dt, screen_w, screen_h)
  if not self.alive then return end

  -- Movement
  local dx, dy = 0, 0
  if love.keyboard.isDown("w") or love.keyboard.isDown("up")    then dy = -1 end
  if love.keyboard.isDown("s") or love.keyboard.isDown("down")  then dy =  1 end
  if love.keyboard.isDown("a") or love.keyboard.isDown("left")  then dx = -1 end
  if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx =  1 end

  -- Normalize diagonal movement
  if dx ~= 0 and dy ~= 0 then
    local inv = 1 / math.sqrt(2)
    dx, dy = dx * inv, dy * inv
  end

  self.x = self.x + dx * self.speed * dt
  self.y = self.y + dy * self.speed * dt

  -- Clamp to screen
  self.x = math.max(0, math.min(screen_w - self.w, self.x))
  self.y = math.max(0, math.min(screen_h - self.h, self.y))

  -- Shooting
  self.fire_timer = self.fire_timer - dt
  if love.keyboard.isDown("space") or love.keyboard.isDown("z") then
    if self.fire_timer <= 0 then
      self.fire_timer = self.fire_rate
      self.bullets:fire_player(
        self.x + self.w,
        self.y + self.h / 2 - 2,
        self.bullet_speed,
        self.bullet_damage
      )
    end
  end

  -- Invulnerability countdown
  if self.invuln_time > 0 then
    self.invuln_time = self.invuln_time - dt
  end
end

--- Apply damage to the player. Respects invulnerability frames.
function Player:take_damage(amount)
  if self.invuln_time > 0 then return end
  self.hp = self.hp - amount
  self.invuln_time = 0.8  -- brief invulnerability
  if self.hp <= 0 then
    self.hp = 0
    self.alive = false
  end
end

function Player:draw()
  if not self.alive then return end

  -- Flash when invulnerable
  if self.invuln_time > 0 and math.floor(self.invuln_time * 10) % 2 == 0 then
    return
  end

  -- Ship body (a pointy shape made of rectangles/triangles)
  love.graphics.setColor(0.2, 0.8, 1, 1)
  love.graphics.rectangle("fill", self.x, self.y + 4, self.w - 8, self.h - 8)
  -- Nose
  love.graphics.polygon("fill",
    self.x + self.w - 8, self.y + 2,
    self.x + self.w + 4, self.y + self.h / 2,
    self.x + self.w - 8, self.y + self.h - 2
  )
  -- Wing top
  love.graphics.setColor(0.1, 0.6, 0.9, 1)
  love.graphics.polygon("fill",
    self.x + 4, self.y + 4,
    self.x + 14, self.y - 4,
    self.x + 14, self.y + 4
  )
  -- Wing bottom
  love.graphics.polygon("fill",
    self.x + 4, self.y + self.h - 4,
    self.x + 14, self.y + self.h + 4,
    self.x + 14, self.y + self.h - 4
  )
  -- Engine glow
  love.graphics.setColor(1, 0.6, 0.1, 0.8)
  love.graphics.rectangle("fill", self.x - 6, self.y + 6, 8, self.h - 12)

  love.graphics.setColor(1, 1, 1, 1)
end

return Player
