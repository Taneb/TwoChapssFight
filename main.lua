local Box = require "box"
local Fighter = require "fighter"

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
   for _,fighter in pairs(fighters) do
      if fighter.alive then
	 alive = fighter.name
	 alivecount = alivecount + 1
      end
   end
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
   fighters = {}-- name   position color     controls.......
   Fighter.new("Player 1", 1, {255,0,0}, "a", "w", "d", "lshift", fighters, keymap)
   Fighter.new("Player 2", 7, {0,0,255}, "kp4", "kp8", "kp6", "kpenter", fighters, keymap)
end

-- this advances time, calling the movement methods for all the fighters, then
-- checking whehter the game has ended.
-- if the game has already ended, winner will not be nil - it is set by
-- checkifgameended - so the buk of this function will not be ran.
-- I don't know whether that is an optimization I really need to care about but
-- it feels neater.
function love.update(dt)
   if winner == nil then
      for _,fighter in pairs(fighters) do
	 fighter:update(dt)
      end
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
      for _,fighter in pairs(fighters) do
	 fighter:draw()
      end
--      overfighters(function(fighter) fighter:draw() end)
   else
      -- render victory screen
      love.graphics.setColor(0, 0, 0)
      love.graphics.printf(winner .. " wins!", 1*650/8, 300, 6*650/8, "center")
   end
end
