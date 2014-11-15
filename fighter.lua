local Sprite = require "sprites"
local Box = require "box"

local Fighter = {}
Fighter.__index = Fighter

function Fighter.new(name, octile, color, leftkey, upkey, rightkey, punchkey,
		     fightertable, keymap)
   local self = setmetatable({}, Fighter)
   local o
   local side
   if octile < 3 then
      o = 1
      side = "left"
   elseif octile > 5 then
      o = -1
      side = "right"
   else
      o = math.random(0,1) * 2 - 1 -- either -1 or 1, randomly
      side = "center"
   end

   self.name = name
   self.graphic=Sprite.static
   self.height = 43
   self.width = 18
   self.t = 0
   self.health = 100
   self.x = octile*love.graphics.getWidth()/8
   self.y = love.graphics.getHeight()/2
   self.o = o
   self.xv = 0
   self.yv = 0
   self.color = color
   self.side = side
   self.leftkey = leftkey
   self.rightkey = rightkey
   self.alive = true
   self.fighters = fightertable

   table.insert(fightertable, self)

   keymap[upkey] = function() self:jump() end
   keymap[punchkey] = function() self:punch() end

   return self
end

function Fighter:jump()
   if self.y + self.height == 600 then
      self.yv = self.yv - 500
   end
end

function Fighter:punch()
   -- can only punch if alive and not cooling down
   if self.t == 0 and self.alive then
      self.graphic = Sprite.punch
      self.height = 43
      self.t = 0.1
      local fistBox = Box.new(self.x + 19*self.o, self.y + 14, 7*self.o, 7)
      for _,other in pairs(fighters) do
	 if other ~= self and fistBox:overlaps(other:getBoundingBox()) then
	    other:damage(10)
	 end
      end
   end
end

-- it has been suggested that I move this into keypress stuff
function Fighter:calculateHorizontalVelocityFromKeyboard()
   if love.keyboard.isDown(self.leftkey) 
   and not love.keyboard.isDown(self.rightkey) then
      self.xv = -400
      self.o  = -1
   elseif love.keyboard.isDown(self.rightkey)
   and not love.keyboard.isDown(self.leftkey) then
      self.xv =  400
      self.o  =  1
   end
end

function Fighter:adjustPositionsAccordingToVelocity(dt)
   self.x = self.x + self.xv*dt
   self.y = math.min(self.y + self.yv*dt, 600 - self.height)
end

function Fighter:adjustVerticalVelocityAccordingToGravity(dt)
   if self.y + self.height == 600 then
      self.yv = 0
   else
      self.yv = self.yv + gravity*dt
   end
end

function Fighter:dealWithFriction(dt)
   if self.y + self.height == 600 then
      friction = 5000
   else
      friction = 100
   end

   if math.abs(self.xv) > 1 then
      friction = friction * dt * math.abs(self.xv)/self.xv
      if math.abs(friction) > math.abs(self.xv) then
	 self.xv = 0
      else
	 self.xv = self.xv - friction
      end
   else
      self.xv = 0
   end
end

function Fighter:advanceCooldown(dt)
   self.t = self.t - dt

   if self.t <= 0 then
      self.graphic = Sprite.static
      self.height = 43
      self.t = 0
   end
end

function Fighter:update(dt)
   self:calculateHorizontalVelocityFromKeyboard()

   self:adjustPositionsAccordingToVelocity(dt)

   self:adjustVerticalVelocityAccordingToGravity(dt)

   self:dealWithFriction(dt)

   self:advanceCooldown(dt)
end

function Fighter:draw()
   love.graphics.setColor(self.color)
   love.graphics.printf(self.health, 1*650/8, 100, 6*650/8, self.side)
   if self.alive then
      love.graphics.draw(self.graphic, self.x, self.y, 0, self.o, 1)
   end
end

function Fighter:damage(damage)
   if self.health > damage then
      self.health = self.health - damage
   else
      self.health = 0
      self.alive = false
   end
end

function Fighter:getBoundingBox()
   return Box.new(self.x, self.y, self.width * self.o, self.height)
end

return Fighter
