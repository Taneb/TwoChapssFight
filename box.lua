local Box = {}
Box.__index = Box

function Box.new(x, y, width, height)
   local self = setmetatable({}, Box)
   if width < 0 then
      x = x + width
      width = - width
   end
   if height < 0 then
      y = y + height
      height = - height
   end
   self.x = x
   self.y = y
   self.width = width
   self.height = height
   return self
end

function Box:overlaps(other)
   if self.x > other.x + other.width or self.x + self.width < other.x then
      return false
   end
   if self.y > other.y + other.height or self.y + self.height < other.y then
      return false
   end
   return true
end

return Box
