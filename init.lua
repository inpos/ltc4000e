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
	local fs = "size[10,8]"..
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

--Load the (mostly unmodified) firmware
local fw = loadfile(minetest.get_modpath("ltc4000e")..DIR_DELIM.."fw.lua")

local function run(pos,event)
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

	function context.digiline_send(channel,msg)
		if channel == "touchscreen" then
			--Touchscreen is integrated into the chip
			ts_on_digiline_receive(pos,msg)
		else
			--Not an integrated peripheral, so send the message
			digiline:receptor_send(pos,digiline.rules.default,channel,msg)
		end
	end

	function context.interrupt(time,iid)
		if iid == "gapout" then
			--This one can have the time changed on-the-fly, so it has to be done with node timers
			local timer = minetest.get_node_timer(pos)
			if time then
				timer:start(time)
			else
				timer:stop()
			end
		else
			local event = {}
			event.type = "interrupt"
			event.iid = iid
			minetest.after(time,run,pos,event)
		end
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

local nodebox = {
	{ -0.35, -0.45, 0.35, 0.35, 0.45, 0.85 }
}


minetest.register_node("ltc4000e:controller", {
	tiles = {
		"ltc4000e_cabinet_sides.png",
		"ltc4000e_cabinet_sides.png",
		"ltc4000e_cabinet_sides.png",
		"ltc4000e_cabinet_sides.png",
		"ltc4000e_cabinet_sides.png",
		"ltc4000e_cabinet_front.png",
	},
	description = "LTC-4000E Traffic Signal Controller",
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	groups = {dig_immediate=2},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local event = {type="program"}
		run(pos,event)
	end,
	on_timer = function(pos)
		local event = {}
		event.type = "interrupt"
		event.iid = "gapout"
		run(pos,event)
	end,
	node_box = {
		type = "fixed",
		fixed = nodebox
    	},
	selection_box = {
		type = "fixed",
		fixed = nodebox
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

--Make sure lights don't "stall" if unloaded
minetest.register_lbm({
	label = "Restart LTC-4000E timers",
	name = "ltc4000e:restart_timers",
	nodenames = {"ltc4000e:controller"},
	run_at_every_load = true,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		local mem = minetest.deserialize(meta:get_string("mem"))
		if mem.cycle then
			local event = {}
			event.type = "interrupt"
			event.iid = "tick"
			run(pos,event)
		end
	end
})

--Crafting recipe
minetest.register_craft({
	output = "ltc4000e:controller",
	recipe = {
		{"default:steelblock","streets:bigpole","default:steelblock"},
		{"default:steelblock","mesecons_luacontroller:luacontroller0000","default:steelblock"},
		{"default:steelblock","digistuff:touchscreen","default:steelblock"},
	}
})

minetest.register_craft({
	output = "ltc4000e:controller",
	recipe = {
		{"moreblocks:slab_steelblock_1","streets:bigpole","moreblocks:slab_steelblock_1"},
		{"moreblocks:slab_steelblock_1","mesecons_luacontroller:luacontroller0000","moreblocks:slab_steelblock_1"},
		{"moreblocks:slab_steelblock_1","digistuff:touchscreen","moreblocks:slab_steelblock_1"},
	}
})
