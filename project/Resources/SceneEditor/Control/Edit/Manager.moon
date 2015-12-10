Dorothy!
Class = unpack require "class"
Button = require "Control.Basic.Button"
SelectionPanel = require "Control.Basic.SelectionPanel"
GroupChooser = require "Control.Edit.GroupChooser"
GroupPanel = require "Control.Edit.GroupPanel"
ContactPanel = require "Control.Edit.ContactPanel"

Class => CCNode!,
	__init:=>
		{:width,:height} = CCDirector.winSize
		_stopEditing = nil
		stopEditing = -> _stopEditing! if _stopEditing
		cancelEditing = -> emit "Scene.SettingPanel.Edit",nil

		@schedule once ->
			sleep 0.1
			Ruler = require "Control.Edit.Ruler"
			@ruler = Ruler {
				x:(width-330)/2+70
				y:100
				width:width-340
				height:60
			}
			@addChild @ruler
		showRuler = (...)->
			@ruler\show ...
			_stopEditing = ->
				_stopEditing = nil
				@ruler\hide!

		@boolSwitcher = with CCMenu!
			.visible = false
			.position = oVec2 width-225,95
			.contentSize = CCSize 50,50
			.touchPriority = editor.levelEditMenu
			switcher = with Button {
					text:"True"
					x:25
					y:25
					width:50
					height:50
					fontSize:18
				}
				.value = true
				\slots "Tapped",-> @boolSwitcher\setValue not .value
			\addChild switcher
			.setValue = (value)=>
				switcher.value = value
				switcher.text = value and "True" or "False"
				switcher.color = ccColor3 value and 0x00ffff or 0xff0088
				\emit "Changed",value
		@addChild @boolSwitcher
		showSwitcher = (default,callback)->
			with @boolSwitcher
				\setValue default
				\slots("Changed")\set callback
				.visible = true
				.scaleX = 0
				.scaleY = 0
				\perform oScale 0.3,1,1,oEase.OutBack
			_stopEditing = ->
				_stopEditing = nil
				@boolSwitcher\perform CCSequence {
					oScale 0.3,0,0,oEase.InBack
					CCHide!
				}

		@gslot "Scene.ViewPanel.Select",cancelEditing

		@gslot "Scene.SettingPanel.Edit",(menuItem)->
			if menuItem and menuItem.selected and editor.currentData
				data = editor.currentData
				item = editor\getItem data
				switch menuItem.name
					when "outline","loop","visible","faceRight","play"
						showSwitcher data[menuItem.name],(value)->
							data[menuItem.name] = value
							menuItem.value = value
							switch menuItem.name
								when "outline"
									item.showDebug = value
								when "loop"
									item.loop = value
								when "visible"
									item.visible = value and data.display
								when "faceRight"
									item.faceRight = value
								when "play"
									if value
										item\start!
									else
										item\stop!
					when "ratioX","ratioY"
						default = data[menuItem.name]
						valueChanged = (value)->
							data[menuItem.name] = value
							menuItem.value = value
						start,stop,interval = if data.typeName == "Camera"
							0,1,0.1
						else
							-10,10,1
						showRuler default,start,stop,interval,valueChanged
					when "speed"
						showRuler data[menuItem.name],0,10,1,(value)->
							data[menuItem.name] = value
							menuItem.value = value
							item.speed = value
					when "look"
						file = data.file
						looks = oCache.Model\getLookNames file
						table.insert looks,1,"None"
						with SelectionPanel items:looks
							\slots "Selected",(value)->
								data[menuItem.name] = (value == "None" and "" or value)
								menuItem.value = value
								item.look = value
								cancelEditing!
					when "animation"
						file = data.file
						looks = oCache.Model\getAnimationNames file
						table.insert looks,1,"None"
						with SelectionPanel items:looks
							\slots "Selected",(value)->
								data[menuItem.name] = (value == "None" and "" or value)
								menuItem.value = value
								item\play value
								cancelEditing!
					when "group"
						groupChooser = with GroupChooser!
							\slots "Hide",cancelEditing
							\slots "Selected",(group)->
								data[menuItem.name] = group
								menuItem.value = editor.sceneData.groups[group]
								groupChooser\hide!
					when "effect"
						print 1
					when "offset","position"
						print 1
					when "simulation"
						with SelectionPanel items:{"Low","Medium","High"}
							\slots "Selected",(value,index)->
								data[menuItem.name] = index
								menuItem.value = value
								cancelEditing!
					when "zoom","scale"
						print 1
					when "angle"
						print 1
					when "skew"
						print 1
					when "groups"
						with GroupPanel!
							\slots "Hide",-> cancelEditing!
					when "contacts"
						groupChooser = with GroupChooser!
							\slots "Hide",-> cancelEditing!
							\slots "Selected",(group)->
								groupChooser\slots "Hide",nil
								groupChooser\hide!
								with ContactPanel group:group
									\slots "Hide",-> cancelEditing!
					when "target"
						print 1
					when "gravity"
						print 1
					when "opacity"
						print 1
			else
				stopEditing!
