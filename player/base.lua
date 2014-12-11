--  __  __ _               _      _ _   _   _       _______        _            _____                  
-- |  \/  (_)             | |    (_) | | | | |     |__   __|      | |          |  __ \                 
-- | \  / |_ _ __   ___   | |     _| |_| |_| | ___    | | ___  ___| |_ _   _   | |__) |__  _ __  _   _ 
-- | |\/| | | '_ \ / _ \  | |    | | __| __| |/ _ \   | |/ _ \/ __| __| | | |  |  ___/ _ \| '_ \| | | |
-- | |  | | | | | |  __/  | |____| | |_| |_| |  __/   | |  __/\__ \ |_| |_| |  | |  | (_) | | | | |_| |
-- |_|  |_|_|_| |_|\___|  |______|_|\__|\__|_|\___|   |_|\___||___/\__|\__, |  |_|   \___/|_| |_|\__, |
--                                                                      __/ |                     __/ |
--                                                                     |___/                     |___/ 
--Copyright Jake Vandereay (fyregryph_)
--Licensed as AGPL

--config
local debug = true
local config = {
	pegasusAlt = {--used in alt mode (e key)
		gravity = 0.75,
		jump = 1.5,
	},
	pegasusNormal = {
		gravity = 0.90,
	},
	pegasusFly = { --flight mode (decent)
		gravity = 0.1,
		jump = 0.2,
		speed = 2,
	},
	-- pegasusAscend = { --flight mode (ascent)
	-- 	gravity = -0.4,
	-- },
	earthAlt = {
		speed = 1.5,
	},
	earthNormal = {
		speed = 1.1,
	}
}
local function dbgp(thing) if debug then print("[MTLP base.lua DEBUG] ".. thing) end end
--TODO: encapsulate these global vars into a object

PonyBaseClass = {}
PonyBaseClass.__index = PonyBaseClass

setmetatable(PonyBaseClass, {
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
		return self
	end,
})

function PonyBaseClass:_init(player) --These vars should (maybe) be in the above definition
	dbgp("Base init")
	self.models = {}
	self.player = player
	self.alt = true
	self.physicsDefault = {
		speed = 1.0,
		jump = 1.0,
		gravity = 1.0,
		sneak = true,
		sneak_glitch = false,
	}
	self.physicsAlt = {}
	self.physicsFly = {}
	self.type = "none"
end

function PonyBaseClass:SetSkin(def)
	dbgp("PonyBaseClass:SetSkin def >> "..dump(def)) 
	dbgp("PonyBaseClass:SetSkin player name >> " .. self.player:get_player_name())
	--
	local mdl = def
	self.player:set_properties({
		mesh = mdl.mesh,
		textures = mdl.textures,
		visual = "mesh",
	})
	self.player:set_eye_offset({x=0,y=-1,z=0},{x=0,y=-3,z=0})
	self.player:set_properties({visual_size = {x=2.5, y=2.5},})
	--self.player:set_local_animation({x=130, y=170}, {x=0, y=40}, {x=50, y=70}, {x=80, y=120}, 60)
end
function PonyBaseClass:ModeTglBtn(button) --mode toggle button (combo) handler
	local button = button or false
	-- button logic
	if button == self.lastBtnState then --exit if there is no button change
		return false
	end
	self.lastBtnState = button
	if not button then return end --exit if button is up
	-- cycling logic
	if self.phyMode then self.phyMode = self.phyMode + 1 else self.phyMode = 1 end
	local maxMode = 0
	if self.canFly then maxMode = 3 else maxMode = 2 end
	if self.phyMode > maxMode then self.phyMode = 1 end
	self:PhisicsMode(self.phyMode)
	--
	return true
end
function PonyBaseClass:PhisicsMode(mode)
	local playername = self.player:get_player_name()
	dbgp("player "..playername.." physics mode change")
	--
	if mode == 1 or mode == "normal" then 
		self.phyMode = 1 --save state for cycling logic
		dbgp(playername.." using normal/modified physics")
		minetest.chat_send_player(playername, "Physics mode: "..self.type.."(standard)")
		self.alt = false
		self.player:set_physics_override(self.physicsDefault)
	elseif mode == 2 or mode == "alt" then
		self.phyMode = 2
		dbgp(playername.." using alt physics")
		minetest.chat_send_player(playername, "Physics mode: "..self.type.."(alternate)")
		self.alt = true
		self.player:set_physics_override(self.physicsAlt)
	elseif self.canFly and mode == 3 or mode == "fly" then
		dbgp(playername.." using flight physics")
		minetest.chat_send_player(playername, "Physics mode: "..self.type.."(flight)")
		self.player:set_physics_override(self.physicsFly)
		self.phyMode = 3
		self.flightMode = true
	end
	dbgp("phyMode="..self.phyMode)
end
function PonyBaseClass:FlightAnim( ... )
	return false --disable flight in base by default
end

EarthPony = {}
EarthPony.__index = EarthPony

setmetatable(EarthPony, {
	__index = PonyBaseClass,
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
		return self
	end,
})

function EarthPony:_init(player)
	dbgp("Earth init")
	if player then
		PonyBaseClass:_init(player)
	end
	for k, v in pairs(config.earthAlt) do --TODO: make this a method
		self.physicsAlt[k] = v 
	end
	for k, v in pairs(config.earthNormal) do --TODO: make this a method
		self.physicsDefault[k] = v 
	end
	if player then
		self.type = "earth"
		self:PhisicsMode(1)
	end
end

