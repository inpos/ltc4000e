local cabinet_digiline_rules = {
	--Around the bottom
	{x=1,y=0,z=0},
	{x=-1,y=0,z=0},
	{x=0,y=0,z=1},
	{x=0,y=0,z=-1},

	--Around the top
	{x=1,y=1,z=0},
	{x=-1,y=1,z=0},
	{x=0,y=1,z=1},
	{x=0,y=1,z=-1},

	--Out the top/bottom
	{x=0,y=2,z=0},
	{x=0,y=-1,z=0},

	--To a distributor 2m below
	{x=0,y=-2,z=0},
}

--Just enough of the touchscreen to enable it to work here
local function process_command(meta,data,msg)
	if msg.command == "clear" then
		data = {}
	elseif msg.command == "addimage" then
		for _,i in pairs({"X","Y","W","H"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		if not msg.texture_name or type(msg.texture_name) ~= "string" then
			return	
		end
		local field = {type="image",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,texture_name=minetest.formspec_escape(msg.texture_name)}
		table.insert(data,field)
	elseif msg.command == "addfield" then
		for _,i in pairs({"X","Y","W","H"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		for _,i in pairs({"name","label","default"}) do
			if not msg[i] or type(msg[i]) ~= "string" then
				return
			end
		end
		local field = {type="field",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,name=minetest.formspec_escape(msg.name),label=minetest.formspec_escape(msg.label),default=minetest.formspec_escape(msg.default)}
		table.insert(data,field)
	elseif msg.command == "addpwdfield" then
		for _,i in pairs({"X","Y","W","H"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		for _,i in pairs({"name","label"}) do
			if not msg[i] or type(msg[i]) ~= "string" then
				return
			end
		end
		local field = {type="pwdfield",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,name=minetest.formspec_escape(msg.name),label=minetest.formspec_escape(msg.label)}
		table.insert(data,field)
	elseif msg.command == "addtextarea" then
		for _,i in pairs({"X","Y","W","H"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		for _,i in pairs({"name","label","default"}) do
			if not msg[i] or type(msg[i]) ~= "string" then
				return
			end
		end
		local field = {type="textarea",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,name=minetest.formspec_escape(msg.name),label=minetest.formspec_escape(msg.label),default=minetest.formspec_escape(msg.default)}
		table.insert(data,field)
	elseif msg.command == "addlabel" then
		for _,i in pairs({"X","Y"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		if not msg.label or type(msg.label) ~= "string" then
			return	
		end
		local field = {type="label",X=msg.X,Y=msg.Y,label=minetest.formspec_escape(msg.label)}
		table.insert(data,field)
	elseif msg.command == "addvertlabel" then
		for _,i in pairs({"X","Y"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		if not msg.label or type(msg.label) ~= "string" then
			return	
		end
		local field = {type="vertlabel",X=msg.X,Y=msg.Y,label=minetest.formspec_escape(msg.label)}
		table.insert(data,field)
	elseif msg.command == "addbutton" then
		for _,i in pairs({"X","Y","W","H"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		for _,i in pairs({"name","label"}) do
			if not msg[i] or type(msg[i]) ~= "string" then
				return
			end
		end
		local field = {type="button",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,name=minetest.formspec_escape(msg.name),label=minetest.formspec_escape(msg.label)}
		table.insert(data,field)
	elseif msg.command == "addbutton_exit" then
		for _,i in pairs({"X","Y","W","H"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		for _,i in pairs({"name","label"}) do
			if not msg[i] or type(msg[i]) ~= "string" then
				return
			end
		end
		local field = {type="button_exit",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,name=minetest.formspec_escape(msg.name),label=minetest.formspec_escape(msg.label)}
		table.insert(data,field)
	elseif msg.command == "addimage_button" then
		for _,i in pairs({"X","Y","W","H"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		for _,i in pairs({"image","name","label"}) do
			if not msg[i] or type(msg[i]) ~= "string" then
				return
			end
		end
		local field = {type="image_button",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,image=minetest.formspec_escape(msg.image),name=minetest.formspec_escape(msg.name),label=minetest.formspec_escape(msg.label)}
		table.insert(data,field)
	elseif msg.command == "addimage_button_exit" then
		for _,i in pairs({"X","Y","W","H"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		for _,i in pairs({"image","name","label"}) do
			if not msg[i] or type(msg[i]) ~= "string" then
				return
			end
		end
		local field = {type="image_button_exit",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,image=minetest.formspec_escape(msg.image),name=minetest.formspec_escape(msg.name),label=minetest.formspec_escape(msg.label)}
		table.insert(data,field)
	elseif msg.command == "adddropdown" then
		for _,i in pairs({"X","Y","W","H","selected_id"}) do
			if not msg[i] or type(msg[i]) ~= "number" then
				return
			end
		end
		if not msg.name or type(msg.name) ~= "string" then
			return
		end
		if not msg.choices or type(msg.choices) ~= "table" or #msg.choices < 1 then
			return
		end
		local field = {type="dropdown",X=msg.X,Y=msg.Y,W=msg.W,H=msg.H,name=msg.name,selected_id=msg.selected_id,choices=msg.choices}
		table.insert(data,field)
	elseif msg.command == "lock" then
		meta:set_int("locked",1)
	elseif msg.command == "unlock" then
		meta:set_int("locked",0)
	end
	return data
end

local function update_ts_formspec(pos,data)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)
	if node.name == "ltc4000e:nema_bottom" then
		meta:set_string("formspec","")
		return
	end
	local fs = "size[12,8]"..
		"background[0,0;0,0;ltc4000e_formspec_bg.png;true]"
	for _,field in pairs(data) do
		if field.type == "image" then
			fs = fs..string.format("image[%s,%s;%s,%s;%s]",field.X,field.Y,field.W,field.H,field.texture_name)
		elseif field.type == "field" then
			fs = fs..string.format("field[%s,%s;%s,%s;%s;%s;%s]",field.X,field.Y,field.W,field.H,field.name,field.label,field.default)
		elseif field.type == "pwdfield" then
			fs = fs..string.format("pwdfield[%s,%s;%s,%s;%s;%s]",field.X,field.Y,field.W,field.H,field.name,field.label)
		elseif field.type == "textarea" then
			fs = fs..string.format("textarea[%s,%s;%s,%s;%s;%s;%s]",field.X,field.Y,field.W,field.H,field.name,field.label,field.default)
		elseif field.type == "label" then
			fs = fs..string.format("label[%s,%s;%s]",field.X,field.Y,field.label)
		elseif field.type == "vertlabel" then
			fs = fs..string.format("vertlabel[%s,%s;%s]",field.X,field.Y,field.label)
		elseif field.type == "button" then
			fs = fs..string.format("button[%s,%s;%s,%s;%s;%s]",field.X,field.Y,field.W,field.H,field.name,field.label)
		elseif field.type == "button_exit" then
			fs = fs..string.format("button_exit[%s,%s;%s,%s;%s;%s]",field.X,field.Y,field.W,field.H,field.name,field.label)
		elseif field.type == "image_button" then
			fs = fs..string.format("image_button[%s,%s;%s,%s;%s;%s;%s]",field.X,field.Y,field.W,field.H,field.image,field.name,field.label)
		elseif field.type == "image_button_exit" then
			fs = fs..string.format("image_button_exit[%s,%s;%s,%s;%s;%s;%s]",field.X,field.Y,field.W,field.H,field.image,field.name,field.label)
		elseif field.type == "dropdown" then
			local choices = ""
			for _,i in ipairs(field.choices) do
				if type(i) == "string" then
					choices = choices..minetest.formspec_escape(i)..","
				end
			end
			choices = string.sub(choices,1,-2)
			fs = fs..string.format("dropdown[%s,%s;%s,%s;%s;%s;%s]",field.X,field.Y,field.W,field.H,field.name,choices,field.selected_id)
		end
	end
	meta:set_string("formspec",fs)
end

local function ts_on_digiline_receive(pos,msg)
	local meta = minetest.get_meta(pos)
	if type(msg) ~= "table" then return end
	local data = minetest.deserialize(meta:get_string("data")) or {}
	if msg.command then
		data = process_command(meta,data,msg)
	else
		for _,i in ipairs(msg) do
			if i.command then
				data = process_command(meta,data,i) or data
			end
		end
	end
	meta:set_string("data",minetest.serialize(data))
	update_ts_formspec(pos,data)
end

--Interrupt node timer stuff
local function getnextinterrupt(interrupts)
	local nextint = 0
	for k,v in pairs(interrupts) do
		if nextint == 0 or v < nextint then
			nextint = v
		end
	end
	if nextint ~= 0 then return(nextint) end
end

local function getcurrentinterrupts(interrupts)
	local current = {}
	for k,v in pairs(interrupts) do
		if v <= os.time() then
			table.insert(current,k)
		end
	end
	return(current)
end

local function setinterrupt(pos,time,iid)
	local meta = minetest.get_meta(pos)
	local timer = minetest.get_node_timer(pos)
	local interrupts = minetest.deserialize(meta:get_string("interrupts")) or {}
	if time == nil then
		interrupts[iid] = nil
	else
		interrupts[iid] = os.time()+time
	end
	local nextint = getnextinterrupt(interrupts)
	if nextint then
		timer:start(nextint-os.time())
	end
	meta:set_string("interrupts",minetest.serialize(interrupts))
end

--Load the (mostly unmodified) firmware
local fw = loadfile(minetest.get_modpath("ltc4000e")..DIR_DELIM.."fw.lua")

local function run(pos,event)
	--Determine controller type
	local node = minetest.get_node(pos)
	local is_cabinet = (node.name == "ltc4000e:nema_bottom" or node.name == "ltc4000e:nema_bottom_open")

	--Initialize environment
	local context = {}
	local meta = minetest.get_meta(pos)
	context.mem = minetest.deserialize(meta:get_string("mem")) or {}
	context.event = event
	context.string = string
	context.table = table
	context.math = math
	context.pairs = pairs
	context.ipairs = ipairs
	context.tostring = tostring
	context.tonumber = tonumber
	context.type = type
	context.print = print
	context.os = {}
	for k,v in pairs(os) do
		context.os[k] = v
	end

	function context.os.datetable()
		return(os.date("*t",os.time()))
	end

	if is_cabinet then
		function context.digiline_send(channel,msg)
			if channel == "touchscreen" then
				--Touchscreen is integrated into the chip
				ts_on_digiline_receive(pos,msg)
			else
				--Not an integrated peripheral, so send the message
				digiline:receptor_send(pos,cabinet_digiline_rules,channel,msg)
			end
		end
	else
		function context.digiline_send(channel,msg)
			if channel == "touchscreen" then
				--Touchscreen is integrated into the chip
				ts_on_digiline_receive(pos,msg)
			else
				--Not an integrated peripheral, so send the message
				digiline:receptor_send(pos,digiline.rules.default,channel,msg)
			end
		end
	end

	function context.interrupt(time,iid)
		--Enforce a minimum interrupt time of one second
		if time ~= nil then time = math.max(time,1) end
		setinterrupt(pos,time,iid)
	end

	--This is where the magic happens...
	setfenv(fw,context)

	--Run code
	local success,err = pcall(fw)
	if not success then
		print("Error in LTC-4000E execution, aborting: "..err)
		return
	end

	--Save memory after execution
	meta:set_string("mem",minetest.serialize(context.mem))
end

local function oninterrupt(pos)
	local meta = minetest.get_meta(pos)
	local timer = minetest.get_node_timer(pos)
	local interrupts = minetest.deserialize(meta:get_string("interrupts")) or {}
	local current = getcurrentinterrupts(interrupts)
	for _,i in ipairs(current) do
		interrupts[i] = nil
		local event = {}
		event.type = "interrupt"
		event.iid = i
		run(pos,event)
	end
	local interrupts = minetest.deserialize(meta:get_string("interrupts")) or {} --Reload as it may have changed
	for _,i in ipairs(current) do
		if interrupts[i] and interrupts[i] <= os.time() then
			interrupts[i] = nil
		end
	end
	local nextint = getnextinterrupt(interrupts)
	if nextint then
		timer:start(nextint-os.time())
	else
		timer:stop()
	end
	meta:set_string("interrupts",minetest.serialize(interrupts))
end

local function ts_on_receive_fields(pos,formname,fields,sender)
	local meta = minetest.get_meta(pos)
	local playername = sender:get_player_name()
	local locked = meta:get_int("locked") == 1
	local can_bypass = minetest.check_player_privs(playername,{protection_bypass=true})
	local is_protected = minetest.is_protected(pos,playername)
	if (locked and is_protected) and not can_bypass then
		minetest.record_protection_violation(pos,playername)
		minetest.chat_send_player(playername,"You are not authorized to use this controller.")
		return
	end
	local event = {}
	event.type = "digiline"
	event.channel = "touchscreen"
	event.msg = fields
	run(pos,event)
end

local polemount_nodebox = {
	{ -0.35, -0.45, 0.35, 0.35, 0.45, 0.85 }
}


minetest.register_node("ltc4000e:polemount", {
	tiles = {
		"ltc4000e_sides.png",
		"ltc4000e_sides.png",
		"ltc4000e_sides.png",
		"ltc4000e_sides.png",
		"ltc4000e_sides.png",
		"ltc4000e_polemount_front.png",
	},
	description = "LTC-4000E Traffic Signal Controller (Pole-Mount)",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	groups = {dig_immediate=2},
	sounds = default.node_sound_metal_defaults(),
	on_construct = function(pos)
		local event = {type="program"}
		run(pos,event)
	end,
	on_timer = oninterrupt,
	node_box = {
		type = "fixed",
		fixed = polemount_nodebox
    	},
	selection_box = {
		type = "fixed",
		fixed = polemount_nodebox
    	},
	on_receive_fields = ts_on_receive_fields,
	digiline = 
	{
		receptor = {},
		effector = {
			action = function(pos,_,channel,msg)
					local event = {}
					event.type = "digiline"
					event.channel = channel
					event.msg = msg
					run(pos,event)
				end
		},
	},
})
minetest.register_alias("ltc4000e:controller","ltc4000e:polemount")

local bottom_nodebox = {
	{ -0.5, -0.5, -0.5, 0.5, -0.2, 0.5 }, --Bottom slab
	{ -0.4, -0.2, -0.3, 0.4, 0.5, 0.3 }, --Main cabinet
	{ -0.4, -0.157, -0.35, 0.4, 0.5, -0.3 }, --Door
}

local top_nodebox = {
	{ -0.4, -0.5, -0.3, 0.4, 0.3, 0.3 }, --Main cabinet
	{ -0.4, -0.5, -0.35, 0.4, 0.157, -0.3 }, --Door
	{ -0.4, 0.2, -0.4, 0.4, 0.3, -0.3 }, --Overhang
}

minetest.register_node("ltc4000e:nema_bottom", {
	tiles = {
		"ltc4000e_cabinet_bottom_topbottom.png",
		"ltc4000e_cabinet_bottom_topbottom.png",
		"ltc4000e_cabinet_bottom_right.png",
		"ltc4000e_cabinet_bottom_left.png",
		"ltc4000e_cabinet_bottom_back.png",
		"ltc4000e_cabinet_bottom_front.png",
	},
	description = "LTC-4000E Traffic Signal Controller (NEMA Cabinet)",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	inventory_image = "ltc4000e_cabinet_inv.png",
	wield_image = "ltc4000e_cabinet_inv.png",
	groups = {dig_immediate=2},
	sounds = default.node_sound_metal_defaults(),
	after_place_node = function(pos,placer)
		local node = minetest.get_node(pos)
		local toppos = {x=pos.x,y=pos.y + 1,z=pos.z}
		local topnode = minetest.get_node(toppos)
		local placername = placer:get_player_name()
		if topnode.name ~= "air" then
			if placer:is_player() then
				minetest.chat_send_player(placername,"Can't place cabinet - no room for the top half!")
			end
			minetest.set_node(pos,{name="air"})
			return true
		end
		if minetest.is_protected(toppos,placername) and not minetest.check_player_privs(placername,{protection_bypass=true}) then
			if placer:is_player() then
				minetest.chat_send_player(placername,"Can't place cabinet - top half is protected!")
				minetest.record_protection_violation(toppos,placername)
			end
			minetest.set_node(pos,{name="air"})
			return true
		end
		node.name = "ltc4000e:nema_top"
		minetest.set_node(toppos,node)
	end,
	on_construct = function(pos)
		local event = {type="program"}
		run(pos,event)
	end,
	on_destruct = function(pos)
		pos.y = pos.y + 1
		if minetest.get_node(pos).name == "ltc4000e:nema_top" then
			minetest.set_node(pos,{name="air"})
		end
	end,
	on_rotate = function(pos,node,user,mode,new_param2)
		if not screwdriver then
			return false
		end
		local ret = screwdriver.rotate_simple(pos,node,user,mode,new_param2)
		minetest.after(0,function(pos)
			local newnode = minetest.get_node(pos)
			local param2 = newnode.param2
			pos.y = pos.y + 1
			local topnode = minetest.get_node(pos)
			topnode.param2 = param2
			minetest.set_node(pos,topnode)
		end,pos)
		return ret
	end,
	on_timer = oninterrupt,
	on_punch = function(pos,node,puncher)
		if not puncher:is_player() then
			return
		end
		local name = puncher:get_player_name()
		if minetest.is_protected(pos,name) and not minetest.check_player_privs(name,{protection_bypass=true}) then
			minetest.chat_send_player(name,"Can't open cabinet - cabinet is locked.")
			minetest.record_protection_violation(pos,name)
			return
		end
		local vpos = vector.new(pos.x,pos.y,pos.z)
		local backdir = minetest.facedir_to_dir(node.param2)
		local frontpos = vector.add(vpos,vector.multiply(backdir,-1))
		local fronttoppos = vector.add(frontpos,vector.new(0,1,0))
		local frontnode = minetest.get_node(frontpos)
		local fronttopnode = minetest.get_node(fronttoppos)
		if frontnode.name ~= "air" or fronttopnode.name ~= "air" then
			minetest.chat_send_player(name,"Can't open cabinet - something is in the way")
			return
		end
		minetest.set_node(frontpos,{name="ltc4000e:door_bottom",param2=node.param2})
		minetest.set_node(fronttoppos,{name="ltc4000e:door_top",param2=node.param2})
		node.name = "ltc4000e:nema_bottom_open"
		minetest.swap_node(pos,node)
		ts_on_digiline_receive(pos,{})
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
		node.name = "ltc4000e:nema_top_open"
		minetest.swap_node(pos,node)
		minetest.sound_play("doors_steel_door_open",{
			pos = pos,
			gain = 0.5,
			max_hear_distance = 10
		})
	end,
	node_box = {
		type = "fixed",
		fixed = bottom_nodebox
    	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,-0.2,0.5},
			{-0.4,-0.2,-0.4,0.4,1.3,0.3},
		}
    	},
	on_receive_fields = ts_on_receive_fields,
	digiline = 
	{
		receptor = {},
		wire = {
			rules = cabinet_digiline_rules,
		},
		effector = {
			action = function(pos,_,channel,msg)
					local event = {}
					event.type = "digiline"
					event.channel = channel
					event.msg = msg
					run(pos,event)
				end
		},
	},
})

minetest.register_node("ltc4000e:nema_top", {
	tiles = {
		"ltc4000e_sides.png",
		"ltc4000e_sides.png",
		"ltc4000e_cabinet_top_right.png",
		"ltc4000e_cabinet_top_left.png",
		"ltc4000e_sides.png",
		"ltc4000e_cabinet_top_front.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = top_nodebox
    	},
	selection_box = {
		type = "fixed",
		fixed = {0,0,0,0,0,0}
    	},
	groups = {not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults()
})

local bottom_open_nodebox = {
	{ -0.5, -0.5, -0.5, 0.5, -0.2, 0.5 }, --Bottom slab
	{ -0.4, -0.2, -0.3, 0.4, 0.5, 0.3 }, --Main cabinet
	{ -0.4, -0.157, -0.3, -0.35, 0.5, -0.5 }, --Door
}

local top_open_nodebox = {
	{ -0.4, -0.5, -0.3, 0.4, 0.3, 0.3 }, --Main cabinet
	{ -0.4, 0.2, -0.4, 0.4, 0.3, -0.3 }, --Overhang
	{ -0.4, -0.5, -0.3, -0.35, 0.157, -0.5 }, --Door
}

local door_bottom_nodebox = {
	{ -0.4, -0.157, 0.5, -0.35, 0.5, -0.1 }, --Door
}

local door_top_nodebox = {
	{ -0.4, -0.5, 0.5, -0.35, 0.157, -0.1 }, --Door
}

minetest.register_node("ltc4000e:nema_bottom_open", {
	tiles = {
		"ltc4000e_cabinet_bottom_topbottom.png",
		"ltc4000e_cabinet_bottom_topbottom.png",
		"ltc4000e_cabinet_bottom_right_open.png",
		"ltc4000e_cabinet_bottom_left_open.png",
		"ltc4000e_cabinet_bottom_back.png",
		{
			name="ltc4000e_cabinet_bottom_inside.png",
			animation={type="vertical_frames", aspect_w=64, aspect_h=64, length=1.2},
		}
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	drop = "ltc4000e:nema_bottom",
	inventory_image = "ltc4000e_cabinet_inv.png",
	wield_image = "ltc4000e_cabinet_inv.png",
	groups = {dig_immediate=2,not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults(),
	on_destruct = function(pos)
		local node = minetest.get_node(pos)
		local vpos = vector.new(pos.x,pos.y,pos.z)
		pos.y = pos.y + 1
		if minetest.get_node(pos).name == "ltc4000e:nema_top_open" then
			minetest.set_node(pos,{name="air"})
		end
		local backdir = minetest.facedir_to_dir(node.param2)
		local frontpos = vector.add(vpos,vector.multiply(backdir,-1))
		local fronttoppos = vector.add(frontpos,vector.new(0,1,0))
		minetest.set_node(frontpos,{name="air"})
		minetest.set_node(fronttoppos,{name="air"})
	end,
	on_rotate = false,
	on_timer = oninterrupt,
	on_punch = function(pos,node,puncher)
		if not puncher:is_player() then
			return
		end
		local name = puncher:get_player_name()
		local vpos = vector.new(pos.x,pos.y,pos.z)
		local backdir = minetest.facedir_to_dir(node.param2)
		local frontpos = vector.add(vpos,vector.multiply(backdir,-1))
		local fronttoppos = vector.add(frontpos,vector.new(0,1,0))
		local frontnode = minetest.get_node(frontpos)
		local fronttopnode = minetest.get_node(fronttoppos)
		minetest.set_node(frontpos,{name="air"})
		minetest.set_node(fronttoppos,{name="air"})
		node.name = "ltc4000e:nema_bottom"
		minetest.swap_node(pos,node)
		ts_on_digiline_receive(pos,{})
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
		node.name = "ltc4000e:nema_top"
		minetest.swap_node(pos,node)
		minetest.sound_play("doors_steel_door_close",{
			pos = pos,
			gain = 0.5,
			max_hear_distance = 10
		})
	end,
	node_box = {
		type = "fixed",
		fixed = bottom_open_nodebox
    	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5,-0.5,-0.5,0.5,-0.2,0.5},
			{-0.4,-0.2,-0.4,0.4,1.3,0.3},
		}
    	},
	on_receive_fields = ts_on_receive_fields,
	digiline = 
	{
		receptor = {},
		wire = {
			rules = cabinet_digiline_rules,
		},
		effector = {
			action = function(pos,_,channel,msg)
					local event = {}
					event.type = "digiline"
					event.channel = channel
					event.msg = msg
					run(pos,event)
				end
		},
	},
})

minetest.register_node("ltc4000e:nema_top_open", {
	tiles = {
		"ltc4000e_sides.png",
		"ltc4000e_sides.png",
		"ltc4000e_cabinet_top_right_open.png",
		"ltc4000e_cabinet_top_left_open.png",
		"ltc4000e_sides.png",
		"ltc4000e_cabinet_top_inside.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = top_open_nodebox
    	},
	selection_box = {
		type = "fixed",
		fixed = {0,0,0,0,0,0}
    	},
	groups = {not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults()
})

minetest.register_node("ltc4000e:door_bottom", {
	tiles = {
		"ltc4000e_sides.png",
		"ltc4000e_sides.png",
		"ltc4000e_cabinet_top_right.png",
		"ltc4000e_cabinet_door_bottom_outside.png",
		"ltc4000e_sides.png",
		"ltc4000e_cabinet_top_front.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = door_bottom_nodebox
    	},
	selection_box = {
		type = "fixed",
		fixed = {0,0,0,0,0,0}
    	},
	groups = {not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults()
})

minetest.register_node("ltc4000e:door_top", {
	tiles = {
		"ltc4000e_sides.png",
		"ltc4000e_sides.png",
		"ltc4000e_cabinet_top_right.png",
		"ltc4000e_cabinet_door_top_outside.png",
		"ltc4000e_sides.png",
		"ltc4000e_cabinet_top_front.png",
	},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = door_top_nodebox
    	},
	selection_box = {
		type = "fixed",
		fixed = {0,0,0,0,0,0}
    	},
	groups = {not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults()
})

--Make sure lights don't "stall" if unloaded and not yet converted to node timers
minetest.register_lbm({
	label = "Restart LTC-4000E timers",
	name = "ltc4000e:restart_timers",
	nodenames = {"ltc4000e:polemount","ltc4000e:nema_bottom","ltc4000e:nema_bottom_open"},
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local mem = minetest.deserialize(meta:get_string("mem"))
		if mem and mem.cycle then
			local event = {}
			event.type = "interrupt"
			event.iid = "tick"
			run(pos,event)
		end
	end
})

--Crafting recipes
minetest.register_craft({
	output = "ltc4000e:polemount",
	recipe = {
		{"default:steelblock","streets:bigpole","default:steelblock"},
		{"default:steelblock","mesecons_luacontroller:luacontroller0000","default:steelblock"},
		{"default:steelblock","digistuff:touchscreen","default:steelblock"},
	}
})

minetest.register_craft({
	output = "ltc4000e:polemount",
	recipe = {
		{"moreblocks:slab_steelblock_1","streets:bigpole","moreblocks:slab_steelblock_1"},
		{"moreblocks:slab_steelblock_1","mesecons_luacontroller:luacontroller0000","moreblocks:slab_steelblock_1"},
		{"moreblocks:slab_steelblock_1","digistuff:touchscreen","moreblocks:slab_steelblock_1"},
	}
})

minetest.register_craft({
	output = "ltc4000e:nema_bottom",
	recipe = {
		{"default:steelblock","default:steelblock","default:steelblock"},
		{"default:steelblock","ltc4000e:polemount","default:steelblock"},
		{"default:steelblock","doors:door_steel","default:steelblock"},
	}
})

minetest.register_craft({
	output = "ltc4000e:nema_bottom",
	recipe = {
		{"moreblocks:slab_steelblock_1","moreblocks:slab_steelblock_1","moreblocks:slab_steelblock_1"},
		{"moreblocks:slab_steelblock_1","ltc4000e:polemount","moreblocks:slab_steelblock_1"},
		{"moreblocks:slab_steelblock_1","doors:door_steel","moreblocks:slab_steelblock_1"},
	}
})
