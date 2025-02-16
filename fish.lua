local Chain = require 'chain'
local Splines = require 'splines'

local body_color = { 58 / 255, 124 / 255, 165 / 255 }
local fin_color = { 129 / 255, 195 / 255, 215 / 255 }

local Fish = {}
Fish.__index = Fish

-- TODO add method setScale to update fish scale. Needs to go from spine to spine and recalculate position from prev pos and angle

function Fish:new(origin, scale)
  scale = scale or 1
  local body_width = { 68, 81, 84, 83, 77, 64, 51, 38, 32, 19, 19, 19 }
  for i, w in ipairs(body_width) do
    body_width[i] = scale * w
  end

  local fish = {
    scale = scale,
    spine = Chain:new(origin, 12, scale * 64, math.pi / 8),
    body_width = body_width,
  }

  for k, v in pairs(self) do
    if k:find("_") ~= 1 then
      fish[k] = v
    end
  end

  return setmetatable(fish, Fish)
end

function Fish:resolve(target_pos, dt)
  self.spine:resolve(target_pos, dt)
end

local function getSidePoints(m, pos_1, pos_2)
  local dx = pos_2.x - pos_1.x
  local dy = pos_2.y - pos_1.y

  return Vec2:new(-dy, dx):setMagnitude(m) + pos_1, Vec2:new(dy, -dx):setMagnitude(m) + pos_1
end

local function drawDorsalFin(self)
  local joints = self.spine.joints

  local dorsal_start_idx = 3
  local dorsal_end_idx = 7
  local dorsal_left = {}
  local dorsal_right = {}

  table.insert(dorsal_left, joints[dorsal_start_idx])
  table.insert(dorsal_right, joints[dorsal_start_idx])
  if debug then
    love.graphics.setColor(1, 0, 1)
    love.graphics.circle("fill", joints[dorsal_start_idx].x, joints[dorsal_start_idx].y, 5)
  end

  for i = dorsal_start_idx + 1, dorsal_end_idx - 1, 1 do
    local side_1, side_2 = getSidePoints(0.25 * self.body_width[i], joints[i], joints[i + 1])
    table.insert(dorsal_left, side_1)
    table.insert(dorsal_right, side_2)
    if debug then
      love.graphics.setColor(1, 0, 1)
      love.graphics.circle("fill", side_1.x, side_1.y, 5)
      love.graphics.circle("fill", side_2.x, side_2.y, 5)
    end
  end

  table.insert(dorsal_left, joints[dorsal_end_idx])
  if debug then
    love.graphics.setColor(1, 0, 1)
    love.graphics.circle("fill", joints[dorsal_end_idx].x, joints[dorsal_end_idx].y, 5)
  end

  local dorsal_shape = {}
  for _, p in ipairs(dorsal_left) do
    table.insert(dorsal_shape, p)
  end
  for i = #dorsal_right, 1, -1 do
    table.insert(dorsal_shape, dorsal_right[i])
  end

  love.graphics.setColor(fin_color[1], fin_color[2], fin_color[3])
  local dorsal_splines_curve = Splines:new(dorsal_shape)
  local dorsal_splines_points = dorsal_splines_curve:render({ detail = 200, type = 'v2' })

  local dorsal_curve = {}
  for _, point in ipairs(dorsal_splines_points) do
    table.insert(dorsal_curve, point.x)
    table.insert(dorsal_curve, point.y)
    if debug then
      love.graphics.setColor(1, 0, 1)
      love.graphics.circle("line", point.x, point.y, 6)
    end
  end
  love.graphics.line(dorsal_curve)
end

local function drawEyes(self)
  local joints = self.spine.joints

  local eye_size = 24 * self.scale
  local eye_left, eye_right = getSidePoints(self.body_width[1] - 0.6 * eye_size, joints[1], joints[2])
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.circle("fill", eye_left.x, eye_left.y, eye_size)
  love.graphics.circle("fill", eye_right.x, eye_right.y, eye_size)
  local pupil_size = 18 * self.scale
  local pupil_left, pupil_right = getSidePoints(self.body_width[1] - 0.4 * eye_size, joints[1], joints[2])
  love.graphics.setColor(0.05, 0.05, 0.05)
  love.graphics.circle("fill", pupil_left.x, pupil_left.y, pupil_size)
  love.graphics.circle("fill", pupil_right.x, pupil_right.y, pupil_size)
end

