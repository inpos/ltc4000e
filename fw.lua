--LTC-4000E Firmware
--A product of Advanced Mesecons Devices, a Cheapie Systems company
--This is free and unencumbered software released into the public domain.
--See http://unlicense.org/ for more information

--Lookup tables for human-readable strings and such
lttypes = {"Permissive","Protected","Yellow Arrow Prot/Perm","Circular Green Prot/Perm"}
pedtypes = {"Unsignalized","Signalized"}
signaltypes = {"Streets 1","Roads","Streets 2"}
pedbuttontypes = {"Normal","TrafficNeXt Compatibility"}
shortphases = {"O","G","R","Y","FR","FY","FG","RY"} -- Green/red switched for, uh, reasons
phases = {O = "Off",R = "Red",Y = "Yellow",G = "Green",RY = "RedYellow",FR = "FlashRed",FY = "FlashYellow",FG = "FlashGreen"}
monitortypes = {"Straight","Left Turn","Pedestrian"}
modes = {"Sensor","Timer","Phase Lock"}
panellock = {"Unlocked","Locked"}
logmodes = {"Quiet","Normal","Verbose"}
pedrecallmodes = {"Never","Timer Only","Always"}
ltrecallmodes = {"No","Yes"}

--Only accept digilines signals on the necessary channels
local event_ok = false
if event.type ~= "digiline" then event_ok = true end
if (not event_ok) and (string.find(event.channel,"detector") or string.find(event.channel,"preempt")) then event_ok = true end
if (not event_ok) and (event.channel == "touchscreen") then event_ok = true end
if not event_ok then
	--Digilines signal on unimportant channel, stop execution
	return
end

--Used for reverse lookups
function pivot(table)
	local out = {}
	for k,v in pairs(table) do
		out[v] = k
	end
	return(out)
end

--Phase setter thing
function setlight(light,phase)
	mem.currentphase[light] = phase
end

--Log filter/formatter
function log(desc,verboseonly)
	if mem.logmode ~= 1 and (mem.logmode == 3 or not verboseonly) then
		print("[LTC-4000E @ "..mem.name.."] "..desc)
	end
end

--Fault logger
function logfault(desc,fatal)
	if fatal then mem.phaselocked = true end
	log(string.format("%s FAULT: ",(fatal and "FATAL" or "Non-fatal"))..desc,false)
	local date = os.datetable()
	local time = string.format(" - %04u-%02u-%02u %02u:%02u:%02u",date.year,date.month,date.day,date.hour,date.min,date.sec)
	table.insert(mem.faultlog,1,desc..time)
end

--Checks if the schedule is currently active
function isscheduled()
	local hour = os.datetable().hour
	if mem.schedstart < mem.schedend then
		--Active during the day
		return(hour >= mem.schedstart and hour < mem.schedend)
	elseif mem.schedstart > mem.schedend then
		--Active during the night
		return(hour >= mem.schedstart or hour < mem.schedend)
	else
		--Disabled
		return(false)
	end
end

--Default parameters
if event.type == "program" then
	mem.menu = "run"
	mem.monitor = 1
	mem.monflash = false
	mem.stats = {a = 0,b = 0,c = 0,d = 0,at = 0,bt = 0,ct = 0,dt = 0,ap = 0,bp = 0,cp = 0,dp = 0,cycles = 0,lastreset = os.time()}
	mem.det = {}
	mem.busy = false
	mem.preempt = nil
	mem.cycle = nil
	mem.currentphase = {a = "G",b = "R",c = "G",d = "R",at = "R",bt = "R",ct = "R",dt = "R",ap = "R",bp = "R",cp = "R",dp = "R"}
	mem.phaselock = {a = "FR",b = "FR",c = "FR",d = "FR",at = "FR",bt = "FR",ct = "FR",dt = "FR",ap = "O",bp = "O",cp = "O",dp = "O"}
	mem.phaselocked = false
	mem.faultlog = {}
	log("Chip programmed",true)
end

if not mem.schedstart then mem.schedstart = 0 end
if not mem.schedend then mem.schedend = 0 end
if not mem.normalmode then
	if mem.phaselocked then
		mem.normalmode = 3
	else
		mem.normalmode = 1
	end
end
if not mem.ltrecallmode then mem.ltrecallmode = 2 end
if not mem.pedrecallmode then mem.pedrecallmode = 2 end
if not mem.schedmode then mem.schedmode = 3 end
if not mem.ltatype then mem.ltatype = 1 end
if not mem.ltbtype then mem.ltbtype = 1 end
if not mem.ltctype then mem.ltctype = 1 end
if not mem.ltdtype then mem.ltdtype = 1 end
if not mem.pedatype then mem.pedatype = 1 end
if not mem.pedbtype then mem.pedbtype = 1 end
if not mem.pedctype then mem.pedctype = 1 end
if not mem.peddtype then mem.peddtype = 1 end
if not mem.signaltype then mem.signaltype = 2 end
if not mem.pedbuttontype then mem.pedbuttontype = 1 end
if not mem.allreda then mem.allreda = 2 end
if not mem.allredb then mem.allredb = 2 end
if not mem.yellowa then mem.yellowa = 3 end
if not mem.yellowb then mem.yellowb = 3 end
if not mem.minsidegreen then mem.minsidegreen = (mem.sidegreen or 7) end
if not mem.gapout then mem.gapout = 3 end
if not mem.maxsidegreen then mem.maxsidegreen = 20 end
if not mem.mindwell then mem.mindwell = 10 end
if not mem.pedwarn then mem.pedwarn = 7 end
if not mem.sideped then mem.sideped = 5 end
if not mem.llturn then mem.llturn = 4 end
if not mem.name then mem.name = "Unnamed Intersection" end
if not mem.logmode then mem.logmode = 2 end
if not mem.lock then mem.lock = 2 end

--Handle special modes
was_phaselocked = mem.phaselocked
was_timed = mem.timed
mem.phaselocked = (isscheduled() and mem.schedmode == 3) or (not isscheduled() and mem.normalmode == 3)
mem.timed = (isscheduled() and mem.schedmode == 2) or (not isscheduled() and mem.normalmode == 2)
if was_phaselocked and not mem.phaselocked then
	mem.currentphase = {a = "G",b = "R",c = "G",d = "R",at = "R",bt = "R",ct = "R",dt = "R",ap = "R",bp = "R",cp = "R",dp = "R"}
	mem.cycle = "mindwell"
	mem.busy = true
	interrupt(0,"tick")
end
if mem.timed then
	mem.det.b = true
	mem.det.d = true
	if mem.ltrecallmode == 2 then
		mem.det.at = true
		mem.det.bt = true
		mem.det.ct = true
		mem.det.dt = true
	end
	if mem.pedrecallmode == 2 or mem.pedrecallmode == 3 then
		mem.det.ap = true
		mem.det.bp = true
		mem.det.cp = true
		mem.det.dp = true
	end
elseif was_timed then
	mem.det = {}
end

--Detector signal handling
if (not mem.phaselocked and not mem.preempt) and event.type == "digiline" and string.sub(event.channel,1,9) == "detector_" and not mem.stoptime then
	local detname = string.sub(event.channel,10)
	if mem.stats[detname] then
		mem.stats[detname] = mem.stats[detname] + 1
	end
	if detname == "a" or detname == "c" then
		log("Ignoring stats-only detector "..detname,true)
	elseif (detname == "at" and mem.ltatype == 1) then
		logfault("AT disabled but detector present",false)
	elseif (detname == "bt" and mem.ltbtype == 1) then
		logfault("BT disabled but detector present",false)
	elseif (detname == "ct" and mem.ltctype == 1) then
		logfault("CT disabled but detector present",false)
	elseif (detname == "dt" and mem.ltdtype == 1) then
		logfault("DT disabled but detector present",false)
	elseif (detname == "ap" and mem.pedatype == 1) then
		logfault("AP disabled but detector present",false)
	elseif (detname == "bp" and mem.pedbtype == 1) then
		logfault("BP disabled but detector present",false)
	elseif (detname == "cp" and mem.pedctype == 1) then
		logfault("CP disabled but detector present",false)
	elseif (detname == "dp" and mem.peddtype == 1) then
		logfault("DP disabled but detector present",false)
	else
		log("Detector "..detname.." activated",true)
		mem.det[detname] = true
		if (detname == "b" or detname == "d") and mem.pedbtype == 2 and mem.pedrecallmode == 3 then
			log("Performing pedestrian recall on ap and cp",true)
			mem.det.ap = true
			mem.det.cp = true
		end
	end
