function togglerecording ()
	RECORDING = not RECORDING
	if RECORDING then
		outputChatBox('Recording...')
	else
		outputChatBox('Working...')
	end
end
addCommandHandler('rj',togglerecording)

function markerHit (player,dimension)
	if player ~= localPlayer then return end
	if cosDistance(Vector3(source:getColor()),MARKER_COLOR) < 0.99 then 
		return 
	end
	if (not RECORDING) or DISABLED then 
		return 
	end
	saveData(source:getPosition())
end

function commandSave ()
	DISABLE_LOAD = true
	Timer(enable,200,1)

	saveData(localPlayer:getPosition())
end
addCommandHandler('sj',commandSave)

function destroyHashNode (hash)
	for i,child in ipairs(file:getChildren()) do
		if tonumber(child:getAttribute('hash')) == hash then
			child:destroy()
		end
	end
end

function saveData (pos)

	player = localPlayer

	DISABLED = true
	Timer(enable,ROTATION_DURATION,1)

	file = XML.load(FILENAME)

	hash = hashVector(pos)

	saves[hash] = {}
	saves[hash]['vel'] = player:getOccupiedVehicle():getVelocity()
	saves[hash]['rot'] = player:getOccupiedVehicle():getRotation()
	saves[hash]['ang'] = player:getOccupiedVehicle():getAngularVelocity()
	saves[hash]['x'] = pos:getX()
	saves[hash]['y'] = pos:getY()
	saves[hash]['z'] = pos:getZ()

	if colshapes[hash] then
		destroyHashNode(hash)
		colshapes[hash]:destroy()

	end

	node = file:createChild('jump')
	node:setAttribute('hash',hash)
	node:setAttribute('vx',saves[hash]['vel']:getX())
	node:setAttribute('vy',saves[hash]['vel']:getY())
	node:setAttribute('vz',saves[hash]['vel']:getZ())
	node:setAttribute('rx',saves[hash]['rot']:getX())
	node:setAttribute('ry',saves[hash]['rot']:getY())
	node:setAttribute('rz',saves[hash]['rot']:getZ())
	node:setAttribute('ax',saves[hash]['ang']:getX())
	node:setAttribute('ay',saves[hash]['ang']:getY())
	node:setAttribute('az',saves[hash]['ang']:getZ())		
	node:setAttribute('px',saves[hash]['x'])
	node:setAttribute('py',saves[hash]['y'])
	node:setAttribute('pz',saves[hash]['z'])

	colshape = ColShape.Sphere(pos,COL_SIZE)

	table.insert(hashorder,hash)
	colshapes[hash] = colshape

	file:saveFile()
	outputChatBox('Jump saved!')
	file:unload()
end
addEventHandler('onClientMarkerHit',root,markerHit)

function deleteJump ()

	if #hashorder == 0 then
		outputChatBox('You have no jumps')
		return
	end

	local removedHash = table.remove(hashorder)
	colshapes[removedHash]:destroy()
	table.remove(colshapes,removedHash)
	table.remove(saves,removedHash)
	file = XML.load(FILENAME)
	destroyHashNode(removedHash)
	file:saveFile()
	file:unload()
	outputChatBox('Last jump deleted')
end
addCommandHandler('dj',deleteJump)