local function drawFins(self)
  local joints = self.spine.joints

  local left = {}
  local right = {}

  -- TODO firx things...
  love.graphics.setColor(1, 0, 1)
  local v = (joints[3] - joints[2])
  -- love.graphics.circle('fill', v.x, v.y, 8)
  -- print(v:magnitude())
  love.graphics.setColor(1, 0, 0)
  -- love.graphics.circle('fill', 300, 300, 8)

  -- TODO: fix, all external points should come only from first point + its angle
  for i = 2, 4, 1 do
    local side_1, side_2 = getSidePoints(self.body_width[i], joints[i], joints[i + 1])
    table.insert(left, side_1)
    table.insert(right, side_2)
  end
  local side_1, side_2 = getSidePoints(1.5 * self.body_width[4], joints[4], joints[5])
  table.insert(left, side_1)
  table.insert(right, side_2)
  side_1, side_2 = getSidePoints(1.8 * self.body_width[3], joints[3], joints[4])
  table.insert(left, side_1)
  table.insert(right, side_2)
  side_1, side_2 = getSidePoints(self.body_width[2], joints[2], joints[3])
  table.insert(left, side_1)
  table.insert(right, side_2)

  local curve_left = {}
  local curve_right = {}
  for _, p in ipairs(left) do
    table.insert(curve_left, p.x)
    table.insert(curve_left, p.y)
  end
  for _, p in ipairs(right) do
    table.insert(curve_right, p.x)
    table.insert(curve_right, p.y)
  end

  love.graphics.setColor(fin_color[1], fin_color[2], fin_color[3])
  local l_splines = Splines:new(curve_left)
  local l_splines_points = l_splines:render({ detail = 1000 })
  love.graphics.line(l_splines_points)
  local r_splines = Splines:new(curve_right)
  local r_splines_points = r_splines:render({ detail = 1000 })
  love.graphics.line(r_splines_points)

  if debug then
    for _, p in ipairs(left) do
      love.graphics.setColor(1, 0, 0)
      love.graphics.circle("fill", p.x, p.y, 5)
    end
    for _, p in ipairs(right) do
      love.graphics.setColor(1, 0, 0)
      love.graphics.circle("fill", p.x, p.y, 5)
    end
    for i = 2, #curve_left, 2 do
      love.graphics.setColor(1, 1, 0)
      love.graphics.circle("line", curve_left[i - 1], curve_left[i], 5)
    end
    for i = 2, #curve_right, 2 do
      love.graphics.setColor(1, 1, 0)
      love.graphics.circle("line", curve_right[i - 1], curve_right[i], 5)
    end
  end
end

