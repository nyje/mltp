--config
local defaultPony = "MineLP_Daring_Do.png"

local debug = false

---
local function dbgp(thing) if debug then print("[MTLP init.lua DEBUG] ".. thing) end end

PonyPlayer = { --main wrapper/interface object
	saveFile = minetest.get_worldpath() .. "/playermodels.txt",
	skinList = minetest.get_modpath("player") .. "/textures/skinlist.txt",
	users = {},
	animList = {
		stand = {x=130, y=170}, 
		walk = {x=0, y=40}, 
		mine = {x=50, y=70}, 
		mine_walk = {x=80, y=120},
	},
	player_anim = {},
	player_sneak = {},
	animBlend = 0,
	skins = {},
	__index = PonyPlayer,
}

function PonyPlayer:Main( ... )
	local dname = defaultPony --default pony
	
	self:Load()
	self:BuildSkinList()
	minetest.register_on_joinplayer(function (player) 
		
		local pname = player:get_player_name()
		if self.users[pname] then
			self:SetSkin(player, self.users[pname].name)
		else
			self:SetSkin(player, dname) --set initial skin
		end
	end)

	minetest.register_on_leaveplayer(function (player)
		local pname = player:get_player_name()
		self.users[pname].model = nil
	end)

	minetest.register_chatcommand("skin", {
		params = "<name> <text>",
		description = "Change pony skin",
		privs = {interact = true},
		func = function(playername, skinname) 
			local player = minetest.get_player_by_name(playername)
			dbgp("/skin called on/by "..playername)
			return self:SetSkin(player, skinname)
		end,
	})
	minetest.register_chatcommand("skins", {
		params = "<player>",
		description = "list pony skins",
		func = function(player) 
			local msg = ""
			for k, v in pairs(self.skins) do
				if not v.secret then
					msg = msg .. v.name .. " "
				end
			end
			minetest.chat_send_player(player, msg)
		end,
	})
	if unified_inventory then
		unified_inventory.register_button("skin_menu", {
			type = "image",
			image = "button.png",
		})
		unified_inventory.register_page("skin_menu", {
			get_formspec = function(player)
				local pname = player:get_player_name()
				local index = 0
				local count = 1
				local skinsfs = ''
				for index, name in pairs(self.skins.lut) do
					local skin = self:GetSkin(name)
					--
					if not skin then print("[MTLP] error, fetching skin for "..name.." failed"); break end
					--
					if skinsfs ~= '' then
						skinsfs = skinsfs .. "," .. skin.name
					else
						skinsfs = skin.name
					end
					if skin.name == self.users[pname].name then
						self.users[pname].index = count
					end
					count = count + 1
				end
				if not self.users[pname].index then self.users[pname].index = 1 end --fallback index
				--TODO Only use the index here once
				local formspec = "textlist[0,0;6,8;mltp:skin_list;"..skinsfs..";"..self.users[pname].index ..";true]"	
				return {formspec = formspec}			
			end,
			transparent = true
		})
	end
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if fields["mltp:skin_list"] == nil then return end
	    -- print("Form " .. formname .. " Player "..player:get_player_name().." submitted fields "..dump(fields))
	    -- self:SetSkin(self.skins[string.split(fields["mltp:skin_list"], ":")[2]].name)
	    local skinindex = tonumber(string.split(fields["mltp:skin_list"], ":")[2])
	    local skin = self:GetSkin(skinindex)
	    --set selected skin GUI index here
	    self:SetSkin(player, skin.name)
	    return true
	end)

	local player_set_animation = self.player_set_animation

	-- Check each player and apply animations
	minetest.register_globalstep(function(dtime) --adapted from the default player.lua
		for _, player in pairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local model = self.users[name].name
			local ponyObject = self.users[name].model
			--ponyObject.player = player--CHANGEME
			if model and ponyObject then
				local controls = player:get_player_control()
				local walking = false
				local animation_speed_mod = model.animation_speed or 30

				---pony stuff
				local altCombo = controls.sneak and controls.aux1
				ponyObject:ModeTglBtn(altCombo) 

				if ponyObject.Pony.canFly then
					ponyObject:FlightControl(controls.jump, controls.sneak)
				end

				if not ponyObject:FlightAnim(controls) then --offload control and animation handling to ponyObject

					--end pony stuff, sort of
					-- Determine if the player is walking
					if controls.up or controls.down or controls.left or controls.right then
						walking = true
					end

					-- Determine if the player is sneaking, and reduce animation speed if so
					if controls.sneak then
						animation_speed_mod = animation_speed_mod / 2
					end

					-- Apply animations based on what the player is doing
					-- if player:get_hp() == 0 then
						-- player_set_animation(self, player, "lay")
					if walking then
						if self.player_sneak[name] ~= controls.sneak then
							self.player_anim[name] = nil
							self.player_sneak[name] = controls.sneak
						end
						if controls.LMB then
							player_set_animation(self, player, "walk_mine", animation_speed_mod)
						else
							player_set_animation(self, player, "walk", animation_speed_mod)
						end
					elseif controls.LMB then
						player_set_animation(self, player, "mine")
					else
						player_set_animation(self, player, "stand", animation_speed_mod)
					end
				end
			end
		end
	end)