end

if event.type == "digiline" and mem.pedbuttontype == 2 and event.channel == "pedbutton" and not mem.stoptime then
	if event.msg == "main" then
		log("Emulating detector_ap/cp for TrafficNeXt compatibility",true)
		mem.det.ap = true
		mem.det.cp = true
	elseif event.msg == "side" then
		log("Emulating detector_bp/dp for TrafficNeXt compatibility",true)
		mem.det.bp = true
		mem.det.dp = true
	else
		logfault("Unrecognized pedbutton type "..event.msg,false)
	end
end

--Volume Density Logic
if event.type == "interrupt" and (event.iid == "gapout" or event.iid == "maxgreen") and (mem.cycle == "straight2.5" or mem.cycle == "straight3") then
	if mem.cycle == "straight2.5" or (mem.currentphase.ap ~= "FR" and mem.currentphase.cp ~= "FR") then
		if event.iid == "gapout" then
			log("Gapped out",true)
		elseif event.iid == "maxgreen" then
			log("Reached maximum green",true)
		end
		--Either gapped out or reached max green, go to next step
		interrupt(nil,"gapout")
		interrupt(nil,"maxgreen")
		interrupt(0,"tick")
	end
end

if (event.channel == "detector_b" or event.channel == "detector_d") and (mem.cycle == "straight2.5" or mem.cycle == "straight3") then
	--Car detected, reset gap-out timer
	interrupt(mem.gapout,"gapout")
end

--Preemption logic
if event.type == "digiline" and string.sub(event.channel,1,8) == "preempt_" and not mem.stoptime then
	log("Preemption detector activated",true)
	mem.preempt = string.sub(event.channel,9,10)
	log("Entering preemption on approach "..mem.preempt.." from state "..(mem.cycle or "idle"),true)
	mem.busy = true
	local pedactive = (mem.currentphase.ap ~= "R" or mem.currentphase.bp ~= "R" or mem.currentphase.cp ~= "R" or mem.currentphase.dp ~= "R")
	for k,v in pairs(mem.currentphase) do
		if pedactive then
			if k == "ap" or k == "bp" or k == "cp" or k == "dp" then
				if v == "G" then setlight(k,"FR") end
			end
		else
			if v ~= "R" then
				setlight(k,"Y")
			end
		end
	end
	if pedactive then
		mem.cycle = "preempt_yellow"
		interrupt(mem.pedwarn,"tick")
	else
		mem.cycle = "preempt_allred"
		interrupt(mem.yellowa,"tick")
	end
end

