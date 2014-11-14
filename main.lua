function mkBoundingBox(x, y, width, height)
   if width < 0 then
      x = x + width
      width = - width
   end
   if height < 0 then
      y = y + height
      height = - height
   end
   local box = {x=x, y=y, width=width, height=height}
   function box.overlaps(self, other)
      if self.x > other.x + other.width or self.x + self.width < other.x then
	 return false
      end
      if self.y > other.y + other.height or self.y + self.height < other.y then
	 return false
      end
      return true
   end
   return box
end

function mkfighter(name, octile, color, leftkey, upkey, rightkey, punchkey)
   local o = nil
   if octile < 3 then
      o = 1
      side = "left"
   elseif octile > 5 then
      o = -1
      side = "right"
   else
      o = math.random(0, 1) * 2 - 1
      side = "center"
   end
   local fighter = 
      {name=name, graphic=fighterstatic, height=43, width=18, t=0, health=100,
       x=octile*love.graphics.getWidth()/8, y=love.graphics.getHeight()/2, o=o,
       xv=0, yv=0, color=color, side=side, leftkey=leftkey, rightkey=rightkey,
       alive=true
      }
   function fighter.jump(self)
      -- tells a fighter to jump if it is touching the ground
      if self.y + self.height == 600 then
	 self.yv = self.yv - 500
      end
   end
   function fighter.punch(self)
     if self.t == 0 then
	self.graphic = fighterpunch
	self.height = 43
	self.t = 0.1
	local fistBox = mkBoundingBox(self.x + 19*self.o, self.y + 14, 7*self.o, 7)
	local attackFunc = function(other)
	   if other ~= self and fistBox:overlaps(other:getBoundingBox()) then
	      other:damage(10)
	   end
	end
	overfighters(attackFunc)
     end
   end
   -- fighter.move is a little do-everything-y.
   -- split it up?
   function fighter.move(self, dt)
   -- deal with horizontal movement
      if love.keyboard.isDown(self.leftkey) 
      and not love.keyboard.isDown(self.rightkey) then
	 self.xv = -400
	 self.o = -1
      elseif love.keyboard.isDown(self.rightkey) 
      and not love.keyboard.isDown(self.leftkey) then
	 self.xv = 400
	 self.o = 1
      end
      -- turn velocities into movement
      self.x = self.x + self.xv * dt
      self.y = math.min(self.y + self.yv * dt, 600 - self.height)
      -- deal with gravity
      if self.y + self.height == 600 then
	 self.yv = 0
      else
	 self.yv = self.yv + gravity * dt
      end
      --deal with friction
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
      
      self.t = self.t - dt
      
      if self.t <= 0 then
	 self.graphic = fighterstatic
	 self.height = 43
	 self.t = 0
      end
   end
   function fighter.draw(self)
      love.graphics.setColor(self.color)
      if self.alive then
	 love.graphics.draw(self.graphic, self.x, self.y, 0, self.o, 1)
      end
	 love.graphics.printf(self.health, 1*650/8, 100, 6*650/8, self.side)
   end
   function fighter.damage(self, damage)
      if self.health > damage then
	 self.health = self.health - damage
      else
	 self.health = 0
	 self.alive = false
      end
   end
   function fighter.getBoundingBox(self)
      return mkBoundingBox(self.x, self.y, self.width * self.o, self.height)
   end

   keymap[upkey] = function () fighter:jump() end
   keymap[punchkey] = function() fighter:punch() end

   return fighter
end

function overfighters(func)
   local i = 1
   local fighter = fighters[i]
   while fighter ~= nil do
      func(fighter)
      i = i+1
      fighter = fighters[i]
   end
end

function love.keypressed(key)
   local func = keymap[key]
   if func ~= nil then
      func()
   end
end

function checkgameover()
   local alivecount = 0
   local alive
   local countFunc = function(fighter)
      if fighter.health > 0 then
	 alive = fighter.name
	 alivecount = alivecount + 1
      end
   end
   overfighters(countFunc)
   if alivecount <= 1 then
      winner = alive
   end
end

function love.load()
   fighterstatic = love.graphics.newImage("fighterstatic.png")
   fighterpunch  = love.graphics.newImage("fighterpunch.png")
   love.graphics.setFont(love.graphics.newFont(20))
   love.graphics.setColor(0,0,0)
   love.graphics.setBackgroundColor(200,250,255)
   love.window.setMode(650, 650)
   gravity = 1000

   -- keymap is a map from keys to function to call when that key is pressed
   -- this is handled by love.keypressed
   -- this should be defined in a better place!
   keymap = {}

   -- create fighters
   fighters = {
      mkfighter("Player 1", 1, {255,0,0}, "a", "w", "d", "lshift"),
      mkfighter("Player 2", 7, {0,0,255}, "kp4", "kp8", "kp6", "kpenter"),
   }
end

function love.update(dt)
   if winner == nil then
      overfighters(function(fighter) fighter:move(dt) end)
      checkgameover()
   end
end

function love.draw()
   if winner == nil then
      love.graphics.setColor(14, 72, 160)
      love.graphics.rectangle("fill", 0, 600, 650, 50)
      overfighters(function(fighter) fighter:draw() end)
   else
      love.graphics.setColor(0, 0, 0)
      love.graphics.printf(winner .. " wins!", 1*650/8, 300, 6*650/8, "center")
   end
end
