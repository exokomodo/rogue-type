--- HUD module.
-- Draws health, scrap, sector/wave, and seed display.

local HUD = {}

function HUD.draw(player, sector, wave, seed, screen_w)
  love.graphics.setColor(1, 1, 1, 0.9)

  -- Health bar (top-left)
  local hx, hy = 10, 8
  love.graphics.print("HP", hx, hy)
  love.graphics.setColor(0.3, 0.3, 0.3, 1)
  love.graphics.rectangle("fill", hx + 24, hy, 80, 12)
  -- Health fill
  local hp_frac = player.hp / player.max_hp
  local r = 1 - hp_frac
  local g = hp_frac
  love.graphics.setColor(r, g, 0.1, 1)
  love.graphics.rectangle("fill", hx + 24, hy, 80 * hp_frac, 12)

  -- Scrap (top-left, below health)
  love.graphics.setColor(1, 0.85, 0.2, 1)
  love.graphics.print("Scrap: " .. player.scrap, hx, hy + 18)

  -- Pod status (top-left, below scrap)
  local pod = player.pod
  local pod_label = "Pod: "
  if pod.state == "orbiting" then
    love.graphics.setColor(0, 0.9, 0.9, 1)
    pod_label = pod_label .. "ATTACHED"
  elseif pod.state == "launched" then
    love.graphics.setColor(1, 0.6, 0.1, 1)
    pod_label = pod_label .. "LAUNCHED"
  else
    love.graphics.setColor(0.6, 0.6, 1, 1)
    pod_label = pod_label .. "RETURNING"
  end
  if pod.upgrade_level > 0 then
    pod_label = pod_label .. " [+" .. pod.upgrade_level .. "]"
  end
  love.graphics.print(pod_label, hx, hy + 34)

  -- Sector / Wave (top-center)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.printf("Sector " .. sector .. " - Wave " .. wave, 0, 8, screen_w, "center")

  -- Seed (top-right)
  love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
  local seed_text = "Seed: " .. tostring(seed)
  love.graphics.printf(seed_text, 0, 8, screen_w - 10, "right")

  love.graphics.setColor(1, 1, 1, 1)
end

return HUD