function EarthPony:SetSkin(def)
	local prop = {mesh = "pony_e.b3d"} -- TODO: use a earth base and just attach horn and wing models.
	for k, v in pairs(def) do
		prop[k] = v
	end
	PonyBaseClass:SetSkin(prop)
end

Unicorn = {}
Unicorn.__index = Unicorn

setmetatable(Unicorn, {
	__index = PonyBaseClass,
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
		return self
	end,
})

function Unicorn:_init(player)
	dbgp("Unicorn init")
	if player then
		PonyBaseClass:_init(player)
	end
	if player then
		self.type = "unicorn"
		self:PhisicsMode(1)
	end
end

function Unicorn:SetSkin(def) --get rid of this
	local prop = {mesh = "pony_u.b3d"}
	for k, v in pairs(def) do
		prop[k] = v
	end
	PonyBaseClass:SetSkin(prop)
end

Pegasus = {}
Pegasus.__index = Pegasus

setmetatable(Pegasus, {
	__index = PonyBaseClass,
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
		return self
	end,
})

function Pegasus:_init(player) 
	dbgp("Pegasus init")
	if player then
		PonyBaseClass:_init(player)
	end
	for k, v in pairs(config.pegasusFly) do --TODO: make this a method
		self.physicsFly[k] = v 
	end
	for k, v in pairs(config.pegasusAlt) do
		self.physicsAlt[k] = v 
	end
	for k, v in pairs(config.pegasusNormal) do
		self.physicsDefault[k] = v 
	end
	if player then
		self.type = "pegasus"
		self:PhisicsMode(1)
	end
	self.canFly = true
	self.phyModeLast = 0
	self.animations = {
		flap = {x = 170, y = 190},
		fly  = {x = 200, y = 220},
		baseSpeed = 60,
	}
	self.ascendAnimState = ""
	self.models = {std = "pony_p.b3d", fly = "pony_p_f.b3d"}
end

function Pegasus:FlightControl(ascend, descend) --fly button handler
	if self.phyMode ~= 3 then return end
	if ascend then
		self.player:set_physics_override({gravity = -0.5})
	elseif descend then
		self.player:set_physics_override({gravity = 0.35})
	else
		self.player:set_physics_override(config.pegasusFly)
	end
end

function Pegasus:FlightAnim(player, control) --not clean
	--quick hack
	--TODO, get a better grasp of Lua OOP, instance vars are not working correctly. Make a proper constructor
	PonyBaseClass.player = player
	--
	if not player then minetest.log("error", "ponyobject with nil player"); return false end
	local pos = player:getpos()
		  pos.y = pos.y - 1.5
	local isAirborn = (minetest.get_node(pos).name == "air")
	--if isAirborn then dbgp("is airborn") end
	--
	if not isAirborn or self.phyMode ~= 3 then
	-- if self.phyMode ~= 3 then
		if not isAirborn and self.wasAirborn or self.phyModeLast ~= self.phyMode then
			PonyBaseClass:SetSkin({mesh = self.models.std})
			dbgp("flight animation unset, using model " .. self.models.std)
		end
		self.phyModeLast = self.phyMode
		self.wasAirborn = isAirborn

		return false 
	end
	if isAirborn and not self.wasAirborn or self.phyModeLast ~= self.phyMode then
		PonyBaseClass:SetSkin({mesh = self.models.fly})
		dbgp("flight animation set, using model " .. self.models.fly)
		dbgp("passed player name: "..player:get_player_name())
		dbgp("stored player name: "..self.player:get_player_name())
	end
	self.phyModeLast = self.phyMode
	self.wasAirborn = isAirborn

	-- dbgp("flight anim model used")
	if control.jump and self.ascendAnimState ~= "up" then 
		dbgp("ascend anim")
		self.ascendAnimState = "up"
		player:set_animation(self.animations.fly, 60, 0)
		player:set_local_animation(self.animations.fly, self.animations.fly, self.animations.fly, self.animations.fly, self.animations.baseSpeed)
	elseif not control.jump and self.ascendAnimState ~= "down" then
		dbgp("descend anim")
		self.ascendAnimState = "down"
		player:set_animation(self.animations.fly, 30, 0)
		player:set_local_animation(self.animations.fly, self.animations.fly, self.animations.fly, self.animations.fly, self.animations.baseSpeed * 0.5)
	end
	return true
end

function Pegasus:SetSkin(def)
	local prop = {mesh = "pony_p.b3d"}
	for k, v in pairs(def) do
		prop[k] = v
	end
	PonyBaseClass:SetSkin(prop)
end

Alicorn = {}
Alicorn.__index = Alicorn

setmetatable(Alicorn, {
	__index = function(table, key)
		for i,s in ipairs({EarthPony, Unicorn, Pegasus}) do
			if s[key] then
				table[key] = s[key]
				return table[key]
			end
		end
	end,
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)
		return self
	end,
})

function Alicorn:_init(player) 
	PonyBaseClass:_init(player)
	EarthPony:_init()
	Pegasus:_init()
	Unicorn:_init()
	--
	self.type = "alicorn"
	self.canFly = true
	self.models = {std = "pony_a.b3d", fly = "pony_a_f.b3d"}
	self:PhisicsMode(1)
end

function Alicorn:FlightAnim( ... )
	return Pegasus.FlightAnim(self, ...)
end

function Alicorn:SetSkin(def) --get rid of this
	local prop = {mesh = "pony_a.b3d"}
	for k, v in pairs(def) do
		prop[k] = v
	end
	PonyBaseClass:SetSkin(prop)
end

