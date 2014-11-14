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
      jumpfighter(objects.fighter1)
   elseif key == "lshift" or key == " " then
      punchfighter(objects.fighter1, objects.fighter2)
   -- player2
   elseif key == "kp8" then
      jumpfighter(objects.fighter2)
   elseif key == "kp+" or key == "kp0" then
      punchfighter(objects.fighter2, objects.fighter1)
   end
end

function jumpfighter(fighter)
   -- tells a fighter to jump if it is touching the ground
   if fighter.y + fighter.height == 600 then
      fighter.yv = fighter.yv - 500
   end
end

function punchfighter(fighter, otherfighter)
   if fighter.t == 0 then
      fighter.graphic = fighterpunch
      fighter.height = 43
      fighter.t = 0.1
      if rectintersect(fighter.x + 19*fighter.o, fighter.y + 14, 7*fighter.o, 7, otherfighter.x, otherfighter.y, otherfighter.width*otherfighter.o, otherfighter.height) then
	 otherfighter.health = otherfighter.health - 10
      end
   end
end

function movefighter(fighter, dt, r, l)
   -- deal with horizontal movement
   if love.keyboard.isDown(l) and not love.keyboard.isDown(r) then
      fighter.xv = -400
      fighter.o = -1
   elseif love.keyboard.isDown(r) and not love.keyboard.isDown(l) then
      fighter.xv = 400
      fighter.o = 1
   end
   -- turn velocities into movement
   fighter.x = fighter.x + fighter.xv * dt
   fighter.y = math.min(fighter.y + fighter.yv * dt, 600 - fighter.height)
   -- deal with gravity
   if fighter.y + fighter.height == 600 then
      fighter.yv = 0
   else
      fighter.yv = fighter.yv + gravity * dt
   end
   --deal with friction
   if fighter.y + fighter.height == 600 then
      friction = 5000
   else
      friction = 100
   end
   if math.abs(fighter.xv) > 1 then
      friction = friction * dt * math.abs(fighter.xv)/fighter.xv
      if math.abs(friction) > math.abs(fighter.xv) then
	 fighter.xv = 0
      else
	 fighter.xv = fighter.xv - friction
      end
   else
      fighter.xv = 0
   end

   fighter.t = fighter.t - dt

   if fighter.t <= 0 then
      fighter.graphic = fighterstatic
      fighter.height = 43
      fighter.t = 0
   end
end   

function checkgameover()
   if objects.fighter1.health <= 0 then
      gameover = "Player 2"
   elseif objects.fighter2.health <= 0 then
      gameover = "Player 1"
   end
end

function love.load()
   fighterstatic = love.graphics.newImage("fighterstatic.png")
   fighterpunch  = love.graphics.newImage("fighterpunch.png")
   love.graphics.setFont(love.graphics.newFont(20))
   love.graphics.setColor(0,0,0)
   love.graphics.setBackgroundColor(255,127,127)
   love.window.setMode(650, 650)
   gravity = 1000

   objects = {}

   -- create first fighter
   objects.fighter1 = {x=1*650/8, y=650/2, xv=0, yv=0, o=1, graphic=fighterstatic, height=43, width=18, t=0, health=100}

   -- create second fighter
   objects.fighter2 = {x=7*650/8, y=650/2, xv=0, yv=0, o=-1, graphic=fighterstatic, height=43, width=18, t=0, health=100}
end

function love.update(dt)
   movefighter(objects.fighter1, dt, "d", "a")
   movefighter(objects.fighter2, dt, "kp6", "kp4")
   checkgameover()
end

function love.draw()
   if gameover == nil then
      love.graphics.setColor(14, 72, 160)
      love.graphics.rectangle("fill", 0, 600, 650, 50)
      love.graphics.setColor(255,0,0)
      love.graphics.draw(objects.fighter1.graphic, objects.fighter1.x, objects.fighter1.y, 0, objects.fighter1.o, 1)
      love.graphics.printf(objects.fighter1.health, 1*650/8, 100, 6*650/8, "left")
      love.graphics.setColor(0,0,255)
      love.graphics.draw(objects.fighter2.graphic, objects.fighter2.x, objects.fighter2.y, 0, objects.fighter2.o, 1)
      love.graphics.printf(objects.fighter2.health, 1*650/8, 100, 6*650/8, "right")
   else
      love.graphics.setColor(0, 0, 0)
      love.graphics.printf(gameover .. " wins!", 1*650/8, 300, 6*650/8, "center")
   end
end

function love.mousepressed(x, y, button)
   if button == 'l' then
      imgx = x
      imgy = y
   end
end
