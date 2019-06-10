
----------------------------------------------SETTINGS-----------------------------------------------------------------
-- Size of the hitboxes for jumps, smaller values mean a smaller area in which the effect will be aplied for each jump
COL_SIZE = 1.6
-----------------------------------DO NOT CHANGE VALUES BELOW HERE-----------------------------------------------------

DISABLE_LOAD = false
saves = {}
autojumps = {}
hitShape = nil
DURATION = nil
ROTATION_HELP = false
local attributes = {}
attributes['autojumpstart'] = {'id','rot_help','speed','precision','duration','model','end','posX','posY','posZ','rotX','rotY','rotZ'}
attributes['autojumpend'] = {'id','model','posX','posY','posZ','rotX','rotY','rotZ'}

function getMatrixFromRot(vec)
	return Matrix(Vector3(0,0,0),vec)
end

function cosDistance (vector1,vector2)
	return (vector1:dot(vector2)/(vector1.length*vector2.length))
end

function rotDistance (vector1,vector2)
	matrix1 = getMatrixFromRot(vector1)
	matrix2 = getMatrixFromRot(vector2)
	return math.min(cosDistance(matrix1:getUp(),matrix2:getUp()),cosDistance(matrix1:getForward(),matrix2:getForward()),cosDistance(matrix1:getRight(),matrix2:getRight()))
end


function setData(hitShape,dimension)

	outputDebugString('event triggered')

	if source ~= localPlayer then
		outputDebugString('not localPlayer')
		return
	end

	if DISABLE_LOAD then 
		outputDebugString('load disabled')
		return 
	end

	if not saves[hitShape] then
		outputDebugString('no autojump attached to colshape')
		return
	end

	DISABLE_LOAD = true
	outputDebugString('performing')

	local vehicle = localPlayer:getOccupiedVehicle()
	local hitPos = Vector3(getElementPosition(hitShape))

	local currentVelocity = vehicle:getVelocity()
	local currentRotation = vehicle:getRotation()

	local requiredRotation = saves[hitShape]['orig_rot']
	local finalVelocity = saves[hitShape]['vel']
	local finalRotation = saves[hitShape]['rot']
	local finalPosition = saves[hitShape]['pos']

	DURATION = math.floor(getCurrentFPS()*saves[hitShape]['duration']*(1/getGameSpeed()))
	if DURATION < 0.01 then
		DURATION = 0.01
	end
	ROTATION_HELP = saves[hitShape]['rothelp']

	outputDebugString(string.format('Duration: %d frames',DURATION))

	local diffRotation = rotDistance(requiredRotation,currentRotation)

	outputDebugString(requiredRotation)
	outputDebugString(currentRotation)
	outputDebugString(string.format('%f',diffRotation))

	if diffRotation >= (2*saves[hitShape]['precision'] - 1)  then
		--vehicle:setCollisionsEnabled(false) CAUSES CAMERA BUGS
		if ROTATION_HELP then vehicle:setAngularVelocity(Vector3(0,0,0)) end
		vehicle:doAutojump(currentVelocity,finalRotation,finalPosition,finalVelocity)
	else
		outputDebugString('Not close enough',0,200,200,200)
	end
end
addEventHandler('onClientElementColShapeHit',localPlayer,setData)



function changeRotation ()
	
	if ROTATION_HELP then
		local newMatrix = currentVehicle:getMatrix()
		newMatrix.up = newMatrix.up + (targetMatrix.up - initialMatrix.up)/(DURATION)
		newMatrix.right = newMatrix.right + (targetMatrix.right - initialMatrix.right)/(DURATION)
		newMatrix.forward = newMatrix.forward + (targetMatrix.forward - initialMatrix.forward)/(DURATION)
		newMatrix.position = Vector3(splineX:get(i),splineY:get(i),splineZ:get(i))

		currentVehicle:setMatrix(newMatrix)
	else
		currentVehicle:setPosition(Vector3(splineX:get(i),splineY:get(i),splineZ:get(i)))	
	end
		currentVehicle:setVelocity(Vector3(splineX:get_der(i),splineY:get_der(i),splineZ:get_der(i)))
	if (i == DURATION) or (i > DURATION) then --second condition to avoid infinite loop just in case
		removeEventHandler('onClientRender',root,changeRotation)
		outputDebugString(string.format('Corrected jump %d',getTickCount()),0,200,200,200)
		DISABLE_LOAD = false
	end
	i = i+1
end

function Vehicle.doAutojump (self,startVelocity,finalRotation,finalPosition,finalVelocity)
	splineX = CubicSpline.new 	(DURATION,
								self:getPosition():getX(),
								finalPosition:getX(),
								startVelocity:getX(),
								finalVelocity:getX())

	splineY = CubicSpline.new 	(DURATION,
								self:getPosition():getY(),
								finalPosition:getY(),
								startVelocity:getY(),
								finalVelocity:getY())

	splineZ = CubicSpline.new 	(DURATION,
								self:getPosition():getZ(),
								finalPosition:getZ(),
								startVelocity:getZ(),
								finalVelocity:getZ())

	initialMatrix = self.matrix
	targetMatrix = Matrix(finalPosition,finalRotation)
	currentVehicle = self
	i = 0
	addEventHandler('onClientRender',root,changeRotation)
