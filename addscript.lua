function addScriptToMap(mapname)

	map = Resource.getFromName(mapname)
	if not map then
		outputChatBox(string.format('There is no map with name: %s',mapname))
		return
	end

	local thisresourcename = getThisResource():getName()
	local admingroup = ACLGroup.get('MapEditor')
	local requiredobject = string.format('resource.%s',thisresourcename)
	if not admingroup:doesContainObject(requiredobject) then
		outputChatBox(string.format("Resource '%s' does not have MapEditor rights, autojump files could not be copied",thisresourcename))
		return
	end


	if not Resource.getFromName('autojump') then
		outputChatBox('Resource name must be "autojump", do not change it!')
		return
	end

	local destination = string.format(':%s/autojump.lua',mapname)
	fileCopy(':autojump/client.lua',destination,true)
	local meta = XML.load(string.format(':%s/meta.xml',mapname))
	local editorMeta = XML.load(':editor_test/meta.xml')

	metaNodes = meta:getChildren()
	for i,node in ipairs(metaNodes) do
		if node:getName() == 'script' then
			if node:getAttribute('src') == 'autojump.lua' then
				outputChatBox('Script updated successfully')
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
addEventHandler('saveResource',root,addScriptToMap)