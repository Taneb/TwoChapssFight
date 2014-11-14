-- make a box for the purpose of checking for overlapping rectangles. this is
-- useful for checking hitboxes, for example.
function mkbox(x, y, width, height)
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

-- make a new fighter. note that this does NOT add the fighter to the fighters
-- table, you'll have to do that yourself!
-- * name is a name for the fighter, eg. "Player 2"
-- * octile is roughly how far across the screen they'll start, in multiples of
--   eighths of the screen
-- * color is what color the fighter should be rendered as. try to choose a
--   color that shows up well against the background!
-- * the remainder of the parameters are controls.
-- this creates a fighter with the following parameters:
-- * name: a name for the fighter, eg. "Player 2"
-- * graphic: their current sprite
-- * height: the fighter's height, in pixels. this is used for the hitbox
-- * width: the fighter's width, in pixels. this is used for the hitbox
-- * t: timeout to prevent the fighter attacking too frequently
-- * health: the fighter's health
-- * x: the fighter's x position
-- * y: the fighter's y position
-- * o: which direction the fighter is facing, -1 is left, 1 is right
-- * xv: the fighter's horizontal velocity
-- * yv: the fighter's vertical velocity
-- * color: the fighter's color. this is used for rendering the character and
--     displaying their health.
-- * side: where their health will be displayed.
-- * leftkey and rightkey: the keys to move the fighter left and right
--     respectively.
-- * alive: whether the fighter is still alive. if they are not alive they will
--     not be rendered and cannot take any action.
-- also, the following methods are defined:
-- * jump(): starts the fighter jumping. this only has effect when the fighter
--     is on the ground.
-- * punch(): makes the fighter punch.
-- * move(): does all the movement for the fighter. this is a huge method and
--     should probably be split up.
-- * draw(): renders the fighter to the screen. this should only be called from
--     love.draw!
-- * damage(amount): reduces the fighter's health by amount, possibly setting
--     their alive status to false.
-- * getBoundingBox: returns the bounding box of the fighter.
function mkfighter(name, octile, color, leftkey, upkey, rightkey, punchkey)
   -- decide from the quartile which way we are facing and where the scores
   -- are displayed
   local o
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

   -- whoa like loads of definitions
   local fighter = 
      {name=name, graphic=fighterstatic, height=43, width=18, t=0, health=100,
       x=octile*love.graphics.getWidth()/8, y=love.graphics.getHeight()/2, o=o,
       xv=0, yv=0, color=color, side=side, leftkey=leftkey, rightkey=rightkey,
       alive=true
      }

   -- methods ahoy!
   function fighter.jump(self)
      -- tells a fighter to jump if it is touching the ground
      if self.y + self.height == 600 then
	 self.yv = self.yv - 500
      end
   end
   function fighter.punch(self)
     if self.t == 0 and self.alive then
	self.graphic = fighterpunch
	self.height = 43
	self.t = 0.1
	local fistBox = mkbox(self.x + 19*self.o, self.y + 14, 7*self.o, 7)
	local function attack(other)
	   if other ~= self and fistBox:overlaps(other:getBoundingBox()) then
	      other:damage(10)
	   end
	end
	overfighters(attack)
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
      return mkbox(self.x, self.y, self.width * self.o, self.height)
   end

   -- register the controls for jump and punch in the keymap.
   -- these functions will be called when the appropriate keys are pressed.
   keymap[upkey] = function () fighter:jump() end
   keymap[punchkey] = function() fighter:punch() end

   return fighter
end

-- map a function over all the fighters.
-- please figure out how for loops work and use that instead
function overfighters(func)
   local i = 1
   local fighter = fighters[i]
   while fighter ~= nil do
      func(fighter)
      i = i+1
      fighter = fighters[i]
   end
end

-- check if the game has ended
--
-- the way this is done is to go through the list of fighters, counting how
-- many are still alive, and remembering the name of one of the alive ones.
-- if there is precisely one fighter still alive, the "winner" global variable
-- is set to their name. if there are precisely zero fighters still alive, the
-- "winner" global variable is set to "Nobody", although this is an exceedingly
-- rare edge case which I have never seen come up. otherwise "winner" is left
-- as nil. "winner" is used by love.draw; if it is nil; it renders the game as
-- usual, if it isn't, it renders a victory screeen. it is also used by
-- love.update to determine if it should still be trying to simulate the game.
function checkifgameended()
   local alivecount = 0
   local alive
   local function count(fighter)
      if fighter.alive then
	 alive = fighter.name
	 alivecount = alivecount + 1
      end
   end
   overfighters(count)
   if alivecount == 1 then
      winner = alive
   elseif alivecount == 0 then
      winner = "Nobody"
   end
end

-- Love2D callbacks ahoy!

-- Love2D calls this function when a key is pressed. this will then lookup the
-- key pressed in the keymap and if it maps to a function, it will call that
-- function. this is used to implement jump and punch controls, implemented in
-- this way so it is easier to add more players, as otherwise this function
-- would have to be edited any time the players or controls are changed.
function love.keypressed(key)
   local func = keymap[key]
   if func ~= nil then
      func()
   end
end

-- this is the function that Love2D calls at startup.
-- what I am doing with it is:
-- * loading sprites. these are currently stored globally, it might be a
--   thought to store them in a table, but i don't know if that gains me that
--   much
-- * set default font, background color, and window size.
-- * define gravity. I think there's a broadway song about doing this.
-- * initialize the keymap used by love.keypressed. keys are later added to
--   this from mkfighter
-- * create the fighters
function love.load()
   -- load sprites
   fighterstatic = love.graphics.newImage("fighterstatic.png")
   fighterpunch  = love.graphics.newImage("fighterpunch.png")

   -- set window information
   love.graphics.setFont(love.graphics.newFont(20))
   love.graphics.setBackgroundColor(200,250,255)
   love.window.setMode(650, 650)

   -- define gravity
   gravity = 1000

   -- keymap is a map from keys to function to call when that key is pressed
   -- this is handled by love.keypressed
   -- this should be defined in a better place!
   keymap = {}

   -- create fighters
   -- if you want to add a fighter, just add one here and everything should
   -- just work.
   fighters = {-- name   position color     controls.......
      mkfighter("Player 1", 1, {255,0,0}, "a", "w", "d", "lshift"),
      mkfighter("Player 2", 7, {0,0,255}, "kp4", "kp8", "kp6", "kpenter"),
   }
end

-- this advances time, calling the movement methods for all the fighters, then
-- checking whehter the game has ended.
-- if the game has already ended, winner will not be nil - it is set by
-- checkifgameended - so the buk of this function will not be ran.
-- I don't know whether that is an optimization I really need to care about but
-- it feels neater.
function love.update(dt)
   if winner == nil then
      overfighters(function(fighter) fighter:move(dt) end)
      checkifgameended()
   end
end

-- this renders the screen. if the game is still ongoing, so the winner global
-- variable is nil, it renders a sort of stage at the bottom of the screen,
-- then calles the draw method on each fighter.
-- when checkifgameended sets the winner global variable to instead the name of
-- the winner - if there is one - a victory screen is displayed.
function love.draw()
   if winner == nil then
      -- render stage
      -- this is just a 50px rectangle at the bottom
      love.graphics.setColor(14, 72, 160)
      love.graphics.rectangle("fill", 0, 600, 650, 50)
      -- render each fighter
      overfighters(function(fighter) fighter:draw() end)
   else
      -- render victory screen
      love.graphics.setColor(0, 0, 0)
      love.graphics.printf(winner .. " wins!", 1*650/8, 300, 6*650/8, "center")
   end
end
