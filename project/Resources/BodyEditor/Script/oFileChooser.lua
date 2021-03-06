local require = using("BodyEditor.Script")
local CCDirector = require("CCDirector")
local CCSize = require("CCSize")
local oSelectionPanel = require("oSelectionPanel")
local CCDrawNode = require("CCDrawNode")
local oVec2 = require("oVec2")
local ccColor4 = require("ccColor4")
local oContent = require("oContent")
local CCLabelTTF = require("CCLabelTTF")
local ccColor3 = require("ccColor3")
local oOpacity = require("oOpacity")
local oButton = require("oButton")
local CCSequence = require("CCSequence")
local CCDelay = require("CCDelay")
local CCCall = require("CCCall")
local oBox = require("oBox")
local CCMenu = require("CCMenu")
local thread = require("thread")
local emit = require("emit")
local sleep = require("sleep")

local function oFileChooser()
	local oEditor = require("oEditor")
	local winSize = CCDirector.winSize
	local itemWidth = 120
	local itemNum = 3
	while (itemWidth+10)*itemNum+10 > winSize.width and itemNum > 1 do
		itemNum = itemNum - 1
	end
	local borderSize = CCSize((itemWidth+10)*itemNum+10,winSize.height*0.6)
	local panel = oSelectionPanel(borderSize)
	local menu = panel.menu
	local border = panel.border
	local halfBW = borderSize.width*0.5
	local halfBH = borderSize.height*0.5
	local background= CCDrawNode()
	background:drawPolygon(
	{
		oVec2(-halfBW,-halfBH),
		oVec2(halfBW,-halfBH),
		oVec2(halfBW,halfBH),
		oVec2(-halfBW,halfBH)
	},ccColor4(0xe5100000),0.5,ccColor4(0xffffafaf))
	border:addChild(background,-1)

	local files = {}
	local function getResources(path)
		local entries = oContent:getEntries(oEditor.output..oEditor.prefix..path,false)
		for i = 1,#entries do
			local name = nil
			if entries[i]:sub(-5,-1) == ".body" then
				name = entries[i]:sub(1,-6)
			end
			if name then
				table.insert(files,oEditor.prefix..path..name)
			end
		end
		local folders = oContent:getEntries(oEditor.output..oEditor.prefix..path,true)
		for _,folder in ipairs(folders) do
			if folder ~= "." and folder ~= ".." then
				getResources(path..folder.."/")
			end
		end
	end
	getResources("")
	local n = 0
	local y
	local xStart = 0 -- left
	local yStart = borderSize.height -- top

	local title = CCLabelTTF("Choose  Body","Arial",24)
	title.texture.antiAlias = false
	title.color = ccColor3(0x00ffff)
	title.anchor = oVec2(0.5,1)
	y = yStart-20
	title.position = oVec2(halfBW,y)
	menu:addChild(title)
	title.opacity = 0
	title:runAction(oOpacity(0.3,1))
	yStart = y-title.contentSize.height-(oEditor.currentFile and -10 or 20)

	if oEditor.currentFile then
		title = CCLabelTTF("(Current: "..oEditor.currentFile:match("([^\\/]*)%.[^%.\\/]*$")..")","Arial",16)
		title.texture.antiAlias = false
		title.color = ccColor3(0x00ffff)
		title.anchor = oVec2(0.5,1)
		y = yStart-20
		title.position = oVec2(halfBW,y)
		menu:addChild(title)
		title.opacity = 0
		title:runAction(oOpacity(0.3,1))
		yStart = y-title.contentSize.height-10
	end

	for i = 1,#files do
		n = n+1
		y = yStart-10-math.floor((n-1)/itemNum)*60
		local name = files[i]:match("([^\\/]*)$")
		name = #name > 10 and name:sub(1,7).."..." or name
		local button = oButton(
			name,
			17,
			itemWidth,50,
			xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
			function(item)
				oEditor:edit(item.file)
				panel:hide()
			end)
		button.file = files[i]..".body"
		--button.color = ccColor3(0xffffff)
		button.anchor = oVec2(0,1)
		button.enabled = false
		button.opacity = 0
		button:runAction(
			CCSequence(
			{
				CCDelay(n*0.05),
				oOpacity(0.2,1),
				CCCall(
					function()
						button.enabled = true
					end)
			}))
		menu:addChild(button)
	end
	n = n+1
	y = yStart-10-math.floor((n-1)/itemNum)*60
	local newButton = oButton(
		"<NEW>",
		17,
		itemWidth,50,
		xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
		function()
			panel:hide()
			oEditor:addChild(oBox("New Body",function(name)
				if name == "" or name:match("[\\/|:*?<>\"%.]") then
					oEditor:addChild(oBox("Invalid Name!"),oEditor.topMost)
				else
					local newFile = oEditor.prefix..name..".body"
					if oContent:exist(oEditor.output..newFile) then
						oEditor:addChild(oBox("Name Exist!"),oEditor.topMost)
					else
						oEditor:new(newFile)
					end
				end
			end,true),oEditor.topMost)
		end)
	newButton.color = ccColor3(0x80ff00)
	newButton.anchor = oVec2(0,1)
	newButton.enabled = false
	newButton.opacity = 0
	newButton:runAction(
		CCSequence(
		{
			CCDelay(n*0.05),
			oOpacity(0.2,1),
			CCCall(
				function()
					newButton.enabled = true
				end)
		}))
	menu:addChild(newButton)

	if oEditor.currentFile and oEditor.standAlone then
		n = n+1
		y = yStart-10-math.floor((n-1)/itemNum)*60
		local delButton = oButton(
			"<DEL>",
			17,
			itemWidth,50,
			xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
			function()
				panel:hide()
				oEditor:addChild(oBox("Delete "..oEditor.currentFile:sub(1,-5),function()
					oEditor:resetEditor()
					oContent:remove(oEditor.output..oEditor.currentFile)
					oEditor.currentFile = nil
					oEditor:clearData()
					oEditor:addChild(oFileChooser(),oEditor.topMost)
				end),oEditor.topMost)
			end)
		delButton.color = ccColor3(0xff0080)
		delButton.anchor = oVec2(0,1)
		delButton.enabled = false
		delButton.opacity = 0
		delButton:runAction(
			CCSequence(
			{
				CCDelay(n*0.05),
				oOpacity(0.2,1),
				CCCall(
					function()
						delButton.enabled = true
					end)
			}))
		menu:addChild(delButton)
	end

	local viewHeight = winSize.height*0.5+halfBH-y-5
	local viewWidth = borderSize.width
	local paddingX = 0
	local paddingY = 100
	panel:reset(viewWidth,viewHeight,paddingX,paddingY)

	local opMenu = CCMenu()
	opMenu.swallowTouches = true
	opMenu.contentSize = CCSize(130,60)
	opMenu.anchor = oVec2(1,0.5)
	opMenu.touchPriority = CCMenu.DefaultHandlerPriority-3
	opMenu.position = oVec2(winSize.width*0.5+borderSize.width*0.5+30,winSize.height*0.5+borderSize.height*0.5)
	panel:addChild(opMenu)

	local cancelButton = oButton("Cancel",17,60,false,
		70,0,
		function(item)
			item.enabled = false
			opMenu.enabled = false
			panel:hide()
		end)
	cancelButton.anchor = oVec2.zero
	local btnBk = CCDrawNode()
	btnBk:drawDot(oVec2.zero,30,ccColor4(0x22ffffff))
	btnBk.position = oVec2(30,30)
	cancelButton:addChild(btnBk,-1)
	opMenu:addChild(cancelButton)

	if oEditor.quitable then
		local backButton = oButton("Quit",17,60,false,
			0,0,
			function(item)
				opMenu.enabled = false
				item.enabled = false
				panel:hide()
				if oEditor.standAlone then
					oEditor:emit("Quit")
				else
					thread(function()
						emit("Body.viewArea.toPos",oEditor.origin)
						emit("Body.viewArea.scaleReset")
						oEditor:hideEditor(true,false)
						sleep(0.6)
						oEditor:emit("Quit")
					end)
				end
			end)
		backButton.anchor = oVec2.zero
		local drawBk = CCDrawNode()
		drawBk:drawDot(oVec2.zero,30,ccColor4(0x22ffffff))
		drawBk.position = oVec2(30,30)
		backButton:addChild(drawBk,-1)
		opMenu:addChild(backButton)
	end

	panel:show()
	return panel
end

return oFileChooser
