function addScriptToMap(mapname)
	if mapname then --mapname is defined only on full-save
		g_MapName = mapname
	end

	if (not g_MapName) then -- if never full-saved
		outputChatBox('Could not add script to map, please do full-save first')
		return
	end


	-- Just in case, map name should be defined at this point with a valid one
	map = Resource.getFromName(g_MapName)
	if not map then
		outputChatBox(string.format('There is no map with name: %s',g_MapName))
		return
	end


	-- acl permission check
	local thisresourcename = getThisResource():getName()
	local admingroup = ACLGroup.get('MapEditor')
	local requiredobject = string.format('resource.%s',thisresourcename)
	if not admingroup:doesContainObject(requiredobject) then
		outputChatBox(string.format("Resource '%s' does not have MapEditor rights, autojump files could not be copied",thisresourcename))
		return
	end

	-- check autojump script exists
	if not Resource.getFromName('autojump') then
		outputChatBox('Resource name must be "autojump", do not change it!')
		return
	end

	-- copy script to map
	local destination = string.format(':%s/autojump.lua',g_MapName)
	fileCopy(':autojump/client.lua',destination,true)

	-- get necessary xml files
	local meta = XML.load(string.format(':%s/meta.xml',g_MapName))
	local editorMeta = XML.load(':editor_test/meta.xml')
	local mapFile = XML.load(string.format(':%s/%s',g_MapName,meta:findChild('map',0):getAttribute('src')))
	outputDebugString(string.format(':%s/%s',g_MapName,meta:findChild('map',0):getAttribute('src')))
	-- if the script is already there, notify that it was updated and finish
	local metaNodes = meta:getChildren()
	for i,node in ipairs(metaNodes) do
		if node:getName() == 'script' then
			if node:getAttribute('src') == 'autojump.lua' then
				outputChatBox(string.format('Script updated successfully on %s',g_MapName))
				editorMeta:saveFile()
				editorMeta:unload()

				copyAutojumpElementsToMap(mapFile,g_MapName,meta)

				mapFile:unload()
				meta:saveFile()
				meta:unload()
				return 
			end
		end
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

	meta:saveFile()
	meta:unload()
	editorMeta:saveFile()
	editorMeta:unload()
	mapFile:unload()


	outputChatBox(string.format('Sucessfully added autojump script to map: %s',g_MapName))
end

function filter_addScriptToMap (value)
	addScriptToMap()
end
addEventHandler('saveResource',root,addScriptToMap)
addEventHandler('quickSaveResource',root,addScriptToMap)
addEventHandler('testResource',root,filter_addScriptToMap)

function copyAutojumpElementsToMap(mapFile,mapName,mapMeta)

	local attributes = {}
	attributes['autojumpstart'] = {'id','rot_help','speed','precision','duration','model','end','posX','posY','posZ','rotX','rotY','rotZ'}
	attributes['autojumpend'] = {'id','model','posX','posY','posZ','rotX','rotY','rotZ'}

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

	if (not found) then
		local child = mapMeta:createChild('file')
		child:setAttribute('src','autojump_data.xml')
		child:setAttribute('type','client')
		outputDebugString('ADDING')
	end


	local autojumpNodes = {}

	local mapNodes = mapFile:getChildren()
	for i,node in ipairs(mapNodes) do
		if ((node:getName() == 'autojumpstart') or (node:getName() == 'autojumpend')) then
			local a = {}
			a['element_name'] = node:getName()
			for i,name in ipairs(attributes[node:getName()]) do
				a[name] = node:getAttribute(name)
			end
			outputDebugString(a['id'])
			table.insert(autojumpNodes,a)
		end
	end

	local newFile = XML.load(string.format(':%s/autojump_data.xml',mapName))
	if (newFile) then
		newFile:destroy()
		newFile:unload()
	end
	newFile = XML(string.format(':%s/autojump_data.xml',mapName),'autojumps')

	outputDebugString(#autojumpNodes)
	for i,nodedata in ipairs(autojumpNodes) do
		nodename = nodedata['element_name']
		nodedata['element_name'] = nil
		newNode = newFile:createChild(nodename)
		for i,name in ipairs(attributes[nodename]) do
			outputDebugString('newfile_save')
			newNode:setAttribute(name,nodedata[name])
		end
	end

	newFile:saveFile()
	newFile:unload()


end