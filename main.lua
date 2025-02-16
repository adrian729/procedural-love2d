_G.debug = false

local nodes
local node_distance

local chain_test
local fish

function love.load()
  --  _G.debug = true

  Vec2 = require("vec2")

  node_distance = 20
  nodes = {}
  local x0 = 280
  for i = 1, 15, 1 do
    nodes[i] = {}
    nodes[i].pos = { x0 + i * node_distance, 300 }
    nodes[i].rad = node_distance
    nodes[i].dist = node_distance
  end
  for i = 1, 1, 1 do
    nodes[i].rad = 15
  end
  for i = 3, 4, 1 do
    nodes[i].rad = 15
  end
  for i = 10, 15, 1 do
    nodes[i].rad = 75 / i
  end
  for i = 1, #nodes, 1 do
    nodes[i].rad = math.max(node_distance - 1.1 * i, 3)
  end

  Chain = require 'chain'
  chain_test = Chain:new(Vec2:new(200, 200), 12, 64, math.pi / 8)

  Fish = require 'fish'
  fish = Fish:new(Vec2:new(200, 200), 0.4)
end

function love.update(dt)
  local mouse_x, mouse_y = love.mouse.getPosition()
  local angle = getAngle(mouse_x, mouse_y, nodes[1].pos[1], nodes[1].pos[2])
  local dir_x, dir_y = getDirection(angle)

  local speed = 1.4

  nodes[1].pos[1] = nodes[1].pos[1] + speed * dir_x * dt
  nodes[1].pos[2] = nodes[1].pos[2] + speed * dir_y * dt

  for i = 1, #nodes - 1, 1 do
    repositionNodes(nodes[i], nodes[i + 1], nodes[i].dist)
  end

  chain_test:resolve(Vec2:new(mouse_x, mouse_y), dt)
  fish:resolve(Vec2:new(mouse_x, mouse_y), speed * dt)
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  for _, n in ipairs(nodes) do
    local pos = n.pos
    -- love.graphics.circle("line", pos[1], pos[2], n.rad)
  end

  love.graphics.setColor(1, 0, 0)
  -- chain_test:draw()
  love.graphics.setColor(0, 1, 0)
  fish:draw()
end

function getAngle(target_x, target_y, obj_x, obj_y)
  return math.atan2(target_y - obj_y, target_x - obj_x)
end

function getDirection(angle)
  return math.cos(angle), math.sin(angle)
end

function getDistance(p1, p2)
  local len = math.max(#p1, #p2)
  local val = 0
  for i = 1, len, 1 do
    local v1 = p1[i] or 0
    local v2 = p2[i] or 0
    val = val + (v1 - v2) ^ 2
  end

  return math.sqrt(val)
end

function magnitude(v)
  local val = 0
  for i = 1, #v, 1 do
    val = val + v[i] ^ 2
  end

  return math.sqrt(val)
end

function repositionNodes(n1, n2, d)
  local p1 = n1.pos
  local p2 = n2.pos

  -- translate to origin
  for i = 1, #p2, 1 do
    local c1 = p1[i] or 0
    p2[i] = p2[i] - c1
  end

  -- resize to new len
  m = magnitude(p2)
  if m > 0 then
    for i = 1, #p2, 1 do
      p2[i] = (d * p2[i] / m)
    end
  end

  -- translate again to initial coordinates
  for i = 1, #p2, 1 do
    local c1 = p1[i] or 0
    p2[i] = p2[i] + c1
  end

  n2.pos = p2
end
