
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

function findHashNode (hash)
	for i,child in ipairs(file:getChildren()) do
		if tonumber(child:getAttribute('hash')) == hash then
			return child
		end
	end
end

function saveRotationHelper ()
	j = j+1
	if j == ROTATION_DURATION then
		saves[hash]['ang'] = player:getOccupiedVehicle():getAngularVelocity()
		saves[hash]['rot'] = localPlayer:getOccupiedVehicle():getRotation()
		saves[hash]['pos'] = localPlayer:getOccupiedVehicle():getPosition()
		saves[hash]['vel'] = player:getOccupiedVehicle():getVelocity()
		file =  XML.load('jumps.xml')
		node =  findHashNode(hash)
		node:setAttribute('px',saves[hash]['pos']:getX())
		node:setAttribute('py',saves[hash]['pos']:getY())
		node:setAttribute('pz',saves[hash]['pos']:getZ())
		node:setAttribute('rx',saves[hash]['rot']:getX())
		node:setAttribute('ry',saves[hash]['rot']:getY())
		node:setAttribute('rz',saves[hash]['rot']:getZ())
		node:setAttribute('vx',saves[hash]['vel']:getX())
		node:setAttribute('vy',saves[hash]['vel']:getY())
		node:setAttribute('vz',saves[hash]['vel']:getZ())
		node:setAttribute('ax',saves[hash]['ang']:getX())
		node:setAttribute('ay',saves[hash]['ang']:getY())
		node:setAttribute('az',saves[hash]['ang']:getZ())		
		file:saveFile()
		file:unload()
		removeEventHandler('onClientRender',root,saveRotationHelper)
		outputChatBox('Jump saved!')
	end
end

function saveRotationDelayed ()
	j = 0
	addEventHandler('onClientRender',root,saveRotationHelper)
end

function saveData (pos)

	player = localPlayer

	DISABLED = true
	DISABLE_LOAD = true
	Timer(enable,200+ROTATION_DURATION,1)

	file = XML.load(FILENAME)

	hash = hashVector(pos)

	node = file:createChild('jump')

	saves[hash] = {}
	saves[hash]['orig_rot'] = player:getOccupiedVehicle():getRotation()
	saveRotationDelayed()
	saves[hash]['orig_pos'] = pos
	saves[hash]['duration'] = ROTATION_DURATION

	if colshapes[hash] then
		destroyHashNode(hash)
		colshapes[hash]:destroy()
	end

	node:setAttribute('hash',hash)
	node:setAttribute('orig_px',saves[hash]['orig_pos']:getX())
	node:setAttribute('orig_py',saves[hash]['orig_pos']:getY())
	node:setAttribute('orig_pz',saves[hash]['orig_pos']:getZ())
	node:setAttribute('orig_rx',saves[hash]['orig_rot']:getX())
	node:setAttribute('orig_ry',saves[hash]['orig_rot']:getY())
	node:setAttribute('orig_rz',saves[hash]['orig_rot']:getZ())
	node:setAttribute('duration',ROTATION_DURATION)

	colshape = ColShape.Sphere(pos,COL_SIZE)

	table.insert(hashorder,hash)
	colshapes[hash] = colshape

	file:saveFile()
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

function changeRotationDuration (cname,newDuration)
	outputDebugString(string.format('Duration changed to %d',tonumber(newDuration)))
	if tonumber(newDuration) < 1 then
		outputChatBox("Don't do that please")
		return
	end

	if tonumber(newDuration) then
		ROTATION_DURATION = math.floor(tonumber(newDuration))
	end
end
addCommandHandler('smoothness',changeRotationDuration)
