--- Rogue Type — main entry point and state machine.
-- States: menu, playing, shop, boss, gameover

local Player  = require("player")
local Bullets = require("bullet")
local Wave    = require("wave")
local Boss    = require("boss")
local Shop    = require("shop")
local HUD     = require("hud")
local RNG     = require("rng")
local ScrapMgr = require("scrap")

-- Game constants
local SCREEN_W = 960
local SCREEN_H = 540
local WAVES_PER_SECTOR = 3

-- Game state
local state         -- "menu", "playing", "shop", "boss", "gameover"
local rng           -- seeded RNG
local seed          -- current run seed
local player
local bullets
local scrap_mgr
local wave
local shop
local boss

local current_sector
local current_wave
local wave_clear_timer  -- brief pause before shop/boss

-- Stars background
local stars = {}

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local function init_stars()
  stars = {}
  for _ = 1, 80 do
    table.insert(stars, {
      x = math.random(0, SCREEN_W),
      y = math.random(0, SCREEN_H),
      speed = 20 + math.random() * 60,
      brightness = 0.3 + math.random() * 0.7,
    })
  end
end

local function update_stars(dt)
  for _, s in ipairs(stars) do
    s.x = s.x - s.speed * dt
    if s.x < 0 then
      s.x = SCREEN_W
      s.y = math.random(0, SCREEN_H)
    end
  end
end

local function draw_stars()
  for _, s in ipairs(stars) do
    love.graphics.setColor(s.brightness, s.brightness, s.brightness, 0.8)
    love.graphics.rectangle("fill", s.x, s.y, 2, 2)
  end
end

----------------------------------------------------------------------
-- State transitions
----------------------------------------------------------------------

local function start_run()
  seed = os.time() * 1000 + math.floor(os.clock() * 1000)
  rng = RNG.new(seed)
  bullets = Bullets.new()
  player = Player.new(bullets)
  scrap_mgr = ScrapMgr.new()
  current_sector = 1
  current_wave = 1
  wave_clear_timer = 0
  wave = Wave.new(rng, current_sector, current_wave, SCREEN_W, SCREEN_H)
  boss = nil
  shop = nil
  state = "playing"
end

local function enter_shop()
  shop = Shop.new(rng)
  bullets:clear()
  state = "shop"
end

local function enter_boss()
  boss = Boss.new(SCREEN_W, SCREEN_H, rng, current_sector)
  bullets:clear()
  state = "boss"
end

local function next_sector()
  current_sector = current_sector + 1
  current_wave = 1
  wave_clear_timer = 0
  wave = Wave.new(rng, current_sector, current_wave, SCREEN_W, SCREEN_H)
  bullets:clear()
  boss = nil
  state = "playing"
end

local function next_wave()
  current_wave = current_wave + 1
  wave_clear_timer = 0
  wave = Wave.new(rng, current_sector, current_wave, SCREEN_W, SCREEN_H)
  state = "playing"
end

----------------------------------------------------------------------
-- LÖVE callbacks
----------------------------------------------------------------------

function love.load()
  love.graphics.setBackgroundColor(0.04, 0.04, 0.08)
  love.graphics.setDefaultFilter("nearest", "nearest")
  init_stars()
  state = "menu"
end

function love.update(dt)
  -- Cap dt to prevent huge jumps
  dt = math.min(dt, 1 / 30)
  update_stars(dt)

  if state == "playing" then
    player:update(dt, SCREEN_W, SCREEN_H)
    bullets:update(dt, SCREEN_W, SCREEN_H)
    scrap_mgr:update(dt, player)
    wave:update(dt, bullets, player, scrap_mgr)

    -- Force pod: update, absorb bullets, damage enemies
    local pod = player.pod
    pod:update(dt, player, SCREEN_W)
    local absorbed = pod:absorb_bullets(bullets.enemy_bullets)
    if absorbed > 0 then player.scrap = player.scrap + absorbed end
    pod:check_hits_on_enemies(wave.enemies)

    -- Check player damage from enemy bullets
    local dmg = bullets:check_hits_on_player(player)
    if dmg > 0 then
      player:take_damage(dmg)
    end

    -- Player death
    if not player.alive then
      state = "gameover"
      return
    end

    -- Wave cleared → brief pause then shop or boss
    if wave.cleared then
      wave_clear_timer = wave_clear_timer + dt
      if wave_clear_timer > 0.8 then
        if current_wave >= WAVES_PER_SECTOR then
          enter_boss()
        else
          enter_shop()
        end
      end
    end

  elseif state == "boss" then
    player:update(dt, SCREEN_W, SCREEN_H)
    bullets:update(dt, SCREEN_W, SCREEN_H)
    scrap_mgr:update(dt, player)
    boss:update(dt, bullets, player)

    -- Force pod: update, absorb bullets, damage boss
    local pod = player.pod
    pod:update(dt, player, SCREEN_W)
    local absorbed = pod:absorb_bullets(bullets.enemy_bullets)
    if absorbed > 0 then player.scrap = player.scrap + absorbed end
    pod:check_hits_on_boss(boss)

    -- Player bullets vs boss
    bullets:check_hits_on_targets({boss}, function(dead_boss)
      scrap_mgr:spawn(dead_boss.x + dead_boss.w / 2, dead_boss.y + dead_boss.h / 2, dead_boss.scrap_value)
    end)

    -- Enemy bullets vs player
    local dmg = bullets:check_hits_on_player(player)
    if dmg > 0 then
      player:take_damage(dmg)
    end

    if not player.alive then
      state = "gameover"
      return
    end

    -- Boss defeated → next sector
    if not boss.alive then
      wave_clear_timer = (wave_clear_timer or 0) + dt
      if wave_clear_timer > 1.2 then
        enter_shop()
      end
    end

  end
