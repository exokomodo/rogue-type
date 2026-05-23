--- Tests for AABB collision helpers.

package.path = "src/?.lua;" .. package.path

local Collision = require("collision")

describe("Collision.aabb", function()
  it("should detect overlapping rectangles", function()
    local a = { x = 0, y = 0, w = 10, h = 10 }
    local b = { x = 5, y = 5, w = 10, h = 10 }
    assert.is_true(Collision.aabb(a, b))
  end)

  it("should not detect separated rectangles", function()
    local a = { x = 0, y = 0, w = 10, h = 10 }
    local b = { x = 20, y = 20, w = 10, h = 10 }
    assert.is_false(Collision.aabb(a, b))
  end)

  it("should not detect edge-touching rectangles (open boundary)", function()
    local a = { x = 0, y = 0, w = 10, h = 10 }
    local b = { x = 10, y = 0, w = 10, h = 10 }
    assert.is_false(Collision.aabb(a, b))
  end)

  it("should detect contained rectangles", function()
    local a = { x = 0, y = 0, w = 20, h = 20 }
    local b = { x = 5, y = 5, w = 5, h = 5 }
    assert.is_true(Collision.aabb(a, b))
  end)

  it("should handle horizontal-only overlap", function()
    local a = { x = 0, y = 0, w = 10, h = 10 }
    local b = { x = 5, y = 20, w = 10, h = 10 }
    assert.is_false(Collision.aabb(a, b))
  end)

  it("should handle vertical-only overlap", function()
    local a = { x = 0, y = 0, w = 10, h = 10 }
    local b = { x = 20, y = 5, w = 10, h = 10 }
    assert.is_false(Collision.aabb(a, b))
  end)
end)

describe("Collision.point_in_rect", function()
  it("should detect a point inside", function()
    local r = { x = 10, y = 10, w = 20, h = 20 }
    assert.is_true(Collision.point_in_rect(15, 15, r))
  end)

  it("should detect a point on the boundary", function()
    local r = { x = 10, y = 10, w = 20, h = 20 }
    assert.is_true(Collision.point_in_rect(10, 10, r))
    assert.is_true(Collision.point_in_rect(30, 30, r))
  end)

  it("should reject a point outside", function()
    local r = { x = 10, y = 10, w = 20, h = 20 }
    assert.is_false(Collision.point_in_rect(5, 5, r))
    assert.is_false(Collision.point_in_rect(35, 35, r))
  end)
end)
