successcolor = '#49d154'
failurecolor = '#d14b49'
attributes = {}
attributes['autojumpstart'] = {'id','rot_help','speed','precision','duration','model','end','posX','posY','posZ','rotX','rotY','rotZ'}
attributes['autojumpend'] = {'id','model','posX','posY','posZ','rotX','rotY','rotZ'}

function updateMapName(map)
	g_MapName = map:getName()
end
addEventHandler('onMapOpened',root,updateMapName)

function findNode (xmlFile,childName,srcName)
	local metaNodes = xmlFile:getChildren()
	for i,node in ipairs(metaNodes) do
		if node:getName() == childName then
			if node:getAttribute('src') == srcName then
				return node
			end
		end
	end
	return false
end

function addScriptToMap()

	-- Just in case, map name should be defined at this point with a valid one
	map = Resource.getFromName(g_MapName)
	if not map then
		outputChatBox(string.format('%sAutojump: There is no map with name: %s',failurecolor,g_MapName),root,0,0,0,true)
		return
	end


	-- acl permission check
	local thisresourcename = getThisResource():getName()
	local admingroup = ACLGroup.get('MapEditor')
	local requiredobject = string.format('resource.%s',thisresourcename)
	if not admingroup:doesContainObject(requiredobject) then
		outputChatBox(string.format("%sAutojump: Resource '%s' does not have MapEditor rights, autojump files could not be copied. Hint: don't do /start autojump, just add the definition in your map",failurecolor,thisresourcename),root,0,0,0,true)
		return
	end

	-- check autojump script exists
	if not Resource.getFromName('autojump') then
		outputChatBox(string.format('Autojump: Resource name must be "autojump", do not change it!',failurecolor),root,0,0,0,true)
		return
	end

	-- get necessary xml files
	local meta = XML.load(string.format(':%s/meta.xml',g_MapName))
	local editorMeta = XML.load(':editor_test/meta.xml')
	local mapFile = XML.load(string.format(':%s/%s',g_MapName,meta:findChild('map',0):getAttribute('src')))

	-- if no autojump nodes remove script from map as it is not needed
	if #getAutojumpNodesFromMap(mapFile) == 0 then
		deleted = false
		if fileExists(':'..g_MapName..'/autojump.lua') then
			fileDelete(':'..g_MapName..'/autojump.lua')
			deleted = true
		end

		if fileExists(':'..g_MapName..'/autojump_data.xml') then
			fileDelete(':'..g_MapName..'/autojump_data.xml')
			deleted = true
		end
		local node1 = findNode(meta,'script','autojump.lua')
		local node2 = findNode(meta,'file','autojump_data.xml')
		if node1 then node1:destroy() end
		if node2 then node2:destroy() end
		editorMeta:saveFile()
		editorMeta:unload()
		mapFile:unload()
		meta:saveFile()
		meta:unload()
		if deleted then
			outputChatBox(successcolor..'Autojump: Script removed from '..g_MapName..' (no autojumps present)', root,0,0,0,true)
		end
		return		
	end

	-- copy script to map
	local destination = string.format(':%s/autojump.lua',g_MapName)
	fileCopy(':autojump/client.lua',destination,true)

	updated = true

	-- if the script is already there, notify that it was updated and finish
	if findNode(meta,'script','autojump.lua') then
		outputChatBox(string.format('%sAutojump: Script updated successfully on %s',successcolor,g_MapName),root,0,0,0,true)

		copyAutojumpElementsToMap(mapFile,g_MapName,meta)
	--copyAutojumpElementsToMap(mapFile,'editor_test',editorMeta) This is map editor's job

		editorMeta:saveFile()
		editorMeta:unload()
		mapFile:unload()
		meta:saveFile()
		meta:unload()
		return
	end

	-- add script to map meta
	local script = meta:createChild('script')
	script:setAttribute('src','autojump.lua')
	script:setAttribute('type','client')

	-- add OOP attribute to map and editor_test too
	if not meta:findChild('oop',0) then
		local oop = meta:createChild('oop')
		oop:setValue('true')
	end
	if not editorMeta:findChild('oop',0) then
		local oop = editorMeta:createChild('oop')
		oop:setValue('true')
	end

	copyAutojumpElementsToMap(mapFile,g_MapName,meta)
	--copyAutojumpElementsToMap(mapFile,'editor_test',editorMeta) This is map editor's job

	meta:saveFile()
	meta:unload()
	editorMeta:saveFile()
	editorMeta:unload()
	mapFile:unload()


	outputChatBox(string.format('%sAutojump: Sucessfully added autojump script to map: %s',successcolor,g_MapName),root,0,0,0,true)