end

function PonyPlayer:BuildSkinList() 
	local input = io.open(self.skinList, 'r')
	local data = nil
	local count = 1
	--- print(data)
	if input then
		data = input:read('*all')
	end
	if data and data ~= "" then
		lines = string.split(data,"\n")
		self.skins.skin = {}
		self.skins.lut = {}
		for _, line in ipairs(lines) do
			local data = string.split(line, ' ', 2)
			local name = data[1]
			local type = data[2]
			self.skins.skin[name] = {
				name = name,
				type = type,
				textures = name
			}
			self.skins.lut[count] = name --create index for skins
			count = count + 1
		end
		io.close(input)
	end
end

function PonyPlayer:GetSkin(arg) --return the properties of a skin my index of name
	if type(arg) == "number" then
		return self.skins.skin[self.skins.lut[arg]]
	elseif type(arg) == "string" then
		local val = self.skins.skin[arg]
		if val then return val end
	end
	print("[MLTP] PonyPlayer:GetSkin skin lookup failed, arg = " .. dump(arg))
	return false --on failure
end

function PonyPlayer.player_set_animation(self, player, anim_name, speed)
	local name = player:get_player_name()
	if self.player_anim[name] == anim_name then
		return
	end
	local model = self.users[name].name
	if not (model and self.animList[anim_name]) then
		return
	end
	local anim = self.animList[anim_name]
	self.player_anim[name] = anim_name
	player:set_animation(anim, speed or model.animation_speed, self.animBlend)
end

function PonyPlayer:Load() --adapted from mod-models
	local input = io.open(self.saveFile, 'r')
	local data = nil
	if input then
		data = input:read('*all')
	end
	if data and data ~= "" then
		lines = string.split(data,"\n")
		for _, line in ipairs(lines) do
			data = string.split(line, ' ', 2)
			self.users[data[1]] = {name = data[2]}
		end
		io.close(input)
	end
end

function PonyPlayer:Save() --adapted from mod-models
	local output = io.open(self.saveFile,'w')
	for name, info in pairs(self.users) do
		skin = info.name
		if name and skin then
			-- print("Save: " .. name .. " " .. skin )
			output:write(name .. " " .. skin .. "\n")
		end
	end
	io.close(output)
end

function PonyPlayer:SetSkin(player, name) 
	-- local index = 1
	local pname = player:get_player_name()
	dbgp("PonyPlayer:SetSkin called on "..pname)
	local model = nil
	-- for k, v in pairs(self.skins.skin) do
	-- 	if v.name == name then
	-- 		model = v
	-- 		break
	-- 	end
	-- end
	model = self:GetSkin(name)
	---
	-- local model = self.skins[index]
	local skin
	---
	if not (model) then
		print("[MLTP] PonyPlayer:SetSkin skin not found || player "..pname)
		return false, "Skin not found"
	end
	---
	local type = model.type
	if type == "earth" then
		skin = EarthPony(player)
	elseif type == "unicorn" then
		skin = Unicorn(player)
	elseif type == "pegasus" then 
		skin = Pegasus(player)
	elseif type == "alicorn" then
		skin = Alicorn(player)
	else 
		print("[MLTP] PonyPlayer:SetSkin model type error || player "..pname)
		return false, "model type error"
	end
	---
	skin:SetSkin({textures = {model.textures}})
	---
	self.users[player:get_player_name()] = {name = model.name, model = skin}
	self:Save()
	--
	dbgp("saved pony type: "..self.users[player:get_player_name()].model.Pony.type)
	--
	return true, "Skin " .. model.name .. " set!"
end

PonyPlayer:Main()