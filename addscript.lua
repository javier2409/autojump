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

	-- if the script is already there, notify that it was updated and finish
	metaNodes = meta:getChildren()
	for i,node in ipairs(metaNodes) do
		if node:getName() == 'script' then
			if node:getAttribute('src') == 'autojump.lua' then
				outputChatBox(string.format('Script updated successfully on %s',g_MapName))
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

	meta:saveFile()
	meta:unload()
	editorMeta:saveFile()
	editorMeta:unload()


	outputChatBox(string.format('Sucessfully added autojump script to map: %s',g_MapName))
end

function waitTime ()
	meta = XML.load(string.format(':%s/meta.xml',g_MapName))
	b = meta:findChild('map',0)
	meta:unload()	

	if b then
		addScriptToMap()
		killTimer(waitTimer)
	end
end

function setWaitTime(mapName)
	g_MapName = mapName
	outputChatBox('Autojump: Waiting for map to be saved')
	waitTimer = setTimer(waitTime,100,0)
end
addEventHandler('saveResource',root,setWaitTime)
addEventHandler('quickSaveResource',root,setWaitTime)