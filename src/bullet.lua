--- Bullet manager.
-- Handles both player and enemy bullets in separate lists.

local Collision = require("collision")

local Bullets = {}
Bullets.__index = Bullets

function Bullets.new()
  local self = setmetatable({}, Bullets)
  self.player_bullets = {}  -- fired by the player, hurt enemies
  self.enemy_bullets = {}   -- fired by enemies, hurt the player
  return self
end

--- Spawn a player bullet at (x, y) moving right.
function Bullets:fire_player(x, y, speed, damage)
  table.insert(self.player_bullets, {
    x = x, y = y, w = 12, h = 4,
    vx = speed or 600, vy = 0,
    damage = damage or 1,
    alive = true,
  })
end

--- Spawn an enemy bullet at (x, y) with given velocity.
function Bullets:fire_enemy(x, y, vx, vy, opts)
  opts = opts or {}
  table.insert(self.enemy_bullets, {
    x = x, y = y, w = opts.w or 6, h = opts.h or 6,
    vx = vx, vy = vy,
    damage = opts.damage or 1,
    alive = true,
  })
end

function Bullets:update(dt, screen_w, screen_h)
  -- Move and cull player bullets
  for i = #self.player_bullets, 1, -1 do
    local b = self.player_bullets[i]
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt
    if b.x > screen_w + 20 or not b.alive then
      table.remove(self.player_bullets, i)
    end
  end
  -- Move and cull enemy bullets
  for i = #self.enemy_bullets, 1, -1 do
    local b = self.enemy_bullets[i]
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt
    if b.x < -20 or b.x > screen_w + 20 or b.y < -20 or b.y > screen_h + 20 or not b.alive then
      table.remove(self.enemy_bullets, i)
    end
  end
end

--- Check player bullets against a list of targets (enemies/boss).
-- Each target must have {x, y, w, h, alive, hp} fields.
-- Returns total scrap dropped from kills.
function Bullets:check_hits_on_targets(targets, on_kill)
  for _, b in ipairs(self.player_bullets) do
    if b.alive then
      for _, t in ipairs(targets) do
        if t.alive and Collision.aabb(b, t) then
          b.alive = false
          t.hp = t.hp - b.damage
          if t.hp <= 0 then
            t.alive = false
            if on_kill then on_kill(t) end
          end
          break
        end
      end
    end
  end
end

--- Check enemy bullets against the player rect.
-- Returns total damage dealt this frame.
function Bullets:check_hits_on_player(player)
  local dmg = 0
  for _, b in ipairs(self.enemy_bullets) do
    if b.alive and Collision.aabb(b, player) then
      b.alive = false
      dmg = dmg + b.damage
    end
  end
  return dmg
end

function Bullets:draw()
  -- Player bullets: bright cyan
  love.graphics.setColor(0, 1, 1, 1)
  for _, b in ipairs(self.player_bullets) do
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
  end
  -- Enemy bullets: red-orange
  love.graphics.setColor(1, 0.3, 0.1, 1)
  for _, b in ipairs(self.enemy_bullets) do
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

--- Clear all bullets (e.g. on state transition).
function Bullets:clear()
  self.player_bullets = {}
  self.enemy_bullets = {}
end

return Bullets