--Phase logic for already-running cycles
if mem.busy and event.type == "interrupt" and (event.iid == "tick" or event.iid == "manualtick") and not mem.phaselocked and (event.iid == "manualtick" or not mem.stoptime) then
	log("Continuing existing cycle at phase "..mem.cycle,true)
	if mem.cycle == "preempt_yellow" then
		for k,v in pairs(mem.currentphase) do
			if k == "ap" or k == "bp" or k == "cp" or k == "dp" then
				setlight(k,"R")
			else
				if v ~= "R" then setlight(k,"Y") end
			end
			mem.cycle = "preempt_allred"
			interrupt(mem.yellowa,"tick")
		end
	elseif mem.cycle == "preempt_allred" then
		mem.currentphase = {a = "R",b = "R",c = "R",d = "R",at = "R",bt = "R",ct = "R",dt = "R",ap = "R",bp = "R",cp = "R",dp = "R"}
		mem.cycle = "preempt_green"
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "preempt_green" then
		if mem["lt"..mem.preempt.."type"] ~= 1 then
			mem.cycle = mem.preempt.."lead1"
		else
			if mem.preempt == "a" or mem.preempt == "c" then
				mem.cycle = "mindwell"
			else
				mem.cycle = "straight2"
			end
		end
		mem.preempt = nil
		mem.det = {}
		interrupt(0,"tick")
	elseif mem.cycle == "straight1" then
		mem.cycle = "straight2"
		setlight("a","R")
		setlight("c","R")
		setlight("at","R")
		setlight("ct","R")
		--Branch over to B/D leading left turn if necessary
		if (mem.det.bt and mem.det.dt and mem.ltbtype ~= 1 and mem.ltdtype ~= 1) or (((mem.det.bt and mem.ltbtype ~= 1) or (mem.det.dt and mem.ltdtype ~= 1)) and ((mem.det.ap and mem.pedatype ~= 1) or (mem.det.cp and mem.pedctype ~= 1))) then
			mem.cycle = "bdlead1"
		elseif mem.det.bt and mem.ltbtype ~= 1 then
			mem.cycle = "blead1"
		elseif mem.det.dt and mem.ltdtype ~= 1 then
			mem.cycle = "dlead1"
		end
		--If nobody wants to go straight or turn on B/D, but there are cars an AT or CT, serve them instead
		if not mem.det.b and not mem.det.d and not mem.det.bt and not mem.det.dt and not mem.det.ap and not mem.det.cp then
			if mem.det.at and mem.ltatype ~= 1 and mem.det.ct and mem.ltctype ~= 1 then
				mem.cycle = "aclead1"
			elseif mem.det.at and mem.ltatype ~= 1 then
				mem.cycle = "alead1"
			elseif mem.det.ct and mem.ltctype ~= 1 then
				mem.cycle = "clead1"
			end
		end
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "straight2" then
		mem.cycle = "straight3"
		setlight("b","G")
		setlight("d","G")
		if mem.ltbtype == 3 then setlight("bt","FY") end
		if mem.ltdtype == 3 then setlight("dt","FY") end
		if (mem.det.ap and mem.pedatype ~= 1) or (mem.det.cp and mem.pedctype ~= 1) or mem.pedrecallmode == 3 and not mem.preempt then
			mem.cycle = "straight2.5"
			if mem.pedatype ~= 1 then setlight("ap","G") end
			if mem.pedctype ~= 1 then setlight("cp","G") end
		end
		log("Entering volume density control",true)
		interrupt(mem.minsidegreen,"gapout")
		interrupt(mem.maxsidegreen,"maxgreen")
	elseif mem.cycle == "straight2.5" then
		mem.cycle = "straight3"
		mem.det.ap = nil
		mem.det.cp = nil
		if mem.pedatype ~= 1 then setlight("ap","FR") end
		if mem.pedctype ~= 1 then setlight("cp","FR") end
		interrupt(mem.pedwarn,"tick")
	elseif mem.cycle == "straight3" then
		mem.cycle = "straight4"
		setlight("b","Y")
		setlight("d","Y")
		if mem.pedatype ~= 1 then setlight("ap","R") end
		if mem.pedctype ~= 1 then setlight("cp","R") end
		if mem.ltbtype == 3 then setlight("bt","Y") end
		if mem.ltdtype == 3 then setlight("dt","Y") end
		mem.det.b = nil
		mem.det.d = nil
		interrupt(mem.yellowb,"tick")
	elseif mem.cycle == "straight4" then
		mem.cycle = "mindwell"
		setlight("b","R")
		setlight("d","R")
		setlight("bt","R")
		setlight("dt","R")
		--Branch over to A/C leading left turn if necessary
		if mem.det.at and mem.det.ct and mem.ltatype ~= 1 and mem.ltctype ~= 1 then
			mem.cycle = "aclead1"
		elseif mem.det.at and mem.ltatype ~= 1 then
			mem.cycle = "alead1"
		elseif mem.det.ct and mem.ltctype ~= 1 then
			mem.cycle = "clead1"
		end
		interrupt(mem.allredb,"tick")
	elseif mem.cycle == "mindwell" then
		mem.cycle = "reset"
		setlight("a","G")
		setlight("c","G")
		if mem.ltatype == 3 then setlight("at","FY") end
		if mem.ltctype == 3 then setlight("ct","FY") end
		if (mem.det.bp and mem.pedbtype ~= 1) or (mem.det.dp and mem.peddtype ~= 1) or (mem.pedrecallmode == 3 and not mem.wasped) then
			mem.cycle = "sideped1"
			if mem.ltatype == 3 and mem.pedbtype ~= 1 then setlight("at","R") end
			if mem.ltctype == 3 and mem.peddtype ~= 1 then setlight("ct","R") end
			if mem.ltatype == 3 or mem.ltctype == 3 then
				interrupt(mem.yellowa,"tick")
			else
				interrupt(0,"tick")
			end
		else
			mem.wasped = false
			interrupt(mem.mindwell,"tick")
		end
	elseif mem.cycle == "bdlead1" then
		mem.cycle = "bdlead2"
		setlight("bt","G")
		setlight("dt","G")
		interrupt(mem.llturn,"tick")
	elseif mem.cycle == "bdlead2" then
		mem.det.bt = nil
		mem.det.dt = nil
		if mem.ltbtype ~= 3 and mem.ltdtype ~= 3 then
			mem.cycle = "bdlead3"
		else
			mem.cycle = "straight2"
		end
		setlight("bt","Y")
		setlight("dt","Y")
		interrupt(mem.yellowb,"tick")
	elseif mem.cycle == "bdlead3" then
		mem.cycle = "straight2"
		setlight("bt","R")
		setlight("dt","R")
		interrupt(mem.allredb,"tick")
	elseif mem.cycle == "blead1" then
		mem.cycle = "blead2"
		setlight("bt","G")
		setlight("b","G")
		interrupt(mem.llturn,"tick")
	elseif mem.cycle == "blead2" then
		if mem.ltbtype ~= 3 then
			mem.cycle = "blead3"
		else
			mem.cycle = "straight2"
		end
		mem.det.bt = nil
		setlight("bt","Y")
		interrupt(mem.yellowb,"tick")
	elseif mem.cycle == "blead3" then
		mem.cycle = "straight2"
		setlight("bt","R")
		interrupt(mem.allredb,"tick")
	elseif mem.cycle == "dlead1" then
		mem.cycle = "dlead2"
		setlight("dt","G")
		setlight("d","G")
		interrupt(mem.llturn,"tick")
	elseif mem.cycle == "dlead2" then
		if mem.ltdtype ~= 3 then
			mem.cycle = "dlead3"
		else
			mem.cycle = "straight2"
		end
		mem.det.dt = nil
		setlight("dt","Y")
		interrupt(mem.yellowb,"tick")
	elseif mem.cycle == "dlead3" then
		mem.cycle = "straight2"
		setlight("dt","R")
		interrupt(mem.allredb,"tick")
	elseif mem.cycle == "aclead1" then
		mem.cycle = "aclead2"
		setlight("at","G")
		setlight("ct","G")
		interrupt(mem.llturn,"tick")
	elseif mem.cycle == "aclead2" then
		if mem.ltatype ~= 3 and mem.ltctype ~= 3 then
			mem.cycle = "aclead3"
		else
			mem.cycle = "mindwell"
		end
		setlight("at","Y")
		setlight("ct","Y")
		mem.det.at = nil
		mem.det.ct = nil
		interrupt(mem.yellowa,"tick")
	elseif mem.cycle == "aclead3" then
		mem.cycle = "mindwell"
		setlight("at","R")
		setlight("ct","R")
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "alead1" then
		if mem.det.ct and mem.ltctype ~= 1 then
			mem.cycle = "aclead2"
			setlight("ct","G")
		else
			mem.cycle = "alead2"
			setlight("a","G")
		end
		setlight("at","G")
		interrupt(mem.llturn,"tick")
	elseif mem.cycle == "alead2" then
		mem.cycle = "alead3"
		setlight("at","Y")
		mem.det.at = nil
		interrupt(mem.yellowa,"tick")
	elseif mem.cycle == "alead3" then
		mem.cycle = "mindwell"
		setlight("at","R")
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "clead1" then
		if mem.det.at and mem.ltatype ~= 1 then
			mem.cycle = "aclead2"
			setlight("at","G")
		else
			mem.cycle = "clead2"
			setlight("c","G")
		end
		setlight("ct","G")
		interrupt(mem.llturn,"tick")
	elseif mem.cycle == "clead2" then
		mem.cycle = "clead3"
		setlight("ct","Y")
		mem.det.ct = nil
		interrupt(mem.yellowa,"tick")
	elseif mem.cycle == "clead3" then
		mem.cycle = "mindwell"
		setlight("ct","R")
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "yta1" then
		mem.cycle = "yta2"
		setlight("c","R")
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "yta2" then
		mem.cycle = "yta3"
		setlight("at","G")
		interrupt(mem.llturn,"tick")
	elseif mem.cycle == "yta3" then
		mem.cycle = "yta4"
		setlight("at","Y")
		mem.det.at = nil
		interrupt(mem.yellowa,"tick")
	elseif mem.cycle == "yta4" then
		mem.cycle = "mindwell"
		if mem.ltatype == 3 then
			setlight("at","FY")
		else
			setlight("at","R")
		end
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "ytc1" then
		mem.cycle = "ytc2"
		setlight("a","R")
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "ytc2" then
		mem.cycle = "ytc3"
		setlight("ct","G")
		interrupt(mem.llturn,"tick")
	elseif mem.cycle == "ytc3" then
		mem.cycle = "ytc4"
		setlight("ct","Y")
		mem.det.ct = nil
		interrupt(mem.yellowa,"tick")
	elseif mem.cycle == "ytc4" then
		mem.cycle = "mindwell"
		if mem.ltctype == 3 then
			setlight("ct","FY")
		else
			setlight("ct","R")
		end
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "sideped1" then
		mem.cycle = "sideped2"
		if mem.ltatype == 3 and mem.pedbtype ~= 1 then setlight("at","R") end
		if mem.ltctype == 3 and mem.peddtype ~= 1 then setlight("ct","R") end
		interrupt(mem.allreda,"tick")
	elseif mem.cycle == "sideped2" then
		mem.cycle = "sideped3"
		if mem.pedbtype ~= 1 then setlight("bp","G") end
		if mem.peddtype ~= 1 then setlight("dp","G") end
		interrupt(mem.sideped,"tick")
	elseif mem.cycle == "sideped3" then
		if not (mem.det.b or mem.det.d or mem.det.at or mem.det.bt or mem.det.ct or mem.det.dt or mem.det.ap or mem.det.cp) and (mem.pedrecallmode == 3 or mem.det.bp or mem.det.dp) then
			mem.det.bp = nil
			mem.det.dp = nil
			interrupt(mem.sideped,"tick")
			log("Extending bp/dp walk time",true)
		else
			mem.cycle = "sideped4"
			mem.det.bp = nil
			mem.det.dp = nil
			if mem.pedbtype ~= 1 then setlight("bp","FR") end
			if mem.peddtype ~= 1 then setlight("dp","FR") end
			interrupt(mem.pedwarn,"tick")
		end
	elseif mem.cycle == "sideped4" then
		mem.wasped = true
		if mem.det.b or mem.det.d or mem.det.at or mem.det.bt or mem.det.ct or mem.det.dt or mem.det.ap or mem.det.cp then
			mem.cycle = "reset"
			interrupt(mem.allredb,"tick")
		else
			mem.cycle = "mindwell"
			interrupt(0,"tick")
		end
		setlight("bp","R")
		setlight("dp","R")
	elseif mem.cycle == "reset" then
		mem.cycle = nil
		mem.busy = false
		mem.wasped = false
		--If someone shows up on AT/CT and turns immediately,
		--we shouldn't change for them unless we're completely idle or protected only
		if mem.ltatype ~= 2 then mem.det.at = nil end
		if mem.ltctype ~= 2 then mem.det.ct = nil end
	else
		logfault("Unrecognized phase "..mem.cycle,true)
	end
end

