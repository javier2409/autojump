
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
-- Ideally this should be 1 but the effect is more noticeable that way
-- (This can be changed dynamically with 'smoothness' command)
-- DO NOT SET TO ZERO OR YOUR PC WILL EXPLODE
ROTATION_DURATION = 15
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

	local hitPosTest = Vector3(getElementPosition(hitShape))
	local hashTest = hashVector(hitPosTest)

	if not saves[hashTest] then 
		return 
	end

	DISABLE_LOAD = true
	Timer(enable,200,1)

	local hitPos = Vector3(getElementPosition(hitShape))
	hash = hashVector(hitPos)

	currentVelocity = vehicle:getVelocity()
	currentRotation = vehicle:getRotation() 

	requiredRotation = saves[hash]['orig_rot']
	finalVelocity = saves[hash]['vel']
	finalRotation = saves[hash]['rot']
	finalPosition = saves[hash]['pos']
	ROTATION_DURATION = saves[hash]['duration']

	diffRotation = rotDistance(requiredRotation,currentRotation)

	outputDebugString(requiredRotation)
	outputDebugString(currentRotation)
	outputDebugString(string.format('%f',diffRotation))

	if diffRotation >= MIN_SIMILARITY_ROT then
		vehicle:setCollisionsEnabled(false)
		vehicle:setRotationBlended(finalRotation,finalPosition)
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
		saves[tonumber(attrs['hash'])]['pos'] = Vector3(tonumber(attrs['px']),tonumber(attrs['py']),tonumber(attrs['pz']))
		saves[tonumber(attrs['hash'])]['rot'] = Vector3(tonumber(attrs['rx']),tonumber(attrs['ry']),tonumber(attrs['rz']))
		saves[tonumber(attrs['hash'])]['ang'] = Vector3(tonumber(attrs['ax']),tonumber(attrs['ay']),tonumber(attrs['az']))
		saves[tonumber(attrs['hash'])]['orig_rot'] = Vector3(tonumber(attrs['orig_rx']),tonumber(attrs['orig_ry']),tonumber(attrs['orig_rz']))
		saves[tonumber(attrs['hash'])]['duration'] = tonumber(attrs['duration'])

		local cshape = ColShape.Sphere(attrs['orig_px'],attrs['orig_py'],attrs['orig_pz'],COL_SIZE)
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
	newMatrix.position = newMatrix.position + (targetMatrix.position-newMatrix.position)/ROTATION_DURATION--*((1/ROTATION_DURATION)*i*i)


	currentVehicle:setMatrix(newMatrix)
	i = i+1
	if i == ROTATION_DURATION then
		removeEventHandler('onClientRender',root,changeRotation)
		setFinalVelocity()
		outputDebugString(string.format('Corrected jump %d',getTickCount()),0,200,200,200)		
	end
end

function setFinalVelocity()
	currentVehicle:setVelocity(saves[hash]['vel'])
	currentVehicle:setAngularVelocity(saves[hash]['ang'])
	currentVehicle:setCollisionsEnabled(true)
end

function Vehicle:setRotationBlended (rotation,position)

	initialMatrix = self.matrix
	targetMatrix = Matrix(position,rotation)
	currentVehicle = self
	i = 0
	addEventHandler('onClientRender',root,changeRotation)
end