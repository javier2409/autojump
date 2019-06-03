
----------------------------------------------SETTINGS-----------------------------------------------------------------
-- Size of the hitboxes for jumps, smaller values mean a smaller area in which the effect will be aplied for each jump
COL_SIZE = 1.6
-----------------------------------DO NOT CHANGE VALUES BELOW HERE-----------------------------------------------------

RECORDING = false
DISABLED = false
DISABLE_LOAD = false
saves = {}
hitShape = nil

function hashVector(vector)
	x = math.floor(vector:getX())
	y = math.floor(vector:getY())
	z = math.floor(vector:getZ())

	return math.floor((x/7)+(y/13)+(z/21))
end

function cosDistance (vector1,vector2)
	return (vector1:dot(vector2)/(vector1.length*vector2.length))
end

function rotDistance (vector1,vector2)
	matrix1 = getMatrixFromRot(vector1)
	matrix2 = getMatrixFromRot(vector2)
	return math.min(cosDistance(matrix1:getUp(),matrix2:getUp()),cosDistance(matrix1:getForward(),matrix2:getForward()),cosDistance(matrix1:getRight(),matrix2:getRight()))
end


function setData(localHitShape,dimension)

	if source ~= localPlayer:getOccupiedVehicle() then
		return
	end

	if RECORDING then
		return
	end

	if DISABLE_LOAD then return end

	if not saves[localHitShape] then
		return
	end

	DISABLE_LOAD = true
	Timer(enable,200,1)

	hitShape = localHitShape

	vehicle = localPlayer:getOccupiedVehicle()
	local hitPos = Vector3(getElementPosition(hitShape))

	currentVelocity = vehicle:getVelocity()
	currentRotation = vehicle:getRotation()

	requiredRotation = saves[hitShape]['orig_rot']
	finalVelocity = saves[hitShape]['vel']
	finalRotation = saves[hitShape]['rot']
	finalPosition = saves[hitShape]['pos']
	ROTATION_DURATION = math.floor(getCurrentFPS()*saves[hitShape]['duration'])

	outputDebugString(string.format('Duration: %d frames',ROTATION_DURATION))

	diffRotation = rotDistance(requiredRotation,currentRotation)

	outputDebugString(requiredRotation)
	outputDebugString(currentRotation)
	outputDebugString(string.format('%f',diffRotation))

	if diffRotation >= (2*saves[hitShape]['precision'] - 1)  then
		splineX = Spline(ROTATION_DURATION,
							vehicle:getPosition():getX(),
							finalPosition:getX(),
							currentVelocity:getX(),
							finalVelocity:getX())

		splineY = Spline(ROTATION_DURATION,
							vehicle:getPosition():getY(),
							finalPosition:getY(),
							currentVelocity:getY(),
							finalVelocity:getY())

		splineZ = Spline(ROTATION_DURATION,
							vehicle:getPosition():getZ(),
							finalPosition:getZ(),
							currentVelocity:getZ(),
							finalVelocity:getZ())
		--vehicle:setCollisionsEnabled(false)
		vehicle:setAngularVelocity(Vector3(0,0,0))
		setRotationBlended(vehicle,finalRotation,finalPosition)
	else
		outputDebugString('Not close enough',0,200,200,200)
	end
end
addEventHandler('onClientElementColShapeHit',root,setData)

function enable( )
	DISABLED = false
	DISABLE_LOAD = false
end


function getMatrixFromRot(vec)
	return Matrix(Vector3(0,0,0),vec)
end

function changeRotation ()
	newMatrix = Matrix()
	newMatrix = currentVehicle:getMatrix()
	newMatrix.up = newMatrix.up + (targetMatrix.up-initialMatrix.up)/ROTATION_DURATION
	newMatrix.right = newMatrix.right + (targetMatrix.right-initialMatrix.right)/ROTATION_DURATION
	newMatrix.forward = newMatrix.forward + (targetMatrix.forward-initialMatrix.forward)/ROTATION_DURATION
	newMatrix.position = Vector3(splineX:get(i),splineY:get(i),splineZ:get(i))

	currentVehicle:setMatrix(newMatrix)
	i = i+1
	if i == ROTATION_DURATION then
		removeEventHandler('onClientRender',root,changeRotation)
		currentVehicle:setCollisionsEnabled(true)
		setFinalVelocity()
		outputDebugString(string.format('Corrected jump %d',getTickCount()),0,200,200,200)
	end
end

function setFinalVelocity()
	currentVehicle:setVelocity(saves[hitShape]['vel'])
	--currentVehicle:setAngularVelocity(saves[hash]['ang'])
end

function setRotationBlended (vehicle,rotation,position)

	initialMatrix = vehicle.matrix
	targetMatrix = Matrix(position,rotation)
	currentVehicle = vehicle
	i = 0
	addEventHandler('onClientRender',root,changeRotation)
end

function loadDataFromFile ()

	autojumps = getElementsByType('autojumpstart',resourceRoot)
	for i,autojump in ipairs(autojumps) do
		outputDebugString(i)

		autojumpEnd = getAutojumpEnd(autojump:getData('end'))
		outputDebugString(type(autojumpEnd:getData('posX')))
		cshape = ColShape.Sphere(autojump:getData('posX'),autojump:getData('posY'),autojump:getData('posZ'),COL_SIZE)
		saves[cshape] = {}
		saves[cshape]['pos'] = Vector3(autojumpEnd:getData('posX'),autojumpEnd:getData('posY'),autojumpEnd:getData('posZ'))
		saves[cshape]['rot'] = Vector3(autojumpEnd:getData('rotX'),autojumpEnd:getData('rotY'),autojumpEnd:getData('rotZ'))
		
		dummyVehicle = Vehicle(411,saves[cshape]['pos'],saves[cshape]['rot'])
		saves[cshape]['vel'] = dummyVehicle.matrix.forward * tonumber(autojump:getData('speed'))
		dummyVehicle:destroy()

		outputDebugString(saves[cshape]['rot'])
		saves[cshape]['orig_rot'] = Vector3(autojump:getData('rotX'),autojump:getData('rotY'),autojump:getData('rotZ'))
		outputDebugString(saves[cshape]['orig_rot'])
		saves[cshape]['duration'] = tonumber(autojump:getData('duration'))
		saves[cshape]['precision'] = tonumber(autojump:getData('precision'))

	end
end
addEventHandler('onClientResourceStart',resourceRoot,loadDataFromFile)

function getAutojumpEnd(name)
	autoends = getElementsByType('autojumpend',resourceRoot)
	for i,autojump in ipairs(autoends) do
		if autojump:getData('id') == name then
			return autojump
		end
	end
end

-------------------------------FPS UTILITY FUNCTION------------------------------------
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


function Spline (final,fstart,fend,fdstart,fdend)
  return CubicSpline.new(final,fstart,fend,fdstart,fdend)
end