--Phase logic for starting new cycles
detactive = false
for _,_ in pairs(mem.det) do detactive = true end
if (not mem.busy) and detactive and (not mem.stoptime) then
	if mem.phaselocked then
		log("Not starting cycle due to phase lock",true)
	elseif mem.preempt then
		log("Not starting cycle due to preemption",true)
	else
	log("Starting new cycle",true)
	mem.stats.cycles = mem.stats.cycles + 1
		if mem.det.at and mem.ltatype ~= 1 and (mem.ltctype == 2 or mem.ltctype == 3) and not (mem.det.b or mem.det.d or mem.det.bt or mem.det.ct or mem.det.dt) then
			mem.cycle = "yta1"
			mem.busy = true
			setlight("c","Y")
			interrupt(mem.yellowa,"tick")
		elseif mem.det.ct and mem.ltctype ~=1 and (mem.ltatype == 2 or mem.ltatype == 3) and not (mem.det.b or mem.det.d or mem.det.at or mem.det.bt or mem.det.dt) then
			mem.cycle = "ytc1"
			mem.busy = true
			setlight("a","Y")
			interrupt(mem.yellowa,"tick")
		elseif mem.det.b or mem.det.d or mem.det.bt or mem.det.dt or (mem.det.at and mem.ltatype ~= 1) or (mem.det.ct and mem.ltctype ~= 1) then
			mem.cycle = "straight1"
			mem.busy = true
			setlight("a","Y")
			setlight("c","Y")
			if mem.ltatype == 3 then setlight("at","Y") end
			if mem.ltctype == 3 then setlight("ct","Y") end
			interrupt(mem.yellowa,"tick")
		elseif (mem.det.ap and mem.pedatype ~= 1) or (mem.det.cp and mem.pedctype ~= 1) then
			mem.cycle = "straight1"
			mem.busy = true
			setlight("a","Y")
			setlight("c","Y")
			if mem.ltatype == 3 then setlight("at","Y") end
			if mem.ltctype == 3 then setlight("ct","Y") end
			interrupt(mem.yellowa,"tick")
		elseif (mem.det.bp and mem.pedbtype ~= 1) or (mem.det.dp and mem.peddtype ~= 1) then
			mem.cycle = "sideped1"
			mem.busy = true
		if mem.ltatype == 3 and mem.pedbtype ~= 1 then setlight("at","Y") end
		if mem.ltctype == 3 and mem.peddtype ~= 1 then setlight("ct","Y") end
			if mem.ltatype == 3 or mem.ltctype == 3 then
				interrupt(mem.yellowa,"tick")
			else
				interrupt(0,"tick")
			end
		else
			logfault("Detectors active but no cycle found",true)
		end
	end
end

--Touch event handling
if event.type == "digiline" and event.channel == "touchscreen" then
	local fields = event.msg
	if mem.menu == "main" then
		if fields.exit then
			mem.menu = "run"
		elseif fields.hwsetup then
			mem.menu = "hwsetup"
		elseif fields.timing then
			mem.menu = "timing"
		elseif fields.options then
			mem.menu = "options"
		elseif fields.phaselock then
			mem.menu = "phaselock"
		elseif fields.about then
			mem.menu = "about"
		elseif fields.log then
			mem.menu = "log"
		elseif fields.monitoring then
			mem.menu = "monitoring"
		elseif fields.mancyc then
			mem.menu = "mancyc"
		elseif fields.stats then
			mem.menu = "stats"
		elseif fields.mode then
			mem.menu = "mode"
		elseif fields.diag then
			mem.menu = "diag"
		end
	elseif mem.menu == "run" then
		if fields.menu then
			mem.menu = "main"
		end
	elseif mem.menu == "hwsetup" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.save then
			mem.menu = "main"
			mem.ltatype = pivot(lttypes)[fields.ltatype]
			mem.ltbtype = pivot(lttypes)[fields.ltbtype]
			mem.ltctype = pivot(lttypes)[fields.ltctype]
			mem.ltdtype = pivot(lttypes)[fields.ltdtype]
			mem.pedatype = pivot(pedtypes)[fields.pedatype]
			mem.pedbtype = pivot(pedtypes)[fields.pedbtype]
			mem.pedctype = pivot(pedtypes)[fields.pedctype]
			mem.peddtype = pivot(pedtypes)[fields.peddtype]
			mem.signaltype = pivot(signaltypes)[fields.signaltype]
			mem.pedbuttontype = pivot(pedbuttontypes)[fields.pedbuttontype]
			mem.logmode = pivot(logmodes)[fields.logmode]
			mem.lock = pivot(panellock)[fields.panellock]
		end
	elseif mem.menu == "timing" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.save then
			mem.menu = "main"
			mem.pedrecallmode = pivot(pedrecallmodes)[fields.pedrecall]
			mem.ltrecallmode = pivot(ltrecallmodes)[fields.ltrecall]
			mem.allreda = tonumber(fields.allreda) or mem.allreda
			mem.allredb = tonumber(fields.allredb) or mem.allredb
			mem.yellowa = tonumber(fields.yellowa) or mem.yellowa
			mem.yellowb = tonumber(fields.yellowb) or mem.yellowb
			mem.mindwell = tonumber(fields.mindwell) or mem.mindwell
			mem.minsidegreen = tonumber(fields.minsidegreen) or mem.minsidegreen
			mem.gapout = tonumber(fields.gapout) or mem.minsidegreen
			mem.maxsidegreen = tonumber(fields.maxsidegreen) or mem.minsidegreen
			mem.pedwarn = tonumber(fields.pedwarn) or mem.pedwarn
			mem.sideped = tonumber(fields.sideped) or mem.sideped
			mem.llturn = tonumber(fields.llturn) or mem.llturn
		end
	elseif mem.menu == "options" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.save then
			mem.menu = "main"
			mem.name = fields.name
		end
	elseif mem.menu == "mancyc" then
		if fields.cancel then
			mem.menu = "main"
		else
			for _,v in pairs({"a","b","c","d","at","bt","ct","dt","ap","bp","cp","dp"}) do
				if fields[v] then
					mem.det[v] = true
					interrupt(0,"tick") --Forces the program to be re-run since the cycle logic is up there ^^
				end
			end
		end
	elseif mem.menu == "log" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.clear then
			mem.faultlog = {}
		end
	elseif mem.menu == "monitoring" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.straight then
			mem.monitor = 1
		elseif fields.leftturn then
			mem.monitor = 2
		elseif fields.pedestrian then
			mem.monitor = 3
		end
	elseif mem.menu == "phaselock" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.save then
			mem.menu = "main"
			local phases_reverse = pivot(phases)
			mem.phaselock.a = phases_reverse[fields.a]
			mem.phaselock.b = phases_reverse[fields.b]
			mem.phaselock.c = phases_reverse[fields.c]
			mem.phaselock.d = phases_reverse[fields.d]
			mem.phaselock.at = phases_reverse[fields.at]
			mem.phaselock.bt = phases_reverse[fields.bt]
			mem.phaselock.ct = phases_reverse[fields.ct]
			mem.phaselock.dt = phases_reverse[fields.dt]
			mem.phaselock.ap = phases_reverse[fields.ap]
			mem.phaselock.bp = phases_reverse[fields.bp]
			mem.phaselock.cp = phases_reverse[fields.cp]
			mem.phaselock.dp = phases_reverse[fields.dp]
		end
	elseif mem.menu == "about" then
		if fields.cancel then
			mem.menu = "main"
		end
	elseif mem.menu == "stats" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.clear then
			mem.stats = {a = 0,b = 0,c = 0,d = 0,at = 0,bt = 0,ct = 0,dt = 0,ap = 0,bp = 0,cp = 0,dp = 0,cycles = 0,lastreset = os.time()}
		end
	elseif mem.menu == "mode" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.save then
			mem.schedstart = tonumber(fields.schedstart) or mem.schedstart
			mem.schedend = tonumber(fields.schedend) or mem.schedend
			mem.normalmode = pivot(modes)[fields.normalmode]
			mem.schedmode = pivot(modes)[fields.schedmode]
			mem.menu = "main"
			interrupt(0,"rerun") -- Some of these need to take immediate effect
		end
	elseif mem.menu == "diag" then
		if fields.cancel then
			mem.menu = "main"
		elseif fields.startstop then
			if mem.stoptime then
				mem.stoptime = false
				interrupt(1,"tick")
			else
				mem.stoptime = true
				interrupt(nil,"tick")
			end
		elseif fields.stepnow then
			interrupt(0,"manualtick")
		elseif fields.reboot then
			mem.phaselocked = true
			mem.cycle = nil
			mem.menu = "reboot"
			mem.busy = false
			mem.preempt = nil
			mem.stoptime = true
			interrupt(10,"reboot")
			interrupt(nil,"step")
			interrupt(nil,"rerun")
			interrupt(nil,"gapout")
			interrupt(nil,"maxgreen")
		end
	else
		logfault("Unrecognized menu "..mem.menu,false)
		mem.menu = "run"
	end
