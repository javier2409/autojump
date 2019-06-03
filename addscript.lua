function addScriptToMap(player,command,mapname)

	map = getResourceFromName(mapname)
	if not map then
		outputChatBox(string.format('There is no map with name: %s',mapname))
		return
	end

	local thisresourcename = getThisResource():getName()
	local admingroup = ACLGroup.get('Admin')
	local requiredobject = string.format('resource.%s',thisresourcename)
	if not admingroup:doesContainObject(requiredobject) then
		outputChatBox(string.format("Resource '%s' does not have Admin rights, files could not be copied",thisresourcename))
		return
	end


	local destination = string.format(':%s/autojump.lua',mapname)
	fileCopy('client.lua',destination,true)
	local meta = XML.load(string.format(':%s/meta.xml',mapname))
	local editorMeta = XML.load(':editor_test/meta.xml')

	metaNodes = meta:getChildren()
	for i,node in ipairs(metaNodes) do
		if node:getName() == 'script' then
			if node:getAttribute('src') == 'autojump.lua' then
				return 
			end
		end
	end

	local script = meta:createChild('script')
	script:setAttribute('src','autojump.lua')
	script:setAttribute('type','client')

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


	outputChatBox(string.format('Sucessfully added autojump script to map: %s',mapname))
end
addCommandHandler('addscript',addScriptToMap)
