CubicSpline = {}
CubicSpline.__index = CubicSpline

function CubicSpline.new (final,fstart,fend,fdstart,fdend)
   local self = setmetatable({},CubicSpline)
   self.t = final or 0
   self.p = fstart or 0
   self.q = fend or 0
   self.r = fdstart or 0
   self.s = fdend or 0;
   return self
end

function CubicSpline:get(x)
  local a = self.p
  local b = self.r
  local c = (3*((self.q-self.p)/(self.t*self.t))) - ((self.s+(2*self.r))/self.t)
  local d = ((self.s+self.r)/(self.t*self.t)) - (2*((self.q-self.p)/(self.t*self.t*self.t)))

  return (a+(b*x)+(c*x*x)+(d*x*x*x))
end


function Spline (final,fstart,fend,fdstart,fdend)
  return CubicSpline.new(final,fstart,fend,fdstart,fdend)
end
