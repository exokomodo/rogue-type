--- Audio manager.
-- Procedurally generates chiptune SFX and dynamic looping music.
-- No external asset files required — all sounds built from waveforms.

local Audio = {}

local master_volume = 1.0
local sfx_sources = {}      -- name → Source
local music_sources = {}    -- tier → Source  ("early", "mid", "late")
local current_music = nil   -- currently playing tier name
local next_music = nil      -- tier we are crossfading toward
local fade_time = 0         -- remaining crossfade seconds
local FADE_DURATION = 1.5   -- seconds to crossfade

----------------------------------------------------------------------
-- Waveform helpers
----------------------------------------------------------------------

local SAMPLE_RATE = 44100

--- Generate a SoundData buffer and return a Source.
-- @param samples  number of samples
-- @param gen_fn   function(i, t) → sample value in [-1, 1]
-- @param looping  bool
local function make_source(samples, gen_fn, looping)
  local sd = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)
  for i = 0, samples - 1 do
    local t = i / SAMPLE_RATE
    local v = gen_fn(i, t)
    -- clamp
    if v > 1 then v = 1 elseif v < -1 then v = -1 end
    sd:setSample(i, v)
  end
  local src = love.audio.newSource(sd)
  if looping then src:setLooping(true) end
  return src
end

--- Simple envelope: linear attack + decay.
local function env_decay(i, total)
  local pos = i / total
  -- tiny 2ms attack to avoid click
  local attack = math.min(1, i / (SAMPLE_RATE * 0.002))
  local decay = 1 - pos
  return attack * decay
end

----------------------------------------------------------------------
-- SFX generators
----------------------------------------------------------------------

local function gen_shoot()
  local dur = 0.08
  local n = math.floor(SAMPLE_RATE * dur)
  return make_source(n, function(i, t)
    local freq = 880
    local v = (math.sin(2 * math.pi * freq * t) > 0) and 0.3 or -0.3
    return v * env_decay(i, n)
  end)
end

local function gen_enemy_death()
  local dur = 0.15
  local n = math.floor(SAMPLE_RATE * dur)
  return make_source(n, function(i, t)
    local progress = i / n
    local freq = 600 - 400 * progress  -- 600 → 200 Hz sweep
    local v = (math.sin(2 * math.pi * freq * t) > 0) and 0.35 or -0.35
    return v * env_decay(i, n)
  end)
end

local function gen_hit()
  local dur = 0.1
  local n = math.floor(SAMPLE_RATE * dur)
  return make_source(n, function(i, t)
    -- low noise burst at ~120 Hz mixed with noise
    local tone = 0.25 * math.sin(2 * math.pi * 120 * t)
    local noise = (math.random() * 2 - 1) * 0.2
    return (tone + noise) * env_decay(i, n)
  end)
end

local function gen_boss_phase_change()
  local dur = 0.4
  local n = math.floor(SAMPLE_RATE * dur)
  return make_source(n, function(i, t)
    local progress = i / n
    -- low rumble + rising tone
    local rumble = 0.2 * math.sin(2 * math.pi * 55 * t)
    local rise_freq = 150 + 500 * progress  -- 150 → 650 Hz
    local rise = 0.2 * math.sin(2 * math.pi * rise_freq * t)
    local env = env_decay(i, n)
    -- boost sustain so it doesn't fade too fast
    env = math.max(env, (1 - progress) * 0.6)
    return (rumble + rise) * env
  end)
end

local function gen_scrap_pickup()
  local dur = 0.06
  local n = math.floor(SAMPLE_RATE * dur)
  return make_source(n, function(i, t)
    local freq = 1200
    local v = 0.25 * math.sin(2 * math.pi * freq * t)
    return v * env_decay(i, n)
  end)
end

local function gen_pod_launch()
  local dur = 0.12
  local n = math.floor(SAMPLE_RATE * dur)
  return make_source(n, function(i, t)
    local progress = i / n
    local freq = 600 - 400 * progress  -- descending whoosh
    local v = (math.sin(2 * math.pi * freq * t) > 0) and 0.25 or -0.25
    return v * env_decay(i, n)
  end)
end

local function gen_pod_recall()
  local dur = 0.1
  local n = math.floor(SAMPLE_RATE * dur)
  return make_source(n, function(i, t)
    local progress = i / n
    local freq = 400 + 600 * progress  -- ascending beep
    local v = (math.sin(2 * math.pi * freq * t) > 0) and 0.25 or -0.25
    return v * env_decay(i, n)
  end)
end

----------------------------------------------------------------------
-- Music generators
----------------------------------------------------------------------

