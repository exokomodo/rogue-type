--- Wave manager.
-- Spawns groups of enemies per wave. Tracks when a wave is cleared.

local Enemy = require("enemy")
local Patterns = require("patterns")

local Wave = {}
Wave.__index = Wave

function Wave.new(rng, sector_num, wave_num, screen_w, screen_h)
  local self = setmetatable({}, Wave)
  self.enemies = {}
  self.spawn_timer = 0
  self.spawn_interval = 0.6
  self.spawned = 0
  self.screen_w = screen_w
  self.screen_h = screen_h
  self.rng = rng
  self.sector_num = sector_num

  -- Pattern grammar for this wave's enemies
  self.grammar = Patterns.PatternGrammar.new(rng, sector_num)

  -- More enemies in later sectors/waves
  self.total_enemies = 3 + wave_num + sector_num * 2
  self.cleared = false
  return self
end

function Wave:update(dt, bullets, player, scrap_mgr)
  -- Spawn enemies over time
  if self.spawned < self.total_enemies then
    self.spawn_timer = self.spawn_timer - dt
    if self.spawn_timer <= 0 then
      self.spawn_timer = self.spawn_interval
      local y = self.rng:random(20, self.screen_h - 40)
      local fire_fn = self.grammar:build_enemy_pattern()
      local e = Enemy.new(self.screen_w + 10, y, self.rng, fire_fn, self.screen_h)
      table.insert(self.enemies, e)
      self.spawned = self.spawned + 1
    end
  end

  -- Update enemies
  for _, e in ipairs(self.enemies) do
    e:update(dt, bullets, player)
  end

  -- Player bullets vs enemies
  bullets:check_hits_on_targets(self.enemies, function(dead_enemy)
    scrap_mgr:spawn(dead_enemy.x, dead_enemy.y, dead_enemy.scrap_value)
  end)

  -- Remove dead/offscreen enemies
  for i = #self.enemies, 1, -1 do
    local e = self.enemies[i]
    if not e.alive or e:is_offscreen() then
      table.remove(self.enemies, i)
    end
  end

  -- Check if wave is cleared
  if self.spawned >= self.total_enemies and #self.enemies == 0 then
    self.cleared = true
  end
end

function Wave:draw()
  for _, e in ipairs(self.enemies) do
    e:draw()
  end
end

return Wave
