-- Base code and idea was taken from https://github.com/argonautcode/animal-proc-anim
local Vec2 = require 'vec2'

local Chain = {}
Chain.__index = Chain

function Chain:new(origin, joint_count, link_size, angle_constraint)
  local chain = {
    speed = 200,
    link_size = link_size,                                -- Space between joints
    angle_constraint = angle_constraint or (2 * math.pi), -- Max angle diff between two adjacent joints, higher = loose, lower = rigid
    joints = { origin },                                  -- List of joint positions as Vec2. #joins > 1, if not it can't be a chain...
    angles = { 0.0 },
  }

  for k, v in pairs(self) do
    if k:find("__") ~= 1 then
      chain[k] = v
    end
  end

  for i = 2, joint_count, 1 do
    table.insert(chain.joints, chain.joints[i - 1] + Vec2:new(0, link_size))
    table.insert(chain.angles, 0.0)
  end

  return setmetatable(chain, self)
end

function Chain:__tostring()
  local chain_str = '['
  for i, joint in ipairs(self.joints) do
    chain_str = chain_str .. tostring(joint) .. '_' .. self.angles[i]
  end
  return chain_str .. ']'
end

local function simplifyAngle(angle)
  -- Simplify the angle to be in the range [0, 2pi)

  local two_pi = 2 * math.pi

  while angle >= two_pi do
    angle = angle - two_pi
  end

  while angle < 0 do
    angle = angle + two_pi
  end

  return angle
end

local function relativeAngleDiff(angle, anchor)
  -- i.e. How many radians do you need to turn the angle to match the anchor?

  -- Since angles are represented by values in [0, 2pi), it's helpful to rotate
  -- the coordinate space such that PI is at the anchor. That way we don't have
  -- to worry about the "seam" between 0 and 2pi.
  return math.pi - simplifyAngle(angle + math.pi - anchor)
end
Chain.relativeAngleDiff = relativeAngleDiff

local function constrainAngle(angle, anchor, constraint)
  -- Constrain the angle to be within a certain range of the anchor

  local relative_diff = relativeAngleDiff(angle, anchor)

  if math.abs(relative_diff) <= constraint then
    return simplifyAngle(angle)
  end

  if relative_diff > constraint then
    return simplifyAngle(anchor - constraint)
  end

  return simplifyAngle(anchor + constraint)
end
Chain.constrainAngle = constrainAngle

local function constrainDistance(pos, anchor, constraint)
  -- Constrain the vector to be at a certain range of the anchor

  return anchor + (pos - anchor):setMagnitude(constraint)
end
Chain.constrainDistance = constrainDistance

local function deltaTarget(target, origin, mag)
  return (target - origin):setMagnitude(mag) + origin
end
Chain.deltaTarget = deltaTarget

function Chain:resolve(pos, dt)
  -- TODO smooth movement if rotation angle is to big

  if self.joints[1]:distance(pos) < 1 then
    return
  end

  local target = deltaTarget(pos, self.joints[1], self.speed * dt)
  self.angles[1] = (target - self.joints[1]):angle()
  self.joints[1] = target

  for i = 2, #self.joints, 1 do
    local curr_angle = (self.joints[i - 1] - self.joints[i]):angle()
    self.angles[i] = constrainAngle(curr_angle, self.angles[i - 1], self.angle_constraint)
    self.joints[i] = self.joints[i - 1] - Vec2:fromAngle(self.angles[i]):setMagnitude(self.link_size)
  end
end

function Chain:fabrikResolve(pos, anchor)
  -- Forward pass
  self.joints[1] = pos
  for i = 2, #self.joints, 1 do
    self.joints[i] = constrainDistance(self.joints[i], self.joints[i - 1], self.link_size)
  end
  -- Backward pass
  self.joints[#self.joints] = anchor
  for i = #self.joints - 1, 1, -1 do
    self.joints[i] = constrainDistance(self.joints[i], self.joints[i + 1], self.link_size)
  end
end

function Chain:draw()
  for i = 1, #self.joints - 1, 1 do
    local start_joint = self.joints[i]
    local end_joint = self.joints[i + 1]
    love.graphics.line(start_joint.x, start_joint.y, end_joint.x, end_joint.y)
  end

  for _, joint in ipairs(self.joints) do
    love.graphics.ellipse("line", joint.x, joint.y, 32, 32)
  end
end

return Chain
