CubicSpline = {T=0,p=0,q=0,r=0,s=0}

function CubicSpline:new (start,final,fstart,fend,fdstart,fdend)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   self.final = T or 0
   self.fstart = p or 0
   self.fend = q or 0
   self.fdstart = r or 0
   self.fdend = s or 0;
   return o
end

function CubicSpline:get(x)
  local a = p
  local b = r
  local c = 3*((q-p)/(t*t)) - (s/t)
  local d = ((s+r)/(t*t)) - 2*((q-p)/(t*t*t))

  return (a+(b*x)+(c*x*x)+(d*x*x*x))
end


function Spline (start,final,fstart,fend,fdstart,fdend)
