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

function mkfighter(octile, color)
   local o = nil
   if octile < 4 then
      o = 1
      side = "left"
   else
      o = -1
      side = "right"
   end
   local fighter = 
      {graphic=fighterstatic, height=43, width=18, t=0, health=100,
       x=octile*love.graphics.getWidth()/8, y=love.graphics.getHeight()/2, o=o,
       xv=0, yv=0, color=color, side=side
      }
   function fighter.jump(self)
      -- tells a fighter to jump if it is touching the ground
      if self.y + self.height == 600 then
	 self.yv = self.yv - 500
      end
   end
   function fighter.punch(self, other)
     if self.t == 0 then
	self.graphic = fighterpunch
	self.height = 43
	self.t = 0.1
	fistBox = mkBoundingBox(self.x + 19*self.o, self.y + 14, 7*self.o, 7)
	if fistBox:overlaps(other:getBoundingBox()) then
	   other.health = other.health - 10
	end
     end
   end
   -- fighter.move is a little do-everything-y.
   -- split it up?
   function fighter.move(self, dt, r, l)
   -- deal with horizontal movement
      if love.keyboard.isDown(l) and not love.keyboard.isDown(r) then
	 self.xv = -400
	 self.o = -1
      elseif love.keyboard.isDown(r) and not love.keyboard.isDown(l) then
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
      love.graphics.draw(self.graphic, self.x, self.y, 0, self.o, 1)
      love.graphics.printf(self.health, 1*650/8, 100, 6*650/8, self.side)
   end
   function fighter.getBoundingBox(self)
      return mkBoundingBox(self.x, self.y, self.width * self.o, self.height)
   end
   return fighter
end

function rectintersect(x1, y1, w1, h1, x2, y2, w2, h2)
   if w1 < 0 then
      x1 = x1 + w1
      w1 = - w1
   end
   if h1 < 0 then
      y1 = y1 + h1
      h1 = - h1
   end
   if w2 < 0 then
      x2 = x2 + w2
      w2 = - w2
   end
   if h2 < 0 then
      y2 = y2 + h2
      h2 = - h2
   end
   if x1 > x2 + w2 or x1 + w1 < x2 then
      return false
   elseif y1 > y2 + h2 or y1 + h1 < y2 then
      return false
   else
      return true
   end
end

function love.keypressed(key)
   -- player1
   if key == "w" then -- jump
      fighter1:jump()
   elseif key == "lshift" or key == " " then
      fighter1:punch(fighter2)
   -- player2
   elseif key == "kp8" then
      fighter2:jump()
   elseif key == "kp+" or key == "kp0" then
      fighter2:punch(fighter1)
   end
end

function checkgameover()
   if fighter1.health <= 0 then
      gameover = "Player 2"
   elseif fighter2.health <= 0 then
      gameover = "Player 1"
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

   -- create first fighter
   fighter1 = mkfighter(1, {255,0,0})

   -- create second fighter
   fighter2 = mkfighter(7, {0,0,255})
end

function love.update(dt)
   if gameover == nil then
      fighter1:move(dt, "d", "a")
      fighter2:move(dt, "kp6", "kp4")
      checkgameover()
   end
end

function love.draw()
   if gameover == nil then
      love.graphics.setColor(14, 72, 160)
      love.graphics.rectangle("fill", 0, 600, 650, 50)
      fighter1:draw()
      fighter2:draw()
   else
      love.graphics.setColor(0, 0, 0)
      love.graphics.printf(gameover.." wins!", 1*650/8, 300, 6*650/8, "center")
   end
end
