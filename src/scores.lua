--- Scores module.
-- Handles saving, loading, and displaying the local leaderboard.
-- Scores are stored as a serialized Lua table in the LOVE2D save directory.

local Scores = {}

local SCORES_FILE = "scores.lua"
local MAX_SCORES = 50  -- keep top 50, display top 3

--- Calculate the score for a run.
-- @param scrap      number of scrap collected
-- @param sector     sector reached
-- @param waves      total waves cleared
-- @return number
function Scores.calculate(scrap, sector, waves)
  return scrap + (sector * 100) + (waves * 20)
end

--- Load scores from the save directory.
-- @return table  list of {seed, score, sector, daily} sorted descending by score
function Scores.load()
  if not love or not love.filesystem then return {} end
  local info = love.filesystem.getInfo(SCORES_FILE)
  if not info then return {} end

  local contents = love.filesystem.read(SCORES_FILE)
  if not contents then return {} end

  -- Load the serialized table safely
  local fn = loadstring(contents)
  if not fn then return {} end

  local ok, data = pcall(fn)
  if not ok or type(data) ~= "table" then return {} end

  return data
end

--- Save a new score entry, keeping the list sorted and trimmed.
-- @param seed    the run seed
-- @param score   calculated score
-- @param sector  sector reached
-- @param daily   boolean, true if daily challenge
function Scores.save(seed, score, sector, daily)
  if not love or not love.filesystem then return end

  local scores = Scores.load()

  -- Insert new entry
  local entry = {
    seed = seed,
    score = score,
    sector = sector,
    daily = daily or false,
  }

  -- Insertion sort: find position
  local pos = #scores + 1
  for i = 1, #scores do
    if score > scores[i].score then
      pos = i
      break
    end
  end
  table.insert(scores, pos, entry)

  -- Trim to max
  while #scores > MAX_SCORES do
    scores[#scores] = nil
  end

  -- Serialize
  local lines = { "return {" }
  for _, s in ipairs(scores) do
    table.insert(lines, string.format(
      "  {seed=%d,score=%d,sector=%d,daily=%s},",
      s.seed, s.score, s.sector, tostring(s.daily)
    ))
  end
  table.insert(lines, "}")

  love.filesystem.write(SCORES_FILE, table.concat(lines, "\n"))
end

--- Draw the top N scores on screen.
-- @param x       left x position
-- @param y       top y position
-- @param screen_w  screen width (for centering)
-- @param count   number of scores to show (default 3)
function Scores.draw_top(_x, y, screen_w, count)
  count = count or 3
  local scores = Scores.load()

  love.graphics.setColor(0.8, 0.7, 0.2, 0.9)
  love.graphics.printf("-- TOP SCORES --", 0, y, screen_w, "center")

  if #scores == 0 then
    love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
    love.graphics.printf("No scores yet", 0, y + 18, screen_w, "center")
    return
  end

  for i = 1, math.min(count, #scores) do
    local s = scores[i]
    local label = s.daily and "DAILY" or tostring(s.seed)
    local line = string.format("#%d  %d pts  Sector %d  [%s]", i, s.score, s.sector, label)
    love.graphics.setColor(0.9, 0.85, 0.4, 0.8)
    love.graphics.printf(line, 0, y + 18 * i, screen_w, "center")
  end

  love.graphics.setColor(1, 1, 1, 1)
end

return Scores