local function drawTail(self)
  local joints = self.spine.joints

  local left = {}
  local right = {}

  local side_1, side_2 = getSidePoints(0.8 * self.body_width[#joints - 2], joints[#joints - 2], joints[#joints - 1])
  table.insert(left, side_1)
  table.insert(right, side_2)
  if debug then
    love.graphics.setColor(0, 0, 1)
    love.graphics.circle("fill", side_1.x, side_1.y, 5)
    love.graphics.circle("fill", side_2.x, side_2.y, 5)
  end

  local tail_2, tail_1 = getSidePoints(1.4 * self.body_width[#joints], joints[#joints], joints[#joints - 1])
  table.insert(left, tail_1)
  table.insert(right, tail_2)
  if debug then
    love.graphics.setColor(0, 0, 1)
    love.graphics.circle("fill", tail_1.x, tail_1.y, 5)
    love.graphics.circle("fill", tail_2.x, tail_2.y, 5)
  end

  local tail_end = (joints[#joints] - joints[#joints - 1])
  tail_end = tail_end:setMagnitude(self.body_width[#joints] + self.spine.link_size)
  tail_end = tail_end + joints[#joints - 1]
  if debug then
    love.graphics.setColor(0, 0, 1)
    love.graphics.circle("fill", tail_end.x, tail_end.y, 5)
  end
  table.insert(left, tail_end)
  -- Comment/uncomment depending on if we want repeated end point or not
  -- table.insert(right, tail_end)

  local shape = {}
  for _, v in ipairs(left) do
    table.insert(shape, v)
  end
  for i = #right, 1, -1 do
    table.insert(shape, right[i])
  end

  love.graphics.setColor(fin_color[1], fin_color[2], fin_color[3])

  local splines_curve = Splines:new(shape)
  local splines_points = splines_curve:render({ detail = 1000, type = 'v2' })

  local curve = {}
  for _, point in ipairs(splines_points) do
    table.insert(curve, point.x)
    table.insert(curve, point.y)
    if debug then
      love.graphics.setColor(1, 1, 0)
      love.graphics.circle("line", point.x, point.y, 6)
    end
  end

  love.graphics.line(curve)
end

local function drawBody(self)
  local joints = self.spine.joints

  if debug then
    love.graphics.setColor(0, 1, 0)
    for i, joint in ipairs(joints) do
      love.graphics.ellipse("line", joint.x, joint.y, self.body_width[i], self.body_width[i])
    end
  end

  local left = {}
  local right = {}
  local front = (joints[1] - joints[2])
  front = front:setMagnitude(self.body_width[1] + self.spine.link_size) + joints[2]
  table.insert(left, front)
  -- Comment/uncomment depending on if we want repeated front point or not
  table.insert(right, front)
  local front_left = Vec2:fromAngle(self.spine.angles[2] - math.pi / 8)
  front_left = front_left:setMagnitude(self.body_width[1])
  front_left = front_left + joints[1]
  table.insert(left, front_left)
  local front_left_2 = Vec2:fromAngle(self.spine.angles[2] - math.pi / 4)
  front_left_2 = front_left_2:setMagnitude(self.body_width[1])
  front_left_2 = front_left_2 + joints[1]
  table.insert(left, front_left_2)
  local front_right = Vec2:fromAngle(self.spine.angles[2] + math.pi / 8)
  front_right = front_right:setMagnitude(self.body_width[1])
  front_right = front_right + joints[1]
  table.insert(right, front_right)
  local front_right_2 = Vec2:fromAngle(self.spine.angles[2] + math.pi / 4)
  front_right_2 = front_right_2:setMagnitude(self.body_width[1])
  front_right_2 = front_right_2 + joints[1]
  table.insert(right, front_right_2)
  if debug then
    love.graphics.setColor(0, 0, 1)
    love.graphics.circle("fill", front.x, front.y, 5)
    love.graphics.circle("fill", front_left.x, front_left.y, 5)
    love.graphics.circle("fill", front_left_2.x, front_left_2.y, 5)
    love.graphics.circle("fill", front_right.x, front_right.y, 5)
    love.graphics.circle("fill", front_right_2.x, front_right_2.y, 5)
  end

  for i = 1, #joints - 2, 1 do
    local side_1, side_2 = getSidePoints(self.body_width[i], joints[i], joints[i + 1])
    table.insert(left, side_1)
    table.insert(right, side_2)
    if debug then
      love.graphics.setColor(0, 0, 1)
      love.graphics.circle("fill", side_1.x, side_1.y, 5)
      love.graphics.circle("fill", side_2.x, side_2.y, 5)
    end
  end

  local shape = {}
  for _, v in ipairs(left) do
    table.insert(shape, v)
  end
  for i = #right, 1, -1 do
    table.insert(shape, right[i])
  end


  love.graphics.setColor(body_color[1], body_color[2], body_color[3])
  -- local bezier_points = love.math.newBezierCurve(curve):render()

  local splines_curve = Splines:new(shape)
  local splines_points = splines_curve:render({ detail = 1000, type = 'v2' })

  -- For some reason triangulate explodes sometimes...
  -- local triangles = love.math.triangulate(bezier_points)
  -- With curve it works if we remove the repeated front anf tail_end, but looks to rough. could be an option if added middle points and smoothing.
  -- local triangles = love.math.triangulate(curve)
  -- local triangles = love.math.triangulate(splines_points)
  local triangles = {}
  for _, triangle in ipairs(triangles) do
    love.graphics.polygon("fill", triangle)
  end

  local curve = {}
  for _, point in ipairs(splines_points) do
    table.insert(curve, point.x)
    table.insert(curve, point.y)
    if debug then
      love.graphics.setColor(1, 1, 0)
      love.graphics.circle("line", point.x, point.y, 6)
    end
  end
  -- love.graphics.line(bezier_points)
  love.graphics.line(curve)

  --[[
  -- This calculates separate left and right sides. It follows better the shape, but is a bit more pointy.
  -- For the fish it may look better with the bezier of a single shape
  local curve_left = {}
  for _, point in ipairs(left) do
    table.insert(curve_left, point.x)
    table.insert(curve_left, point.y)
    if debug then
      love.graphics.setColor(1, 0, 0)
      love.graphics.circle("line", point.x, point.y, 6)
    end
  end
  local curve_right = {}
  for _, point in ipairs(right) do
    table.insert(curve_right, point.x)
    table.insert(curve_right, point.y)
    if debug then
      love.graphics.setColor(1, 0, 0)
      love.graphics.circle("line", point.x, point.y, 6)
    end
  end
  local bezier_points_left = love.math.newBezierCurve(curve_left):render()
  local bezier_points_right = love.math.newBezierCurve(curve_right):render()
  love.graphics.line(bezier_points_left)
  love.graphics.line(bezier_points_right)
  --]]
end

function Fish:draw()
  drawBody(self)
  drawDorsalFin(self)
  drawEyes(self)
  -- drawFins(self)
  drawTail(self)

  local joints = self.spine.joints
  local side_1, side_2 = getSidePoints(self.body_width[3], joints[3], joints[4])
  love.graphics.translate(side_1.x, side_1.y)
  love.graphics.rotate(self.spine.angles[3] + math.pi / 3)
  love.graphics.ellipse("line", 0, 0, 30, 15)
  love.graphics.rotate(-self.spine.angles[3] - math.pi / 3)
  love.graphics.translate(-side_1.x, -side_1.y)
  love.graphics.translate(side_2.x, side_2.y)
  love.graphics.rotate(self.spine.angles[3] - math.pi / 3)
  love.graphics.ellipse("line", 0, 0, 30, 15)
  love.graphics.rotate(-self.spine.angles[3] + math.pi / 3)
  love.graphics.translate(-side_2.x, -side_2.y)
end

return Fish
