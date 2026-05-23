--- AABB collision helpers.
-- All game entities use axis-aligned bounding boxes: {x, y, w, h}.

local Collision = {}

--- Check if two AABB rectangles overlap.
-- Each rect is a table with fields x, y, w, h.
-- @return boolean
function Collision.aabb(a, b)
  return a.x < b.x + b.w
     and a.x + a.w > b.x
     and a.y < b.y + b.h
     and a.y + a.h > b.y
end

--- Check if a point (px, py) is inside a rect {x, y, w, h}.
-- @return boolean
function Collision.point_in_rect(px, py, r)
  return px >= r.x and px <= r.x + r.w
     and py >= r.y and py <= r.y + r.h
end

return Collision
