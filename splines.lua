-- Catmull-Rom splines
-- lua v5.1^
local Vec2 = require 'vec2'

local Splines = {}

function Splines:new(points)
  return setmetatable(
    {
      points = points, -- points as vec2 array
      render_type = 'catmull-rom',
    },
    self
  )
end

function Splines:__index(key)
  if key == nil then
    return Splines
  end

  if type(key) ~= 'string' then
    return
  end

  return Splines[key]
end

function Splines:__tostring()
  -- TODO
  return 'Splines'
end

function Splines:render(props)
  -- Render splines
  -- props: type, detail, alpha, tension
  -- detail
  -- alpha: if val in [0, 1] 0->uniform, 0.5->centripetal, 1->chordal; otherwise, custom impl
  -- tension, from 0 to 1 => how tight, 0 more curve, 1 straight lines from point to point. t = 0 is good for centripetal
  props = props or {}
  self.render_type = props.type or self.render_type
  if #self.points < 4 then
    self.rendered_points = self.points
    return self.points
  end

  local detail = props.detail or 5
  if self.render_type == 'catmull-rom' then
    return self:renderCatmullRom(detail, props.alpha, props.tension)
  else
    return self:renderV2(detail)
  end
end

function Splines:renderCatmullRom(detail, alpha, tension)
  local points = self.points
  self.rendered_points = {}

  table.insert(self.rendered_points, points[1])
  for i = 2, #points - 3, 1 do
    local s = self.segmentCoefficients(
      points[i - 1], points[i], points[i + 1], points[i + 2],
      alpha, tension
    )
    -- Calc each detail point in [0, d), d not included since it will be the start of the next segment
    for j = 0, detail - 1, 1 do
      local t = j / detail
      table.insert(self.rendered_points, self.renderPoint(s.a, s.b, s.c, s.d, t))
    end
  end
  table.insert(self.rendered_points, points[#self.points])

  return self.rendered_points
end

function Splines.segmentCoefficients(p0, p1, p2, p3, alpha, tension)
  -- calculates the coefficients to interpolate points in segment p1-p2
  -- p0 .. p3 points to calc p1 to p2 segment
  -- alpha, from 0 to 1 => 0 uniform Catmull-Rom spline, 0.5 centripetal variant, 1 chordal variant
  -- tension, from 0 to 1 => how tight, 0 more curve, 1 straight lines from point to point. t = 0 is good for centripetal

  alpha = alpha or 0.5
  tension = tension or 0

  local t01 = p0:distance(p1) ^ alpha
  local t12 = p1:distance(p2) ^ alpha
  local t23 = p2:distance(p3) ^ alpha

  local m1 = (1.0 - tension) * (p2 - p1 + t12 * ((p1 - p0) / t01) - (p2 - p0) / (t01 + t12))
  local m2 = (1.0 - tension) * ((p3 - p2) / t23 - (p3 - p1) / (t12 + t23))

  -- a,b,c,d points/coefficients to interpolate the points in the segment p1 to p2
  return {
    a = 2 * p1 - 2 * p2 + m1 + m2,
    b = -3 * p1 + 3 * p2 - 2 * m1 - m2,
    c = m1,
    d = p1
  }
end

function Splines.renderPoint(a, b, c, d, t)
  -- a,b,c,d points/coefficients to interpolate the points in the segment
  -- t from 0 to 1. Value 0 start of the segment, 1 end of the segment.
  return a * t ^ 3 + b * t ^ 2 + c * t + d
end

function Splines:renderV2(detail)
  -- impl using algorithm at https://www.love2d.org/forums/viewtopic.php?t=1401
  local points = self.points
  self.rendered_points = {}

  for i = 1, #points - 1, 1 do
    local p0 = points[i - 1]
    local p1 = points[i]
    local p2 = points[i + 1]
    local p3 = points[i + 2]

    -- Calculate the colinearity and control points for the section:
    local t1 = Vec2:new()
    local colin_1 = nil
    if p0 then
      t1 = 0.5 * (p2 - p0)
      colin_1 = self.getColinearity(p0, p1, p2)
    end

    local t2 = Vec2:new()
    local colin_2 = nil
    if p3 then
      t2 = 0.5 * (p3 - p1)
      colin_2 = self.getColinearity(p1, p2, p3)
    end

    local colinearity = colin_1 or colin_2 or 0
    if colin_1 and colin_2 then
      colinearity = (colin_1 + colin_2) / 2
    end

    -- Get the proper detail using the computed colinearity, then calculate the spline points:
    local rdetail = (detail * (1 - colinearity))
    for j = 0, rdetail, 1 do
      local s = j / rdetail
      local s2 = s * s
      local s3 = s2 * s
      local h1 = 2 * s3 - 3 * s2 + 1
      local h2 = -2 * s3 + 3 * s2
      local h3 = s3 - 2 * s2 + s
      local h4 = s3 - s2
      table.insert(
        self.rendered_points,
        Vec2:new(
          (h1 * p1.x) + (h2 * p2.x) + (h3 * t1.x) + (h4 * t2.x),
          (h1 * p1.y) + (h2 * p2.y) + (h3 * t1.y) + (h4 * t2.y)
        )
      )
    end

    if math.ceil(rdetail) > rdetail then
      table.insert(self.rendered_points, p2)
    end
  end

  return self.rendered_points
end

function Splines.getColinearity(p1, p2, p3)
  local ux = p2.x - p1.x
  local uy = p2.y - p1.y
  local vx = p3.x - p2.x
  local vy = p3.y - p2.y
  local udv = (ux * vx + uy * vy)
  local udu = (ux * ux + uy * uy)
  local vdv = (vx * vx + vy * vy)

  if udv < 0 then --the angle is greater than 90 degrees.
    return 0
  end

  local scalar = 1 -- TODO: check if this parameter is needed and how changing it affects oputput or remove
  return scalar * udv ^ 2 / (udu * vdv)
end

return Splines