end

if event.iid == "reboot" then
	mem.phaselocked = false
	mem.menu = "main"
	mem.stoptime = false
	mem.cycle = nil
	interrupt(0,"tick")
end

--Light control signal sending
if mem.phaselocked then
	mem.busy = false
	mem.cycle = nil
	mem.currentphase = mem.phaselock
	for k,v in pairs(mem.phaselock) do
		digiline_send(k,string.upper(phases[v]))
	end
else
	for k,v in pairs(mem.currentphase) do
		digiline_send(k,string.upper(phases[v]))
	end
end

--Display drawing
if event.type == "interrupt" and event.iid == "monflash" then
	mem.monflash = not mem.monflash
end
local disp = {{command="clear"}}
if mem.lock == 2 then
	table.insert(disp,{command="lock"})
else
	table.insert(disp,{command="unlock"})
end
if mem.menu == "main" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Main Menu"})
	table.insert(disp,{command="addbutton",X=1,Y=1,W=2,H=1,name="exit",label="Exit"})
	table.insert(disp,{command="addbutton",X=1,Y=3,W=2,H=1,name="hwsetup",label="Hardware Setup"})
	table.insert(disp,{command="addbutton",X=1,Y=5,W=2,H=1,name="timing",label="Timing"})
	table.insert(disp,{command="addbutton",X=4,Y=1,W=2,H=1,name="options",label="Set Name"})
	table.insert(disp,{command="addbutton",X=4,Y=3,W=2,H=1,name="phaselock",label="Phase Lock"})
	table.insert(disp,{command="addbutton",X=4,Y=5,W=2,H=1,name="about",label="About"})
	table.insert(disp,{command="addbutton",X=7,Y=1,W=2,H=1,name="log",label="Log"})
	table.insert(disp,{command="addbutton",X=7,Y=3,W=2,H=1,name="monitoring",label="Monitoring"})
	table.insert(disp,{command="addbutton",X=7,Y=5,W=2,H=1,name="mancyc",label="Manual Call Entry"})
	table.insert(disp,{command="addbutton",X=1,Y=7,W=2,H=1,name="stats",label="Statistics"})
	table.insert(disp,{command="addbutton",X=4,Y=7,W=2,H=1,name="mode",label="Mode/Schedule"})
	table.insert(disp,{command="addbutton",X=7,Y=7,W=2,H=1,name="diag",label="Diagnostics"})
elseif mem.menu == "run" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label=mem.name})
	table.insert(disp,{command="addlabel",X=0,Y=1,label="Advanced Mesecons Devices LTC-4000E"})
	if #mem.faultlog > 0 then
		table.insert(disp,{command="addlabel",X=0,Y=2,label="FAULT DETECTED! Use Menu->Log to view"})
	else
		table.insert(disp,{command="addlabel",X=0,Y=2,label="No Current Faults"})
	end
	table.insert(disp,{command="addbutton",X=0,Y=7,W=2,H=1,name="menu",label="Menu"})
elseif mem.menu == "hwsetup" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Hardware Setup"})
	table.insert(disp,{command="addlabel",X=0,Y=1,label="Left Turn A Type"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=1.5,W=2.25,H=1,name="ltatype",selected_id=mem.ltatype,choices=lttypes})
	table.insert(disp,{command="addlabel",X=0,Y=2.5,label="Left Turn B Type"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=3,W=2.25,H=1,name="ltbtype",selected_id=mem.ltbtype,choices=lttypes})
	table.insert(disp,{command="addlabel",X=0,Y=4,label="Left Turn C Type"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=4.5,W=2.25,H=1,name="ltctype",selected_id=mem.ltctype,choices=lttypes})
	table.insert(disp,{command="addlabel",X=0,Y=5.5,label="Left Turn D Type"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=6,W=2.25,H=1,name="ltdtype",selected_id=mem.ltdtype,choices=lttypes})
	table.insert(disp,{command="addlabel",X=3,Y=1,label="Pedestrian A Type"})
	table.insert(disp,{command="adddropdown",X=3.1,Y=1.5,W=2.25,H=1,name="pedatype",selected_id=mem.pedatype,choices=pedtypes})
	table.insert(disp,{command="addlabel",X=3,Y=2.5,label="Pedestrian B Type"})
	table.insert(disp,{command="adddropdown",X=3.1,Y=3,W=2.25,H=1,name="pedbtype",selected_id=mem.pedbtype,choices=pedtypes})
	table.insert(disp,{command="addlabel",X=3,Y=4,label="Pedestrian C Type"})
	table.insert(disp,{command="adddropdown",X=3.1,Y=4.5,W=2.25,H=1,name="pedctype",selected_id=mem.pedctype,choices=pedtypes})
	table.insert(disp,{command="addlabel",X=3,Y=5.5,label="Pedestrian D Type"})
	table.insert(disp,{command="adddropdown",X=3.1,Y=6,W=2.25,H=1,name="peddtype",selected_id=mem.peddtype,choices=pedtypes})
	table.insert(disp,{command="addlabel",X=6,Y=1,label="Signal Type"})
	table.insert(disp,{command="adddropdown",X=6.1,Y=1.5,W=2.25,H=1,name="signaltype",selected_id=mem.signaltype,choices=signaltypes})
	table.insert(disp,{command="addlabel",X=6,Y=2.5,label="Pedestrian Button Type"})
	table.insert(disp,{command="adddropdown",X=6.1,Y=3,W=2.25,H=1,name="pedbuttontype",selected_id=mem.pedbuttontype,choices=pedbuttontypes})
	table.insert(disp,{command="addlabel",X=6,Y=4,label="Log Output Mode"})
	table.insert(disp,{command="adddropdown",X=6.1,Y=4.5,W=2.25,H=1,name="logmode",selected_id=mem.logmode,choices=logmodes})
	table.insert(disp,{command="addlabel",X=6,Y=5.5,label="Panel Lock"})
	table.insert(disp,{command="adddropdown",X=6.1,Y=6,W=2.25,H=1,name="panellock",selected_id=mem.lock,choices=panellock})
	table.insert(disp,{command="addbutton",X=2,Y=7,W=2,H=1,name="save",label="Save"})
	table.insert(disp,{command="addbutton",X=5,Y=7,W=2,H=1,name="cancel",label="Cancel"})
elseif mem.menu == "timing" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Timing"})
	table.insert(disp,{command="addfield",X=0.25,Y=1,W=2.25,H=1,name="allreda",label="All Red A/C->B/D",default=tostring(mem.allreda)})
	table.insert(disp,{command="addfield",X=0.25,Y=2.5,W=2.25,H=1,name="allredb",label="All Red B/D->A/C",default=tostring(mem.allredb)})
	table.insert(disp,{command="addfield",X=0.25,Y=4,W=2.25,H=1,name="yellowa",label="Yellow A/C->B/D",default=tostring(mem.yellowa)})
	table.insert(disp,{command="addfield",X=0.25,Y=5.5,W=2.25,H=1,name="yellowb",label="Yellow B/D->A/C",default=tostring(mem.yellowb)})
	table.insert(disp,{command="addfield",X=3.25,Y=1,W=2.25,H=1,name="mindwell",label="Minimum Dwell",default=tostring(mem.mindwell)})
	table.insert(disp,{command="addlabel",X=5.9,Y=0.45,label="Pedestrian Recall"})
	table.insert(disp,{command="adddropdown",X=5.9,Y=0.85,W=2.25,H=1,name="pedrecall",selected_id=mem.pedrecallmode,choices=pedrecallmodes})
	table.insert(disp,{command="addlabel",X=5.9,Y=1.95,label="LT Recall in Timer Mode"})
	table.insert(disp,{command="adddropdown",X=5.9,Y=2.35,W=2.25,H=1,name="ltrecall",selected_id=mem.ltrecallmode,choices=ltrecallmodes})
	table.insert(disp,{command="addfield",X=3.25,Y=4,W=2.25,H=1,name="pedwarn",label="Pedestrian Warn",default=tostring(mem.pedwarn)})
	table.insert(disp,{command="addfield",X=3.25,Y=5.5,W=2.25,H=1,name="sideped",label="B/D Pedestrian Walk",default=tostring(mem.sideped)})
	table.insert(disp,{command="addfield",X=3.25,Y=2.5,W=2.25,H=1,name="llturn",label="Lead/Lag Turn",default=tostring(mem.llturn)})
	table.insert(disp,{command="addfield",X=0.25,Y=7,W=2.25,H=1,name="minsidegreen",label="B/D Min Green",default=tostring(mem.minsidegreen)})
	table.insert(disp,{command="addfield",X=3.25,Y=7,W=2.25,H=1,name="gapout",label="B/D Gap-out",default=tostring(mem.gapout)})
	table.insert(disp,{command="addfield",X=6.25,Y=7,W=2.25,H=1,name="maxsidegreen",label="B/D Max Green",default=tostring(mem.maxsidegreen)})
	table.insert(disp,{command="addbutton",X=6,Y=3.75,W=2,H=1,name="save",label="Save"})
	table.insert(disp,{command="addbutton",X=6,Y=5,W=2,H=1,name="cancel",label="Cancel"})
