--- Tests for the seeded RNG wrapper.
-- Verifies determinism: same seed → same sequence.

-- Stub love global so rng.lua falls back to LCG
love = nil

package.path = "src/?.lua;" .. package.path

local RNG = require("rng")

describe("RNG", function()
  it("should return the seed it was created with", function()
    local r = RNG.new(42)
    assert.are.equal(42, r:getSeed())
  end)

  it("should produce deterministic sequences from the same seed", function()
    local r1 = RNG.new(12345)
    local r2 = RNG.new(12345)
    local seq1, seq2 = {}, {}
    for i = 1, 20 do
      seq1[i] = r1:random()
      seq2[i] = r2:random()
    end
    for i = 1, 20 do
      assert.are.equal(seq1[i], seq2[i], "Mismatch at index " .. i)
    end
  end)

  it("should produce different sequences from different seeds", function()
    local r1 = RNG.new(111)
    local r2 = RNG.new(222)
    local same = true
    for _ = 1, 10 do
      if r1:random() ~= r2:random() then
        same = false
        break
      end
    end
    assert.is_false(same)
  end)

  it("should produce integers in range with random(lo, hi)", function()
    local r = RNG.new(999)
    for _ = 1, 50 do
      local v = r:random(5, 10)
      assert.is_true(v >= 5 and v <= 10, "Out of range: " .. v)
    end
  end)

  it("should produce integers in [1, n] with random(n)", function()
    local r = RNG.new(777)
    for _ = 1, 50 do
      local v = r:random(6)
      assert.is_true(v >= 1 and v <= 6, "Out of range: " .. v)
    end
  end)

  it("should generate a seed when none is provided", function()
    local r = RNG.new()
    assert.is_not_nil(r:getSeed())
    assert.is_true(r:getSeed() > 0)
  end)
end)
