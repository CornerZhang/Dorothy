Dorothy!
ExprEditorView = require "View.Control.Trigger.ExprEditor"
TriggerExpr = require "Control.Trigger.TriggerExpr"
ExprChooser = require "Control.Trigger.ExprChooser"
TriggerDef = require "Data.TriggerDef"

Class ExprEditorView,
	__init:(args)=>
		@exprData = nil
		@asyncLoad = false
		@actionItem = nil
		@localVarItem = nil
		@locals = nil
		@localSet = nil
		@localVarFrom = nil
		@localVarTo = nil

		for child in *@editMenu.children
			child.scale = oScale 0.3,1,1,oEase.OutQuad

		@_selectedExprItem = nil
		@changeExprItem = (button)->
			@_selectedExprItem.checked = false if @_selectedExprItem
			@_selectedExprItem = button.checked and button or nil
			if button.checked
				@editMenu.visible = true
				@editMenu.transformTarget = button
				@editMenu.position = oVec2 button.width,0
				{:expr,:index,:parentExpr} = @_selectedExprItem
				subExprItem = switch @_selectedExprItem.itemType
					when "Mid","End" then true
					else false
				edit = not subExprItem
				insert = switch expr[1]
					when "Condition","Event","Action" then false
					else
						if not subExprItem
							if parentExpr then (parentExpr[1] ~= "Event")
							else true
						else false
				add = switch expr[1]
					when "Event"
						#expr == 1
					else
						if parentExpr then (parentExpr[1] ~= "Event")
						else true
				del = switch expr[1]
					when "Condition","Event","Action" then false
					else not subExprItem
				up = index and index > 2 and not subExprItem
				down = index and index < #parentExpr and not subExprItem
				buttons = for v,k in pairs {:edit,:insert,:add,:del,:up,:down}
					if k then v
					else continue
				@showEditButtons buttons
			else
				@editMenu.visible = false
				@editMenu.transformTarget = nil

		@setupMenuScroll @triggerMenu

		getLocalVarText = ->
			defaultValues = for var in *@locals
				switch @localSet[var]
					when "Number" then "0"
					else "nil"
			"local "..table.concat(@locals,", ").." = "..table.concat(defaultValues,", ")

		createLocalVarItem = ->
			indent = @actionItem.indent+1
			localVarItem = with @createExprItem getLocalVarText!,indent
				.positionY = @actionItem.positionY-@actionItem.height/2-.height/2
			children = @triggerMenu.children
			index = children\index(@actionItem)+1
			children\removeLast!
			children\insert localVarItem,index
			localVarItem

		refreshLocalVars = ->
			if @actionItem
				nextExpr = (expr)->
					return unless "table" == type expr
					switch expr[1]
						when "SetLocalNumber"
							if not @localSet[expr[2][2]]
								@localSet[expr[2][2]] = "Number"
								table.insert @locals,expr[2][2]
					for i = 2,#expr
						nextExpr expr[i]
				@locals = {}
				@localSet = {}
				nextExpr @actionItem.expr
				if @localVarItem
					if #@locals > 0
						@localVarItem.text = getLocalVarText!
					else
						@localVarItem.parent\removeChild @localVarItem
						@localVarItem = nil
				else
					if #@locals > 0
						@localVarItem = createLocalVarItem!

		nextExpr = (parentExpr,index,indent)->
			expr = index and parentExpr[index] or parentExpr
			switch expr[1]
				when "Trigger"
					@createExprItem "Trigger(",indent
					for i = 2,4
						nextExpr expr,i,indent+1
					@createExprItem ")",indent
				when "Event"
					with @createExprItem "Event(",indent,expr
						.itemType = "Start"
						.actionExpr = expr
					nextExpr expr,2,indent+1
					@createExprItem "),",indent
					indent -= 1
				when "Condition"
					with @createExprItem "Condition( function() return",indent,expr
						.itemType = "Start"
						.actionExpr = expr
					for i = 2,#expr
						nextExpr expr,i,indent+1
					@createExprItem "end ),",indent
				when "Action"
					@actionItem = with @createExprItem "Action( function()",indent,expr
						.itemType = "Start"
						.actionExpr = expr
					children = @triggerMenu.children
					index = #children+1
					for i = 2,#expr
						nextExpr expr,i,indent+1
					if #@locals > 0
						@localVarItem = createLocalVarItem!
						moveY = @localVarItem.height
						start = index+1
						stop = #children
						for child in *children[start,stop]
							child.positionY -= moveY
					@createExprItem "end )",indent
				when "If"
					with @createExprItem tostring(expr),indent,expr,parentExpr,index
						.itemType = "Start"
						.actionExpr = expr[3]
					for i = 2,#expr[3]
						nextExpr expr[3],i,indent+1
					with @createExprItem "else",indent,expr[4],expr,4
						.itemType = "Mid"
						.actionExpr = expr[4]
					for i = 2,#expr[4]
						nextExpr expr[4],i,indent+1
					with @createExprItem "end",indent,expr,parentExpr,index
						.itemType = "End"
				when "Loopi"
					with @createExprItem tostring(expr),indent,expr,parentExpr,index
						.itemType = "Start"
						.actionExpr = expr[5]
					for i = 2,#expr[5]
						nextExpr expr[5],i,indent+1
					with @createExprItem "end",indent,expr,parentExpr,index
						.itemType = "End"
				when "SetLocalNumber"
					if not @localSet[expr[2][2]]
						@localSet[expr[2][2]] = "Number"
						table.insert @locals,expr[2][2]
					@createExprItem tostring(expr),indent,expr,parentExpr,index
				else
					@createExprItem tostring(expr),indent,expr,parentExpr,index

		@nextExpr = (parentExpr,indent,index)=>
			nextExpr parentExpr,index,indent -- params order changed

		addNewItem = (selectedExprItem,indent,parentExpr,index,delExpr=true,insertAfter=false)->
			-- update triggerMenu
			children = @triggerMenu.children
			itemIndex = children\index selectedExprItem
			startIndex = #children+1
			@nextExpr parentExpr,indent,index
			stopIndex = #children
			-- get new items
			newItems = [child for child in *children[startIndex,stopIndex]]
			-- unselect item
			targetItem = selectedExprItem
			targetExpr = targetItem.expr
			selectedExprItem.checked = false
			@.changeExprItem selectedExprItem
			-- remove old expr items
			if delExpr
				if targetExpr.MultiLine
					endSearch = false
					targetItems = for childItem in *children[itemIndex,]
						break if endSearch
						if childItem.expr == targetExpr and childItem.itemType == "End"
							endSearch = true
							childItem
						childItem
					for item in *targetItems
						@triggerMenu\removeChild item
				else
					@triggerMenu\removeChild targetItem
			elseif insertAfter
				if targetExpr.MultiLine
					for i = itemIndex,#children
						childItem = children[i]
						if childItem.expr == targetExpr and childItem.itemType == "End"
							itemIndex = i+1
							break
				else
					itemIndex += 1
			-- insert new expr items in right position
			for item in *newItems
				children\insert item,itemIndex
				itemIndex += 1
			-- separate condition exprs by comma
			if not delExpr and parentExpr[1] == "Condition"
				selectedExprItem\updateText!
			-- remove duplicated new exprs
			for i = startIndex,stopIndex
				children\removeLast!
			-- refresh local variable names
			refreshLocalVars!
			if @localVarFrom
				@renameLocalVar @localVarFrom,@localVarTo
				@localVarFrom,@localVarTo = nil,nil
			-- update items position
			offset = @offset
			@offset = oVec2.zero
			@viewSize = @triggerMenu\alignItems 0
			@offset = offset
			-- select new expr item
			newItems[1].checked = true
			@.changeExprItem newItems[1]

		@editBtn\slot "Tapped",->
			selectedExprItem = @_selectedExprItem
			if selectedExprItem
				{:expr,:parentExpr,:index} = selectedExprItem
				with ExprChooser {
						valueType:expr.Type
						expr:expr
						parentExpr:parentExpr
						owner:@
					}
					\slot "Result",(newExpr)->
						if parentExpr
							parentExpr[index] = newExpr
							addNewItem selectedExprItem,selectedExprItem.indent,parentExpr,index

		insertNewExpr = (after)-> ->
			selectedExprItem = @_selectedExprItem
			{:expr,:indent,:parentExpr,:index} = selectedExprItem
			parentExpr or= expr
			if after
				switch selectedExprItem.itemType
					when "Start","Mid"
						parentExpr = selectedExprItem.actionExpr
						index = #parentExpr+1
						indent += 1
						if index > 1
							lastExpr = parentExpr[#parentExpr]
							isMultiLine = not not lastExpr.MultiLine -- MultiLine can be nil
							children = @triggerMenu.children
							startIndex = children\index(selectedExprItem)+1
							for childItem in *children[startIndex,]
								if childItem.expr == lastExpr and (isMultiLine == (childItem.itemType == "End"))
									selectedExprItem = childItem
									break
					else
						index += 1
			else
				indent += (parentExpr.MultiLine and 1 or 0)
				index or= #parentExpr
			valueType = switch parentExpr[1]
				when "Event"
					"Event"
				when "Condition"
					"Boolean"
				else
					"Action"
			with ExprChooser {
					valueType:valueType
					parentExpr:parentExpr
					owner:@
				}
				\slot "Result",(newExpr)->
					return unless newExpr
					table.insert parentExpr,index,newExpr
					addNewItem selectedExprItem,indent,parentExpr,index,false,after

		@insertBtn\slot "Tapped",insertNewExpr false
		@addBtn\slot "Tapped",insertNewExpr true

	createExprItem:(text,indent,expr,parentExpr,index)=>
		children = @triggerMenu.children
		lastItem = children and children.last or nil
		exprItem = with TriggerExpr {
				:indent
				:text
				:expr
				:parentExpr
				:index
				width:@triggerMenu.width
			}
			.position = lastItem and
				(lastItem.position-oVec2(0,lastItem.height/2+.height/2)) or
				oVec2(@triggerMenu.width/2,@triggerMenu.height-.height/2)+@offset
			\slot "Tapped",@changeExprItem if expr
		@triggerMenu\addChild exprItem
		{:width,:height} = @viewSize
		@viewSize = CCSize width,@height-exprItem.positionY+exprItem.height/2
		sleep! if @asyncLoad
		exprItem

	loadExpr:(arg)=>
		@exprData = switch type arg
			when "table" then arg
			when "string" then TriggerDef.SetExprMeta dofile arg
		@view\schedule once ->
			@triggerMenu\removeAllChildrenWithCleanup!
			@actionItem = nil
			@localVarItem = nil
			@locals = {}
			@localSet = {}
			@asyncLoad = true
			@nextExpr @exprData,0
			@asyncLoad = false
		@exprData

	isInActions:=>
		expr = @_selectedExprItem.expr
		parentExpr = @_selectedExprItem.parentExpr
		not parentExpr or not (parentExpr[1] == "Condition" or
			expr[1] == "Condition" or
			parentExpr[1] == "Event" or
			expr[1] == "Event")

	getPrevLocalVars:(varType)=>
		targetExpr = @_selectedExprItem.expr
		varSet = {}
		nextExpr = (expr)->
			return false unless "table" == type expr
			return true if expr == targetExpr
			switch expr[1]
				when "SetLocalNumber"
					if not varSet[expr[2][2]]
						varSet[expr[2][2]] = "Number"
			for i = 2,#expr
				if nextExpr expr[i]
					return true
			false
		nextExpr @actionItem.expr
		return for v,k in pairs varSet
			if k == varType then v
			else continue

	markLocalVarRename:(fromName,toName)=>
		@localVarFrom = fromName
		@localVarTo = toName

	renameLocalVar:(fromName,toName)=>
		nextExpr = (expr)->
			return false unless "table" == type expr
			renamed = false
			switch expr[1]
				when "Action"
					return false
				when "LocalName"
					if expr[2] == fromName
						expr[2] = toName
						renamed = true
			for i = 2,#expr
				if nextExpr expr[i]
					renamed = true
			renamed
		children = @triggerMenu.children
		startIndex = children\index(@actionItem)+1
		for item in *children[startIndex,]
			if item.expr and nextExpr item.expr
				item.text = tostring item.expr

	showEditButtons:(names)=>
		posX = @editMenu.width-30
		buttonSet = {@["#{name}Btn"],true for name in *names}
		for i = #@editMenu.children,1,-1
			child = @editMenu.children[i]
			if buttonSet[child]
				child.positionX = posX
				child.visible = true
				child.scaleX = 0
				child.scaleY = 0
				child\perform child.scale
				posX -= 50
			else
				child.visible = false

	enabled:property => @touchEnabled,
		(value)=>
			@touchEnabled = value
			@triggerMenu.enabled = value
			@editMenu.enabled = value
