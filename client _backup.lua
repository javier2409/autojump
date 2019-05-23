
----------------------------------------------SETTINGS-----------------------------------------------------------------
--Edit this settings according to your criteria

--[[
Similarity needed between saved speed/rotation and player's speed/rotation
0 means the jump correction will be applied ALWAYS
1 means they need to be exactly equal (pointless)

Values greater than 0.97 are advisable to make the effect less noticeable
]]
MIN_SIMILARITY_SPD = 0.96 
MIN_SIMILARITY_ROT = 0.96 

-- Marker colors for recording jumps
MARKER_COLOR = Vector3(0,0,255)

-- Size of the hitboxes for jumps, smaller values mean a smaller area in which the effect will be aplied for each jump
COL_SIZE = 1.6

-- In case you want to change the jumps file name (change in meta.xml also)
FILENAME = 'jumps.xml'


-- The script rotates the car smoothly, this parameter indicates how many frames will it take to rotate the car
-- 1 means instant rotation
-- Ideally this should be 1 but the effect is more noticeable that way, set according to your map ideas
-- DO NOT SET TO ZERO OR YOUR PC WILL EXPLODE
ROTATION_DURATION = 60
-----------------------------------DO NOT CHANGE VALUES BELOW HERE-----------------------------------------------------

RECORDING = false
DISABLED = false
DISABLE_LOAD = false
file = nil
saves = {}
colshapes = {}
hashorder = {}
hash = nil

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


function setData(hitShape,dimension)

	if source ~= localPlayer:getOccupiedVehicle() then 
		return 
	end

	vehicle = localPlayer:getOccupiedVehicle()

	if RECORDING then 
		return 
	end

	if DISABLE_LOAD then return end
	DISABLE_LOAD = true
	Timer(enable,200,1)

	hitPos = Vector3(getElementPosition(hitShape))
	hash = hashVector(hitPos)

	if not saves[hash] then 
		return 
	end


	currentVelocity = vehicle:getVelocity()
	currentRotation = vehicle:getRotation() 

	requiredVelocity = saves[hash]['vel']
	requiredRotation = saves[hash]['rot']

	diffVelocity = cosDistance(requiredVelocity,currentVelocity)
	diffRotation = rotDistance(requiredRotation,currentRotation)

	outputDebugString(requiredRotation)
	outputDebugString(currentRotation)
	outputDebugString(string.format('%f %f',diffVelocity,diffRotation))

	if diffVelocity >= MIN_SIMILARITY_SPD and diffRotation >= MIN_SIMILARITY_ROT then
		vehicle:setVelocity(requiredVelocity)
		vehicle:setRotationBlended(requiredRotation)
		--vehicle:setAngularVelocity(saves[hash]['ang'])
	else
		outputDebugString('Not close enough',0,200,200,200)
	end
end
addEventHandler('onClientElementColShapeHit',root,setData)

function enable( )
	DISABLED = false
	DISABLE_LOAD = false
end

function loadDataFromFile ()
	file = XML.load(FILENAME)

	if not file then
		file = XML(FILENAME,'jumps')
		file:saveFile()
		file:unload()
		return 0
	end

	saves = file:getChildren()
	for i,save in ipairs(saves) do
		local attrs = save:getAttributes()
		saves[tonumber(attrs['hash'])] = {}
		saves[tonumber(attrs['hash'])]['vel'] = Vector3(tonumber(attrs['vx']),tonumber(attrs['vy']),tonumber(attrs['vz']))
		saves[tonumber(attrs['hash'])]['rot'] = Vector3(tonumber(attrs['rx']),tonumber(attrs['ry']),tonumber(attrs['rz']))
		saves[tonumber(attrs['hash'])]['ang'] = Vector3(tonumber(attrs['ax']),tonumber(attrs['ay']),tonumber(attrs['az']))

		local cshape = ColShape.Sphere(attrs['px'],attrs['py'],attrs['pz'],COL_SIZE)
		colshapes[tonumber(attrs['hash'])] = cshape
		table.insert(hashorder,tonumber(attrs['hash']))
	end

	file:saveFile()
	file:unload()
end
addEventHandler('onClientResourceStart',resourceRoot,loadDataFromFile)

function getMatrixFromRot(vec)
	return Matrix(Vector3(0,0,0),vec)
end

function changeRotation ()
	newMatrix = Matrix()
	newMatrix = currentVehicle:getMatrix()
	newMatrix.up = newMatrix.up + (targetMatrix.up-initialMatrix.up)/ROTATION_DURATION
	newMatrix.right = newMatrix.right + (targetMatrix.right-initialMatrix.right)/ROTATION_DURATION
	newMatrix.forward = newMatrix.forward + (targetMatrix.forward-initialMatrix.forward)/ROTATION_DURATION

	currentVehicle:setMatrix(newMatrix)
	i = i+1
	if i == ROTATION_DURATION then
		removeEventHandler('onClientRender',root,changeRotation)
		setAngularVelocity2()
		outputDebugString(string.format('Corrected jump %d',getTickCount()),0,200,200,200)		
	end
end

function setAngularVelocity2()
	currentVehicle:setAngularVelocity(saves[hash]['ang'])
end

function Vehicle:setRotationBlended (rotation)

	initialMatrix = self.matrix
	targetMatrix = Matrix(Vector3(0,0,0),rotation)
	currentVehicle = self
	i = 0
	addEventHandler('onClientRender',root,changeRotation)
end