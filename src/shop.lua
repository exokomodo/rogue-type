--- Stub upgrade shop.
-- Shows 3 random upgrades purchasable with scrap between waves.

local Shop = {}
Shop.__index = Shop

-- All possible upgrades
local UPGRADE_POOL = {
  { name = "Rapid Fire",    desc = "Shoot faster",         cost = 5,  stat = "fire_rate",     delta = -0.02 },
  { name = "Damage Up",     desc = "+1 bullet damage",     cost = 8,  stat = "bullet_damage", delta = 1 },
  { name = "Speed Boost",   desc = "Move faster",          cost = 4,  stat = "speed",         delta = 40 },
  { name = "Hull Repair",   desc = "Restore 2 HP",         cost = 6,  stat = "hp",            delta = 2 },
  { name = "Max HP Up",     desc = "+1 max HP",            cost = 10, stat = "max_hp",        delta = 1 },
  { name = "Bullet Speed",  desc = "Faster projectiles",   cost = 5,  stat = "bullet_speed",  delta = 100 },
  { name = "Force Pod Upgrade", desc = "+Damage & absorb radius", cost = 12, stat = "pod", delta = 1 },
}

function Shop.new(rng)
  local self = setmetatable({}, Shop)
  self.items = {}
  self.selected = 1
  self:generate(rng)
  return self
end

--- Pick 4 random upgrades from the pool.
function Shop:generate(rng)
  self.items = {}
  local indices = {}
  for i = 1, #UPGRADE_POOL do indices[i] = i end
  -- Fisher-Yates shuffle (partial, 4 picks)
  local pick_count = math.min(4, #UPGRADE_POOL)
  for i = #indices, #indices - (pick_count - 1), -1 do
    local j = rng:random(1, i)
    indices[i], indices[j] = indices[j], indices[i]
    table.insert(self.items, UPGRADE_POOL[indices[i]])
  end
  self.selected = 1
end

--- Handle key press. Returns true if shop should close (player pressed enter to continue).
function Shop:keypressed(key, player)
  if key == "up" or key == "w" then
    self.selected = math.max(1, self.selected - 1)
  elseif key == "down" or key == "s" then
    self.selected = math.min(#self.items, self.selected + 1)
  elseif key == "return" or key == "space" or key == "z" then
    local item = self.items[self.selected]
    if item and player.scrap >= item.cost then
      player.scrap = player.scrap - item.cost
      -- Apply upgrade
      if item.stat == "hp" then
        player.hp = math.min(player.max_hp, player.hp + item.delta)
      elseif item.stat == "pod" then
        player.pod:upgrade()
      else
        player[item.stat] = player[item.stat] + item.delta
        -- Clamp fire rate so it doesn't go negative
        if item.stat == "fire_rate" then
          player.fire_rate = math.max(0.04, player.fire_rate)
        end
      end
      -- Mark as purchased
      item.purchased = true
    end
  elseif key == "escape" or key == "x" then
    return true  -- close shop, continue to next wave/boss
  end
  return false
end

function Shop:draw(screen_w, screen_h, player_scrap)
  -- Dim background
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 0, 0, screen_w, screen_h)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("=== UPGRADE SHOP ===", 0, 60, screen_w, "center")
  love.graphics.printf("Scrap: " .. player_scrap, 0, 85, screen_w, "center")

  local base_y = 130
  for i, item in ipairs(self.items) do
    local y = base_y + (i - 1) * 60
    local is_sel = (i == self.selected)

    -- Selection highlight
    if is_sel then
      love.graphics.setColor(0.3, 0.6, 1, 0.3)
      love.graphics.rectangle("fill", screen_w / 2 - 160, y - 4, 320, 50)
    end

    if item.purchased then
      love.graphics.setColor(0.4, 0.4, 0.4, 1)
      love.graphics.printf(item.name .. " [PURCHASED]", 0, y, screen_w, "center")
    else
      love.graphics.setColor(1, 1, 0.6, 1)
      love.graphics.printf(item.name .. "  [" .. item.cost .. " scrap]", 0, y, screen_w, "center")
      love.graphics.setColor(0.7, 0.7, 0.7, 1)
      love.graphics.printf(item.desc, 0, y + 18, screen_w, "center")
    end
  end

  love.graphics.setColor(0.5, 0.5, 0.5, 1)
  love.graphics.printf("W/S to navigate  |  SPACE to buy  |  ESC/X to continue", 0, screen_h - 40, screen_w, "center")
  love.graphics.setColor(1, 1, 1, 1)
end

return Shop