elseif mem.menu == "options" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Set Name"})
	table.insert(disp,{command="addfield",X=0.25,Y=1,W=5,H=1,name="name",label="Intersection Name",default=mem.name})
	table.insert(disp,{command="addbutton",X=0.25,Y=2.5,W=2,H=1,name="save",label="Save"})
	table.insert(disp,{command="addbutton",X=0.25,Y=3.5,W=2,H=1,name="cancel",label="Cancel"})
elseif mem.menu == "mancyc" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Manual Call Entry"})
	table.insert(disp,{command="addimage_button",X=1,Y=2,W=2,H=1,name="b",label="Straight B",image="digistuff_ts_bg.png"..(mem.det.b and "^[brighten" or "")})
	table.insert(disp,{command="addimage_button",X=1,Y=4,W=2,H=1,name="d",label="Straight D",image="digistuff_ts_bg.png"..(mem.det.d and "^[brighten" or "")})
	if mem.ltatype ~= 1 then table.insert(disp,{command="addimage_button",X=4,Y=1,W=2,H=1,name="at",label="Left Turn A",image="digistuff_ts_bg.png"..(mem.det.at and "^[brighten" or "")}) end
	if mem.ltbtype ~= 1 then table.insert(disp,{command="addimage_button",X=4,Y=2,W=2,H=1,name="bt",label="Left Turn B",image="digistuff_ts_bg.png"..(mem.det.bt and "^[brighten" or "")}) end
	if mem.ltctype ~= 1 then table.insert(disp,{command="addimage_button",X=4,Y=3,W=2,H=1,name="ct",label="Left Turn C",image="digistuff_ts_bg.png"..(mem.det.ct and "^[brighten" or "")}) end
	if mem.ltdtype ~= 1 then table.insert(disp,{command="addimage_button",X=4,Y=4,W=2,H=1,name="dt",label="Left Turn D",image="digistuff_ts_bg.png"..(mem.det.dt and "^[brighten" or "")}) end
	if mem.pedatype ~= 1 then table.insert(disp,{command="addimage_button",X=7,Y=1,W=2,H=1,name="ap",label="Pedestrian A",image="digistuff_ts_bg.png"..(mem.det.ap and "^[brighten" or "")}) end
	if mem.pedbtype ~= 1 then table.insert(disp,{command="addimage_button",X=7,Y=2,W=2,H=1,name="bp",label="Pedestrian B",image="digistuff_ts_bg.png"..(mem.det.bp and "^[brighten" or "")}) end
	if mem.pedctype ~= 1 then table.insert(disp,{command="addimage_button",X=7,Y=3,W=2,H=1,name="cp",label="Pedestrian C",image="digistuff_ts_bg.png"..(mem.det.cp and "^[brighten" or "")}) end
	if mem.peddtype ~= 1 then table.insert(disp,{command="addimage_button",X=7,Y=4,W=2,H=1,name="dp",label="Pedestrian D",image="digistuff_ts_bg.png"..(mem.det.dp and "^[brighten" or "")}) end
	table.insert(disp,{command="addbutton",X=4,Y=6,W=2,H=1,name="cancel",label="Back"})