end

function createAutojumpElements()
	file = XML.load('autojump_data.xml')
	for i,node in ipairs(file:getChildren()) do
		newElement = Element(node:getName().."X")
		for i,name in ipairs(attributes[node:getName()]) do
			newElement:setData(name,node:getAttribute(name))
		end
		table.insert(autojumps,newElement)
	end
	file:unload()
end

function loadDataFromFile ()

	createAutojumpElements()

	local autojumps = getElementsByType('autojumpstartX',resourceRoot)
	for i,autojump in ipairs(autojumps) do

		local autojumpEnd = getAutojumpEnd(autojump:getData('end'))

		-- Check that the autojump is configured
		if 	autojumpEnd 							and 
			tonumber(autojump:getData('duration')) 	and
			tonumber(autojump:getData('precision')) and
			tonumber(autojump:getData('speed')) 	then
			-- Also check that is is configued correctly
			if 	tonumber(autojump:getData('duration')) >= 0.1 	and
				tonumber(autojump:getData('precision')) >= 0	and
				tonumber(autojump:getData('precision')) <= 1	and
				tonumber(autojump:getData('speed'))	>= 0		then -- Should speed < 0 be allowed? Technically yes, but what's the point?


				local cshape = ColShape.Sphere(autojump:getData('posX'),
											autojump:getData('posY'),
											autojump:getData('posZ'),
											COL_SIZE)

				saves[cshape] = {}
				saves[cshape]['pos'] = Vector3(autojumpEnd:getData('posX'),
												autojumpEnd:getData('posY'),
												autojumpEnd:getData('posZ'))

				saves[cshape]['duration'] = tonumber(autojump:getData('duration'))
				saves[cshape]['precision'] = tonumber(autojump:getData('precision'))

				if autojump:getData('rot_help') == 'true' then saves[cshape]['rothelp'] = true end
				if autojump:getData('rot_help') == 'false' then saves[cshape]['rothelp'] = false end

				--[[
				Rotations work differently in objects than in vehicles
				the editor gives "object" formatted rotation, I need to convert it
				to "vehicle" rotation using a 'dummy' vehicle
				]]

				local dummyVehicle = Vehicle(411,0,0,0)
				
				local dummyRotation = Vector3(autojumpEnd:getData('rotX'),
											autojumpEnd:getData('rotY'),
											autojumpEnd:getData('rotZ'))
				
				local dummyRotation_o = Vector3(autojump:getData('rotX'),
											autojump:getData('rotY'),
											autojump:getData('rotZ'))
				
				-- For some reason oop version of this function seems to ignore 'ZXY' parameter
				-- 'ZXY' means "interpret this rotation as an object rotation"
				setElementRotation(dummyVehicle,dummyRotation,'ZXY')

				-- Now I get vehicle formatted rotation because I'm getting it from a real vehicle.
				saves[cshape]['rot'] = dummyVehicle:getRotation()
				saves[cshape]['vel'] = dummyVehicle.matrix.forward * tonumber(autojump:getData('speed'))

				setElementRotation(dummyVehicle,dummyRotation_o,'ZXY')

				saves[cshape]['orig_rot'] = dummyVehicle:getRotation()

				dummyVehicle:destroy()
			end
		end
	end
end
addEventHandler('onClientResourceStart',resourceRoot,loadDataFromFile)

function getAutojumpEnd(name)
	local autoends = getElementsByType('autojumpendX',resourceRoot)
	for i,autojump in ipairs(autoends) do
		if autojump:getData('id') == name then
			return autojump
		end
	end
end

-------------------------------FPS UTILITY FUNCTION (taken from MTA Wiki)---------------
local fps = false
function getCurrentFPS() -- Setup the useful function
    return fps
end

local function updateFPS(msSinceLastFrame)
    -- FPS are the frames per second, so count the frames rendered per milisecond using frame delta time and then convert that to frames per second.
    fps = (1 / msSinceLastFrame) * 1000
end
addEventHandler("onClientPreRender", root, updateFPS)


-----------------------------------CUBIC SPLINE-----------------------------------------
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

function CubicSpline:get_der(x)
  local a = self.p
  local b = self.r
  local c = (3*((self.q-self.p)/(self.t*self.t))) - ((self.s+(2*self.r))/self.t)
  local d = ((self.s+self.r)/(self.t*self.t)) - (2*((self.q-self.p)/(self.t*self.t*self.t)))

  return (b+(2*c*x)+(3*d*x*x))
end	