--- Build an arpeggiated square-wave loop.
-- @param notes  table of {freq, duration_in_beats} pairs
-- @param bpm    beats per minute
-- @param amp    amplitude
local function gen_arpeggio_loop(notes, bpm, amp, wave_type)
  wave_type = wave_type or "square"
  amp = amp or 0.12

  -- compute total duration
  local beat_dur = 60 / bpm
  local total_beats = 0
  for _, note in ipairs(notes) do
    total_beats = total_beats + note[2]
  end
  local total_dur = total_beats * beat_dur
  local n = math.floor(SAMPLE_RATE * total_dur)

  return make_source(n, function(i, t)
    -- figure out which note we're in
    local elapsed_beats = t / beat_dur
    local acc = 0
    local freq = 0
    for _, note in ipairs(notes) do
      acc = acc + note[2]
      if elapsed_beats < acc then
        freq = note[1]
        break
      end
    end
    if freq == 0 then return 0 end  -- rest / silence

    local v
    if wave_type == "sine" then
      v = amp * math.sin(2 * math.pi * freq * t)
    else
      v = (math.sin(2 * math.pi * freq * t) > 0) and amp or -amp
    end

    -- global gentle envelope to avoid clicks at loop boundary
    local edge = math.min(i / (SAMPLE_RATE * 0.005), (n - 1 - i) / (SAMPLE_RATE * 0.005), 1)
    return v * edge
  end, true)
end

local function gen_music_early()
  -- Upbeat C-major arpeggio: C5 E5 G5 C6, 1 beat each, 240 bpm ≈ 1s loop
  local notes = {
    {523.25, 1}, {659.25, 1}, {783.99, 1}, {1046.50, 1},
    {783.99, 1}, {659.25, 1}, {523.25, 1}, {440.00, 1},
  }
  return gen_arpeggio_loop(notes, 240, 0.10, "square")
end

local function gen_music_mid()
  -- Tenser A-minor arpeggio, lower register, slower
  local notes = {
    {220.00, 1}, {261.63, 1}, {329.63, 1}, {220.00, 1},
    {196.00, 1}, {261.63, 1}, {293.66, 1}, {196.00, 1},
  }
  return gen_arpeggio_loop(notes, 180, 0.10, "square")
end

local function gen_music_late()
  -- Sparse eerie sine pulses with rests
  local notes = {
    {130.81, 2}, {0, 1},  -- C3 then silence
    {146.83, 2}, {0, 2},  -- D3 then silence
    {110.00, 3}, {0, 2},  -- A2 then silence
  }
  return gen_arpeggio_loop(notes, 120, 0.08, "sine")
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

--- Generate all sounds. Call once in love.load().
function Audio.init()
  sfx_sources = {
    shoot            = gen_shoot(),
    enemy_death      = gen_enemy_death(),
    hit              = gen_hit(),
    boss_phase_change = gen_boss_phase_change(),
    scrap_pickup     = gen_scrap_pickup(),
    pod_launch       = gen_pod_launch(),
    pod_recall       = gen_pod_recall(),
  }

  music_sources = {
    early = gen_music_early(),
    mid   = gen_music_mid(),
    late  = gen_music_late(),
  }

  -- Start all music at volume 0
  for _, src in pairs(music_sources) do
    src:setVolume(0)
    src:play()
  end

  current_music = nil
  next_music = nil
  fade_time = 0
end

--- Play a one-shot SFX by name. Restarts if already playing.
function Audio.play(name)
  local src = sfx_sources[name]
  if not src then return end
  src:stop()
  src:setVolume(master_volume)
  src:play()
end

--- Crossfade music to match the current sector.
-- Call each frame from love.update.
function Audio.update(sector, dt)
  -- Determine target tier
  local tier
  if sector <= 2 then
    tier = "early"
  elseif sector <= 4 then
    tier = "mid"
  else
    tier = "late"
  end

  -- Kick off crossfade if tier changed
  if tier ~= current_music and tier ~= next_music then
    next_music = tier
    fade_time = FADE_DURATION
  end

  -- Process crossfade
  if next_music and fade_time > 0 then
    fade_time = fade_time - (dt or 0)
    if fade_time <= 0 then
      -- Snap volumes
      for name, src in pairs(music_sources) do
        if name == next_music then
          src:setVolume(0.5 * master_volume)
        else
          src:setVolume(0)
        end
      end
      current_music = next_music
      next_music = nil
    else
      local progress = 1 - (fade_time / FADE_DURATION)
      for name, src in pairs(music_sources) do
        if name == next_music then
          src:setVolume(progress * 0.5 * master_volume)
        elseif name == current_music then
          src:setVolume((1 - progress) * 0.5 * master_volume)
        else
          src:setVolume(0)
        end
      end
    end
  end
end

--- Set master volume (0–1).
function Audio.set_volume(v)
  master_volume = math.max(0, math.min(1, v))
  -- Update any currently playing music
  for name, src in pairs(music_sources) do
    if name == current_music then
      src:setVolume(0.5 * master_volume)
    end
  end
end

return Audio