elseif mem.menu == "log" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Fault Log"})
	table.insert(disp,{command="addbutton",X=2,Y=0,W=2,H=1,name="cancel",label="Back"})
	table.insert(disp,{command="addbutton",X=4,Y=0,W=2,H=1,name="clear",label="Clear"})
	if #mem.faultlog > 0 then
		for i=1,math.max(#mem.faultlog,10),1 do
			table.insert(disp,{command="addlabel",X=0,Y=1+(i/2),label=mem.faultlog[i]})
		end
	else
		table.insert(disp,{command="addlabel",X=0,Y=1.5,label="No Faults"})
	end
elseif mem.menu == "monitoring" then
	interrupt(1,"monflash")

	local monitor_textures = {}
	monitor_textures.O = "streets_tl_off.png"
	monitor_textures.R = "streets_tl_red.png"
	monitor_textures.Y = "streets_tl_yellow.png"
	monitor_textures.G = "streets_tl_green.png"
	if mem.monflash then
		monitor_textures.FR = "streets_tl_red.png"
		monitor_textures.FY = "streets_tl_yellow.png"
		monitor_textures.FG = "streets_tl_green.png"
	else
		monitor_textures.FR = "streets_tl_off.png"
		monitor_textures.FY = "streets_tl_off.png"
		monitor_textures.FG = "streets_tl_off.png"
	end
	monitor_textures.RY = "streets_tl_redyellow.png"

	local monitor_textures_lt = {}
	monitor_textures_lt.O = "streets_tl_left_off.png"
	monitor_textures_lt.R = "streets_tl_left_red.png"
	monitor_textures_lt.Y = "streets_tl_left_yellow.png"
	monitor_textures_lt.G = "streets_tl_left_green.png"
	if mem.monflash then
		monitor_textures_lt.FR = "streets_tl_left_red.png"
		monitor_textures_lt.FY = "streets_tl_left_yellow.png"
		monitor_textures_lt.FG = "streets_tl_left_green.png"
	else
		monitor_textures_lt.FR = "streets_tl_left_off.png"
		monitor_textures_lt.FY = "streets_tl_left_off.png"
		monitor_textures_lt.FG = "streets_tl_left_off.png"
	end
	monitor_textures_lt.RY = "streets_tl_left_redyellow.png"

	local monitor_textures_ped = {}
	monitor_textures_ped.O = "streets_pl_off.png"
	monitor_textures_ped.R = "streets_pl_dontwalk.png"
	monitor_textures_ped.G = "streets_pl_walk.png"
	if mem.monflash then
		monitor_textures_ped.FR = "streets_pl_dontwalk.png"
		monitor_textures_ped.FY = "streets_pl_dontwalk.png"
		monitor_textures_ped.FG = "streets_pl_dontwalk.png"
		monitor_textures_ped.Y = "streets_pl_dontwalk.png"
	else
		monitor_textures_ped.FR = "streets_pl_off.png"
		monitor_textures_ped.FY = "streets_pl_off.png"
		monitor_textures_ped.FG = "streets_pl_off.png"
		monitor_textures_ped.Y = "streets_pl_off.png"
	end
	monitor_textures_ped.RY = "streets_pl_dontwalk.png"

	table.insert(disp,{command="addlabel",X=0,Y=0,label="Monitor"})
	table.insert(disp,{command="addbutton",X=0,Y=2,W=2,H=1,name="straight",label="Straight"})
	table.insert(disp,{command="addbutton",X=0,Y=3,W=2,H=1,name="leftturn",label="Left Turn"})
	table.insert(disp,{command="addbutton",X=0,Y=4,W=2,H=1,name="pedestrian",label="Pedestrian"})
	table.insert(disp,{command="addbutton",X=0,Y=6,W=2,H=1,name="cancel",label="Back"})

	--Texture names
	local asphalt = ""
	local sideline = ""
	local centerline = ""
	if mem.signaltype == 1 then
		asphalt = "streets_asphalt.png"
		sideline = asphalt.."^streets_asphalt_side.png"
		centerline = asphalt.."^streets_rw_dashed_line.png"
	elseif mem.signaltype == 2 then
		asphalt = "streets_asphalt.png"
		sideline = asphalt.."^streets_asphalt_side.png"
		centerline = asphalt.."^infrastructure_double_yellow_line.png"
	elseif mem.signaltype == 3 then
		asphalt = "streets_asphalt.png"
		sideline = asphalt.."^streets_solid_side_line.png"
		centerline = asphalt.."^(streets_double_solid_center_line.png^[colorize:#ecb100)"
	end

	--Center of intersection
	table.insert(disp,{command="addimage",X=5.25,	Y=3.25,	W=1,H=1,texture_name=asphalt})
	table.insert(disp,{command="addimage",X=6,	Y=3.25,	W=1,H=1,texture_name=asphalt})
	table.insert(disp,{command="addimage",X=6.75,	Y=3.25,	W=1,H=1,texture_name=asphalt})
	table.insert(disp,{command="addimage",X=5.25,	Y=4,	W=1,H=1,texture_name=asphalt})
	table.insert(disp,{command="addimage",X=6,	Y=4,	W=1,H=1,texture_name=asphalt})
	table.insert(disp,{command="addimage",X=6.75,	Y=4,	W=1,H=1,texture_name=asphalt})
	table.insert(disp,{command="addimage",X=5.25,	Y=4.75,	W=1,H=1,texture_name=asphalt})
	table.insert(disp,{command="addimage",X=6,	Y=4.75,	W=1,H=1,texture_name=asphalt})
	table.insert(disp,{command="addimage",X=6.75,	Y=4.75,	W=1,H=1,texture_name=asphalt})

	--Approach Labels
	table.insert(disp,{command="addlabel",X=3.5,	Y=4.25,	label="A"})
	table.insert(disp,{command="addlabel",X=6.25,	Y=1.25,	label="B"})
	table.insert(disp,{command="addlabel",X=9.25,	Y=4.25,	label="C"})
	table.insert(disp,{command="addlabel",X=6.25,	Y=7.25,	label="D"})

	--Approach A (left)
	table.insert(disp,{command="addimage",X=4.5,	Y=3.25,	W=1,H=1,texture_name=sideline.."^[transformR270"})
	table.insert(disp,{command="addimage",X=4.5,	Y=4,	W=1,H=1,texture_name=centerline.."^[transformR90"})
	table.insert(disp,{command="addimage",X=4.5,	Y=4.75,	W=1,H=1,texture_name=sideline.."^[transformR90"})
	table.insert(disp,{command="addimage",X=3.75,	Y=3.25,	W=1,H=1,texture_name=sideline.."^[transformR270"})
	table.insert(disp,{command="addimage",X=3.75,	Y=4,	W=1,H=1,texture_name=centerline.."^[transformR90"})
	table.insert(disp,{command="addimage",X=3.75,	Y=4.75,	W=1,H=1,texture_name=sideline.."^[transformR90"})

	--Approach B (top)
	table.insert(disp,{command="addimage",X=5.25,	Y=2.5,	W=1,H=1,texture_name=sideline})
	table.insert(disp,{command="addimage",X=6,	Y=2.5,	W=1,H=1,texture_name=centerline})
	table.insert(disp,{command="addimage",X=6.75,	Y=2.5,	W=1,H=1,texture_name=sideline.."^[transformR180"})
	table.insert(disp,{command="addimage",X=5.25,	Y=1.75,	W=1,H=1,texture_name=sideline})
	table.insert(disp,{command="addimage",X=6,	Y=1.75,	W=1,H=1,texture_name=centerline})
	table.insert(disp,{command="addimage",X=6.75,	Y=1.75,	W=1,H=1,texture_name=sideline.."^[transformR180"})
	
	--Approach C (right)
	table.insert(disp,{command="addimage",X=7.5,	Y=3.25,	W=1,H=1,texture_name=sideline.."^[transformR270"})
	table.insert(disp,{command="addimage",X=7.5,	Y=4,	W=1,H=1,texture_name=centerline.."^[transformR90"})
	table.insert(disp,{command="addimage",X=7.5,	Y=4.75,	W=1,H=1,texture_name=sideline.."^[transformR90"})
	table.insert(disp,{command="addimage",X=8.25,	Y=3.25,	W=1,H=1,texture_name=sideline.."^[transformR270"})
	table.insert(disp,{command="addimage",X=8.25,	Y=4,	W=1,H=1,texture_name=centerline.."^[transformR90"})
	table.insert(disp,{command="addimage",X=8.25,	Y=4.75,	W=1,H=1,texture_name=sideline.."^[transformR90"})

	--Approach D (bottom)
	table.insert(disp,{command="addimage",X=5.25,	Y=5.5,	W=1,H=1,texture_name=sideline})
	table.insert(disp,{command="addimage",X=6,	Y=5.5,	W=1,H=1,texture_name=centerline})
	table.insert(disp,{command="addimage",X=6.75,	Y=5.5,	W=1,H=1,texture_name=sideline.."^[transformR180"})
	table.insert(disp,{command="addimage",X=5.25,	Y=6.25,	W=1,H=1,texture_name=sideline})
	table.insert(disp,{command="addimage",X=6,	Y=6.25,	W=1,H=1,texture_name=centerline})
	table.insert(disp,{command="addimage",X=6.75,	Y=6.25,	W=1,H=1,texture_name=sideline.."^[transformR180"})

	--Traffic Lights
	if mem.monitor == 1 then
		table.insert(disp,{command="addimage",X=4.25,	Y=5.5,	W=1,H=1,texture_name=monitor_textures[mem.currentphase.a].."^[transformR270"}) --A
		table.insert(disp,{command="addimage",X=4.5,	Y=2.25,	W=1,H=1,texture_name=monitor_textures[mem.currentphase.b].."^[transformR180"}) --B
		table.insert(disp,{command="addimage",X=7.75,	Y=2.5,	W=1,H=1,texture_name=monitor_textures[mem.currentphase.c].."^[transformR90"}) --C
		table.insert(disp,{command="addimage",X=7.5,	Y=5.75,	W=1,H=1,texture_name=monitor_textures[mem.currentphase.d]}) --D
	elseif mem.monitor == 2 then
		table.insert(disp,{command="addimage",X=4.25,	Y=5.5,	W=1,H=1,texture_name=monitor_textures_lt[mem.currentphase.at].."^[transformR270"}) --A
		table.insert(disp,{command="addimage",X=4.5,	Y=2.25,	W=1,H=1,texture_name=monitor_textures_lt[mem.currentphase.bt].."^[transformR180"}) --B
		table.insert(disp,{command="addimage",X=7.75,	Y=2.5,	W=1,H=1,texture_name=monitor_textures_lt[mem.currentphase.ct].."^[transformR90"}) --C
		table.insert(disp,{command="addimage",X=7.5,	Y=5.75,	W=1,H=1,texture_name=monitor_textures_lt[mem.currentphase.dt]}) --D
	elseif mem.monitor == 3 then
		table.insert(disp,{command="addimage",X=4.25,	Y=5.5,	W=1,H=1,texture_name=monitor_textures_ped[mem.currentphase.ap].."^[transformR270"}) --A
		table.insert(disp,{command="addimage",X=4.5,	Y=2.25,	W=1,H=1,texture_name=monitor_textures_ped[mem.currentphase.bp].."^[transformR180"}) --B
		table.insert(disp,{command="addimage",X=7.75,	Y=2.5,	W=1,H=1,texture_name=monitor_textures_ped[mem.currentphase.cp].."^[transformR90"}) --C
		table.insert(disp,{command="addimage",X=7.5,	Y=5.75,	W=1,H=1,texture_name=monitor_textures_ped[mem.currentphase.dp]}) --D
	end
elseif mem.menu == "phaselock" then
	local phaselock_phases = {"Off","Green","Red"}
	if mem.signaltype >= 2 then
		table.insert(phaselock_phases,"Yellow")
		table.insert(phaselock_phases,"FlashRed")
		table.insert(phaselock_phases,"FlashYellow")
	end
	if mem.signaltype == 3 then
		table.insert(phaselock_phases,"FlashGreen")
		table.insert(phaselock_phases,"RedYellow")
	end
	local shortphase_reverse = pivot(shortphases)
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Phase Lock"})
	table.insert(disp,{command="addlabel",X=0,Y=1,label="Straight A"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=1.5,W=2.25,H=1,name="a",selected_id=shortphase_reverse[mem.phaselock.a],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=0,Y=2.5,label="Straight B"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=3,W=2.25,H=1,name="b",selected_id=shortphase_reverse[mem.phaselock.b],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=0,Y=4,label="Straight C"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=4.5,W=2.25,H=1,name="c",selected_id=shortphase_reverse[mem.phaselock.c],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=0,Y=5.5,label="Straight D"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=6,W=2.25,H=1,name="d",selected_id=shortphase_reverse[mem.phaselock.d],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=3,Y=1,label="Left Turn A"})
	table.insert(disp,{command="adddropdown",X=3.1,Y=1.5,W=2.25,H=1,name="at",selected_id=shortphase_reverse[mem.phaselock.at],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=3,Y=2.5,label="Left Turn B"})
	table.insert(disp,{command="adddropdown",X=3.1,Y=3,W=2.25,H=1,name="bt",selected_id=shortphase_reverse[mem.phaselock.bt],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=3,Y=4,label="Left Turn C"})
	table.insert(disp,{command="adddropdown",X=3.1,Y=4.5,W=2.25,H=1,name="ct",selected_id=shortphase_reverse[mem.phaselock.ct],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=3,Y=5.5,label="Left Turn D"})
	table.insert(disp,{command="adddropdown",X=3.1,Y=6,W=2.25,H=1,name="dt",selected_id=shortphase_reverse[mem.phaselock.dt],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=6,Y=1,label="Pedestrian A"})
	table.insert(disp,{command="adddropdown",X=6.1,Y=1.5,W=2.25,H=1,name="ap",selected_id=shortphase_reverse[mem.phaselock.ap],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=6,Y=2.5,label="Pedestrian B"})
	table.insert(disp,{command="adddropdown",X=6.1,Y=3,W=2.25,H=1,name="bp",selected_id=shortphase_reverse[mem.phaselock.bp],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=6,Y=4,label="Pedestrian C"})
	table.insert(disp,{command="adddropdown",X=6.1,Y=4.5,W=2.25,H=1,name="cp",selected_id=shortphase_reverse[mem.phaselock.cp],choices=phaselock_phases})
	table.insert(disp,{command="addlabel",X=6,Y=5.5,label="Pedestrian D"})
	table.insert(disp,{command="adddropdown",X=6.1,Y=6,W=2.25,H=1,name="dp",selected_id=shortphase_reverse[mem.phaselock.dp],choices=phaselock_phases})
	table.insert(disp,{command="addbutton",X=3,Y=7,W=2,H=1,name="save",label="Save"})
	table.insert(disp,{command="addbutton",X=6,Y=7,W=2,H=1,name="cancel",label="Cancel"})
elseif mem.menu == "about" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="About"})
	table.insert(disp,{command="addlabel",X=0,Y=1,label="LTC-4000E"})
	table.insert(disp,{command="addlabel",X=0,Y=1.5,label="A product of Advanced Mesecons Devices, a Cheapie Systems company."})
	table.insert(disp,{command="addlabel",X=0,Y=2,label="This is free and unencumbered software released into the public domain."})
	table.insert(disp,{command="addlabel",X=0,Y=2.5,label="See http://unlicense.org/ for more information."})
	table.insert(disp,{command="addbutton",X=0,Y=7.25,W=2,H=1,name="cancel",label="Back"})
