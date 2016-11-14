--This is built off cave realms
-- Parameters
caverealms = {}
hell = {}
hell.sky_color_timer = 0

-- -0.5 massive lava sea and lots of space
-- 0 for huge caves
-- 0.5 for smaller caves
local TCAVE = 0

local BLEND = 128 -- Cave blend distance near YMIN, YMAX

--local DM_TOP = caverealms.config.dm_top -- -4000 --level at which Dungeon Master Realms start to appear
--local DM_BOT = caverealms.config.dm_bot -- -5000 --level at which "" ends
--local DEEP_CAVE = caverealms.config.deep_cave -- -7000 --level at which deep cave biomes take over

-- 3D noise for caves

local np_cave = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=256, z=512}, -- squashed 2:1
	seed = 59033,
	octaves = 6,
	persist = 0.63
}


-- Stuff

subterrain = {}
local YMAX = -20000
local YMIN = -30000
local lava_level = -25000

local yblmin = YMIN + BLEND * 1.5
local yblmax = YMAX - BLEND * 1.5

minetest.register_on_generated(function(minp, maxp, seed)
	--if out of range of caverealms limits
	if minp.y > YMAX or maxp.y < YMIN then
		return --quit; otherwise, you'd have stalagmites all over the place
	end

	--easy reference to commonly used values
	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	print ("Hell generated at ("..x0.." "..y0.." "..z0..")") --tell people you are generating a chunk
	
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	--grab content IDs
	local c_air = minetest.get_content_id("air")
	local c_lava = minetest.get_content_id("default:lava_source")
	local c_netherrack = minetest.get_content_id("hell:netherrack")
	
	--mandatory values
	local sidelen = x1 - x0 + 1 --length of a mapblock
	local chulens = {x=sidelen, y=sidelen, z=sidelen} --table of chunk edges
	local chulens2D = {x=sidelen, y=sidelen, z=1}
	local minposxyz = {x=x0, y=y0, z=z0} --bottom corner
	
	local nvals_cave = minetest.get_perlin_map(np_cave, chulens):get3dMap_flat(minposxyz) --cave noise for structure
	
	local nixyz = 1 --3D node index
	
	--generate lava check
	local lava_generation = false
	if maxp.y < lava_level then
		lava_generation = true
	end
	
	for z = z0, z1 do -- for each xy plane progressing northwards
		--structure loop
		for y = y0, y1 do -- for each x row progressing upwards		
			local vi = area:index(x0, y, z) --current node index
			--print(nvals_cave[nixyz]*10000, tcave)
			for x = x0, x1 do --Times 10000 for massive caves
				--print(nvals_cave[nixyz])
				if nvals_cave[nixyz] > TCAVE then --if node falls within cave threshold
					--if below lava level then generate lava
					if lava_generation == true then
						data[vi] = c_lava
					else
						data[vi] = c_air --hollow it out to make the cave
					end
				else
					--create cave structure
					data[vi] = c_netherrack
				end
				--increment indices
				nixyz = nixyz + 1
				vi = vi + 1
			end
		end
	end
	
	--send data back to voxelmanip
	vm:set_data(data)
	
	--calc lighting
	--vm:set_lighting({day=1, night=0})
	--vm:calc_lighting()
	
	--write it to world
	vm:write_to_map(data)

	local chugent = math.ceil((os.clock() - t1) * 1000) --grab how long it took
	print ("Hell generated chunk in "..chugent.." ms") --tell people how long
end)

--the player's default sky color
minetest.register_on_joinplayer(function(player)
	local pos = player:getpos().y
	if pos < YMAX and pos > YMIN then
		print("set player to hell color")
		player:set_sky({r=66, g=0, b=0},"plain",{})
	end
end)

--this changes the player's sky color to red
minetest.register_globalstep(function(dtime)
	hell.sky_color_timer = hell.sky_color_timer + dtime
	if hell.sky_color_timer >= 10 then
		for i, player in pairs(minetest.get_connected_players()) do
			local pos = player:getpos().y
			if pos < YMAX and pos > YMIN then
				print("set player to hell color")
				player:set_sky({r=66, g=0, b=0},"plain",{})
			else
				--if not in hell, change back to default sky
				player:set_sky({r=0, g=0, b=0},"regular",{})
			end
		end
		hell.sky_color_timer = 0
	end
end)


minetest.register_node("hell:netherrack", {
	description = "Netherrack",
	tiles = {"nether_rack.png"},
	is_ground_content = true,
	groups = {cracky = 3, level = 2},
	light_source = 10,
	paramtype = "light",
	sounds = default.node_sound_stone_defaults(),
})
