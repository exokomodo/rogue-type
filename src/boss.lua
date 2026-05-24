--- Boss module.
-- A boss with 3 phases. Spawns after wave clear. Gets more aggressive each phase.

local Patterns = require("patterns")
local Audio = require("audio")

local Boss = {}
Boss.__index = Boss

function Boss.new(screen_w, screen_h, rng, sector)
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

  -- Build pattern grammar firing functions for each phase
  local grammar = Patterns.PatternGrammar.new(rng, sector or 1)
  self.phase_patterns = {
    grammar:build_boss_phase(1),
    grammar:build_boss_phase(2),
    grammar:build_boss_phase(3),
  }

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
  local prev_phase = self.phase
  if self.hp <= self.max_hp * 0.33 then
    self.phase = 3
  elseif self.hp <= self.max_hp * 0.66 then
    self.phase = 2
  end
  if self.phase ~= prev_phase then
    Audio.play("boss_phase_change")
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
  local pattern_fn = self.phase_patterns[self.phase] or self.phase_patterns[3]
  pattern_fn(cx, cy, bullets, player)
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
