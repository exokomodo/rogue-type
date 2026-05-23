--- Boss module.
-- A boss with 3 phases. Spawns after wave clear. Gets more aggressive each phase.

local Boss = {}
Boss.__index = Boss

function Boss.new(screen_w, screen_h, rng)
  local self = setmetatable({}, Boss)
  self.w = 60
  self.h = 50
  self.x = screen_w + 20  -- starts offscreen right
  self.y = screen_h / 2 - self.h / 2
  self.target_x = screen_w - 100
  self.hp = 30
  self.max_hp = 30
  self.phase = 1
  self.alive = true
  self.entering = true  -- sliding in
  self.time = 0
  self.fire_timer = 0
  self.scrap_value = 15
  self.rng = rng
  self.screen_w = screen_w
  self.screen_h = screen_h
  self.move_speed = 80
  self.base_y = self.y
  return self
end

function Boss:update(dt, bullets, player)
  if not self.alive then return end
  self.time = self.time + dt

  -- Slide into position
  if self.entering then
    self.x = self.x - 150 * dt
    if self.x <= self.target_x then
      self.x = self.target_x
      self.entering = false
    end
    return
  end

  -- Update phase based on remaining HP
  if self.hp <= self.max_hp * 0.33 then
    self.phase = 3
  elseif self.hp <= self.max_hp * 0.66 then
    self.phase = 2
  end

  -- Vertical movement — weave gets faster in later phases
  local weave_speed = 1.5 + self.phase * 0.5
  local weave_amp = 60 + self.phase * 20
  self.y = self.base_y + math.sin(self.time * weave_speed) * weave_amp
  self.y = math.max(10, math.min(self.screen_h - self.h - 10, self.y))

  -- Firing patterns per phase
  self.fire_timer = self.fire_timer - dt
  if self.fire_timer <= 0 and player.alive then
    self:fire_pattern(bullets, player)
    self.fire_timer = math.max(0.3, 1.2 - self.phase * 0.3)
  end
end

function Boss:fire_pattern(bullets, player)
  local cx = self.x
  local cy = self.y + self.h / 2

  if self.phase == 1 then
    -- Aimed triple shot
    local dx = player.x - cx
    local dy = (player.y + player.h / 2) - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
      local spd = 220
      local nx, ny = dx / dist, dy / dist
      for spread = -1, 1 do
        bullets:fire_enemy(cx, cy,
          nx * spd + ny * spread * 40,
          ny * spd - nx * spread * 40,
          { w = 8, h = 8 }
        )
      end
    end

  elseif self.phase == 2 then
    -- Fan of 5 bullets
    for i = 0, 4 do
      local angle = math.rad(-40 + i * 20) + math.pi
      bullets:fire_enemy(cx, cy,
        math.cos(angle) * 200,
        math.sin(angle) * 200,
        { w = 8, h = 8 }
      )
    end

  else
    -- Phase 3: dense radial burst
    local count = 10
    for i = 0, count - 1 do
      local angle = (i / count) * math.pi * 2 + self.time
      bullets:fire_enemy(cx, cy,
        math.cos(angle) * 180,
        math.sin(angle) * 180,
        { w = 7, h = 7 }
      )
    end
  end
end

function Boss:draw()
  if not self.alive then return end

  -- Phase-dependent color: green → orange → magenta
  local colors = {
    {0.2, 0.8, 0.3},
    {0.9, 0.6, 0.1},
    {0.8, 0.1, 0.6},
  }
  local c = colors[self.phase] or colors[3]
  love.graphics.setColor(c[1], c[2], c[3], 1)

  -- Main body
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

  -- Inner detail
  love.graphics.setColor(0.1, 0.1, 0.1, 0.6)
  love.graphics.rectangle("fill", self.x + 8, self.y + 8, self.w - 16, self.h - 16)

  -- Eye
  love.graphics.setColor(1, 0, 0, 1)
  love.graphics.circle("fill", self.x + 15, self.y + self.h / 2, 6 + math.sin(self.time * 5) * 2)

  -- HP bar above boss
  love.graphics.setColor(0.3, 0.3, 0.3, 1)
  love.graphics.rectangle("fill", self.x, self.y - 12, self.w, 6)
  love.graphics.setColor(1, 0.1, 0.1, 1)
  love.graphics.rectangle("fill", self.x, self.y - 12, self.w * (self.hp / self.max_hp), 6)

  love.graphics.setColor(1, 1, 1, 1)
end

return Boss