elseif mem.menu == "stats" then
	interrupt(1,"statsrefresh")
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Statistics"})
	table.insert(disp,{command="addbutton",X=2,Y=0,W=2,H=1,name="cancel",label="Back"})
	table.insert(disp,{command="addbutton",X=4,Y=0,W=2,H=1,name="clear",label="Clear"})
	table.insert(disp,{command="addlabel",X=0,Y=1,label="Numbers represent total seconds waiting (for detectors) or total presses (for buttons)"})
	table.insert(disp,{command="addlabel",X=0,Y=2,label="A: "..mem.stats.a})
	table.insert(disp,{command="addlabel",X=0,Y=2.5,label="B: "..mem.stats.b})
	table.insert(disp,{command="addlabel",X=0,Y=3,label="C: "..mem.stats.c})
	table.insert(disp,{command="addlabel",X=0,Y=3.5,label="D: "..mem.stats.d})
	table.insert(disp,{command="addlabel",X=2,Y=2,label="AT: "..mem.stats.at})
	table.insert(disp,{command="addlabel",X=2,Y=2.5,label="BT: "..mem.stats.bt})
	table.insert(disp,{command="addlabel",X=2,Y=3,label="CT: "..mem.stats.ct})
	table.insert(disp,{command="addlabel",X=2,Y=3.5,label="DT: "..mem.stats.dt})
	table.insert(disp,{command="addlabel",X=4,Y=2,label="AP: "..mem.stats.ap})
	table.insert(disp,{command="addlabel",X=4,Y=2.5,label="BP: "..mem.stats.bp})
	table.insert(disp,{command="addlabel",X=4,Y=3,label="CP: "..mem.stats.cp})
	table.insert(disp,{command="addlabel",X=4,Y=3.5,label="DP: "..mem.stats.dp})
	table.insert(disp,{command="addlabel",X=0,Y=4.5,label="Total cycles: "..mem.stats.cycles})
	local timesinceclear = os.time() - mem.stats.lastreset
	local lastclear = "ERROR"
	if timesinceclear < 120 then --Two minutes
		lastclear = math.floor(timesinceclear).." seconds"
	elseif timesinceclear < 7200 then --Two hours
		lastclear = math.floor(timesinceclear/60).." minutes"
	elseif timesinceclear < 172800 then --Two days
		lastclear = math.floor(timesinceclear/3600).." hours"
	else
		lastclear = math.floor(timesinceclear/86400).." days"
	end
	table.insert(disp,{command="addlabel",X=0,Y=5.5,label="Last cleared: "..lastclear.." ago"})
elseif mem.menu == "mode" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Mode / Schedule"})
	table.insert(disp,{command="addlabel",X=0,Y=1,label="Normal Mode"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=1.5,W=2.25,H=1,name="normalmode",selected_id=mem.normalmode,choices=modes})
	table.insert(disp,{command="addlabel",X=0,Y=2.5,label="Scheduled Mode"})
	table.insert(disp,{command="adddropdown",X=0.1,Y=3,W=2.25,H=1,name="schedmode",selected_id=mem.schedmode,choices=modes})
	table.insert(disp,{command="addfield",X=0.5,Y=4.5,W=2,H=1,name="schedstart",label="Schedule Start Hour",default=tostring(mem.schedstart)})
	table.insert(disp,{command="addfield",X=0.5,Y=5.5,W=2,H=1,name="schedend",label="Schedule End Hour",default=tostring(mem.schedend)})
	table.insert(disp,{command="addbutton",X=3,Y=7,W=2,H=1,name="save",label="Save"})
	table.insert(disp,{command="addbutton",X=6,Y=7,W=2,H=1,name="cancel",label="Cancel"})
elseif mem.menu == "diag" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Diagnostics"})
	table.insert(disp,{command="addlabel",X=0,Y=1,label="State: "..(mem.cycle or "Idle")})
	table.insert(disp,{command="addbutton",X=0,Y=2,W=2,H=1,name="startstop",label=(mem.stoptime and "Start Time" or "Stop Time")})
	table.insert(disp,{command="addbutton",X=0,Y=3,W=2,H=1,name="stepnow",label="Next Step"})
	table.insert(disp,{command="addbutton",X=0,Y=5,W=2,H=1,name="reboot",label="Reboot"})
	table.insert(disp,{command="addbutton",X=0,Y=7,W=2,H=1,name="cancel",label="Back"})
elseif mem.menu == "reboot" then
	table.insert(disp,{command="addlabel",X=0,Y=0,label="Rebooting, please wait..."})
	table.insert(disp,{command="addlabel",X=0,Y=0.5,label="This will take about 10 seconds."})
else
	logfault("Unrecognized menu "..mem.menu,false)
	mem.menu = "run"
end
digiline_send("touchscreen",disp)

--Wake up periodically to check schedule
if (mem.schedstart ~= mem.schedend) then
	interrupt(10,"schedcheck")
end