end

function filter_addScriptToMap (value)
	if not updated then
		outputChatBox(failurecolor..'Autojump: Autojumps may not be updated, save map before testing.',root,0,0,0,true)
	end
end
addEventHandler('testResource',root,filter_addScriptToMap)

function waitTime ()

	if (not g_MapName) then -- if never full-saved
		outputChatBox(string.format('%sAutojump: Could not add script to map, please do full-save first',failurecolor),root,0,0,0,true)
		killTimer(waitTimer)
		return
	end

	meta = XML.load(string.format(':%s/meta.xml',g_MapName))
	b = meta:findChild('map',0)
	meta:unload()	


	if b then
		killTimer(waitTimer)
		addScriptToMap()
	end
end

function setWaitTime(mapName)
	g_MapName = mapName
	--outputChatBox(successcolor..'Autojump: Waiting for map to be saved',root,0,0,0,true)
	waitTimer = setTimer(waitTime,500,40)
end
function setWaitTime_quicksave()
	waitTimer = setTimer(waitTime,500,40)
end
addEventHandler('saveResource',root,setWaitTime)
addEventHandler('quickSaveResource',root,setWaitTime_quicksave)

function copyAutojumpElementsToMap(mapFile,mapName,mapMeta)

	-- check if map's meta already has autojump_data.xml
	local found = false
	outputDebugString(string.format(':%s/autojump_data.xml',mapName))
	local metaNodes = mapMeta:getChildren()
	for i,node in ipairs(metaNodes) do
		if node:getName() == 'file' then
			if ((node:getAttribute('src') == 'autojump_data.xml') and (node:getAttribute('type') == 'client')) then
				found = true
			end
		end
	end

	-- if it doesn't, add it
	if (not found) then
		local child = mapMeta:createChild('file')
		child:setAttribute('src','autojump_data.xml')
		child:setAttribute('type','client')
	end

	-- gather autojump data from map
	local autojumpNodes = getAutojumpNodesFromMap(mapFile)

	-- copy data to autojump_data.xml and add it to map 
	local newFile = XML.load(string.format(':%s/autojump_data.xml',mapName))
	if (newFile) then
		newFile:destroy()
		newFile:unload()
	end
	newFile = XML(string.format(':%s/autojump_data.xml',mapName),'autojumps')

	for i,nodedata in ipairs(autojumpNodes) do
		nodename = nodedata['element_name']
		nodedata['element_name'] = nil
		newNode = newFile:createChild(nodename)
		for i,name in ipairs(attributes[nodename]) do
			newNode:setAttribute(name,nodedata[name])
		end
	end

	newFile:saveFile()
	newFile:unload()


end

function getAutojumpNodesFromMap (mapFile)
	local autojumpNodes = {}
	local mapNodes = mapFile:getChildren()
	for i,node in ipairs(mapNodes) do
		if ((node:getName() == 'autojumpstart') or (node:getName() == 'autojumpend')) then
			local a = {}
			a['element_name'] = node:getName()
			for i,name in ipairs(attributes[node:getName()]) do
				a[name] = node:getAttribute(name)
			end
			table.insert(autojumpNodes,a)
		end
	end
	return autojumpNodes
end

-- this ivalidates save when you modify autojumps, to warn you if you don't save before testing
function invalidate ()
	local etype = source:getType()
	if ((etype ~= 'autojumpstart') and (etype ~= 'autojumpend')) then return end
	updated = false
	outputDebugString('Autojump: invalidated save '..getTickCount())
end
addEventHandler('onElementDestroy',root,invalidate)
addEventHandler('onElementCreate',root,invalidate)
addEventHandler('onElementDrop',root,invalidate)
addEventHandler('onElementSelect',root,invalidate)
addEventHandler('onElementDestroy_undoredo',root,invalidate)
addEventHandler('onElementCreate_undoredo',root,invalidate)
addEventHandler('onElementMove_undoredo',root,invalidate)