end

function love.draw()
  draw_stars()

  if state == "menu" then
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.printf("ROGUE TYPE", 0, SCREEN_H / 2 - 60, SCREEN_W, "center")

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.printf("A Horizontal Bullet Hell Roguelite", 0, SCREEN_H / 2 - 30, SCREEN_W, "center")

    love.graphics.setColor(0.6, 0.6, 0.6, 0.7 + math.sin(love.timer.getTime() * 3) * 0.3)
    love.graphics.printf("Press SPACE or ENTER to start", 0, SCREEN_H / 2 + 30, SCREEN_W, "center")

    love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
    love.graphics.printf(
      "WASD/Arrows to move  |  SPACE/Z to shoot  |  X to launch/recall pod",
      0, SCREEN_H - 50, SCREEN_W, "center"
    )

  elseif state == "playing" then
    wave:draw()
    scrap_mgr:draw()
    bullets:draw()
    player:draw()
    player.pod:draw()

    if wave.cleared then
      love.graphics.setColor(0.2, 1, 0.4, 1)
      love.graphics.printf("WAVE CLEARED!", 0, SCREEN_H / 2 - 10, SCREEN_W, "center")
    end

    HUD.draw(player, current_sector, current_wave, seed, SCREEN_W)

  elseif state == "shop" then
    shop:draw(SCREEN_W, SCREEN_H, player.scrap)

  elseif state == "boss" then
    scrap_mgr:draw()
    bullets:draw()
    boss:draw()
    player:draw()
    player.pod:draw()

    if not boss.alive then
      love.graphics.setColor(1, 0.9, 0.2, 1)
      love.graphics.printf("BOSS DEFEATED!", 0, SCREEN_H / 2 - 10, SCREEN_W, "center")
    end

    HUD.draw(player, current_sector, "BOSS", seed, SCREEN_W)

  elseif state == "gameover" then
    love.graphics.setColor(0.9, 0.1, 0.1, 1)
    love.graphics.printf("GAME OVER", 0, SCREEN_H / 2 - 50, SCREEN_W, "center")

    love.graphics.setColor(1, 1, 1, 0.8)
    local status = "Sector " .. current_sector .. " - Wave " .. tostring(current_wave)
    love.graphics.printf(status, 0, SCREEN_H / 2 - 20, SCREEN_W, "center")
    love.graphics.printf("Scrap collected: " .. player.scrap, 0, SCREEN_H / 2, SCREEN_W, "center")

    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.printf("Run Seed: " .. tostring(seed), 0, SCREEN_H / 2 + 30, SCREEN_W, "center")

    love.graphics.setColor(0.5, 0.5, 0.5, 0.6 + math.sin(love.timer.getTime() * 3) * 0.3)
    love.graphics.printf("Press SPACE or ENTER to return to menu", 0, SCREEN_H / 2 + 70, SCREEN_W, "center")
  end
end

function love.keypressed(key)
  if key == "escape" then
    if state == "menu" then
      love.event.quit()
    elseif state ~= "shop" then
      state = "menu"
    end
  end

  if state == "menu" then
    if key == "space" or key == "return" then
      start_run()
    end

  elseif state == "shop" then
    local close = shop:keypressed(key, player)
    if close then
      if current_wave >= WAVES_PER_SECTOR then
        -- Shop after boss defeat → advance sector
        next_sector()
      else
        next_wave()
      end
    end

  elseif state == "playing" or state == "boss" then
    if key == "x" then
      player.pod:toggle(player)
    end

  elseif state == "gameover" then
    if key == "space" or key == "return" then
      state = "menu"
    end
  end
end
