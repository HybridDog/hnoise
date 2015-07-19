--V2

local load_time_start = os.clock()

local function get_random(a, b, seed)
	return PseudoRandom(math.abs(a+b*50)+seed)
end

local r_chs = {}

local function hnoise_single(t)
	local t1 = os.clock()

	local s = t.scale
	if not r_chs[s] then
		r_chs[s] = math.floor(s/3+0.5)
	end
	local minp = t.minp
	local seed = t.seed
	local size = t.size
	--local height = t.height or 10

	size = size or 15
	local r_ch = r_chs[s]
	local maxp = vector.add(minp, size)

	local tab = {}
	local sm = t.range or (s+r_ch)*2
	for z = -sm, size+sm do
		local pz = z+minp.z
		if pz%s == 0 then
			for x = -sm, size+sm do
				local px = x+minp.x
				if px%s == 0 then
					local pr = get_random(px, pz, seed)
					local pstring = px+pr:next(-r_ch, r_ch).." "..pz+pr:next(-r_ch, r_ch)
					tab[pstring] = pr:next(0, s)
				end
			end
		end
	end

	s = s+r_ch

	local s_max = math.sqrt(2)*s

	local tab2,n = {},1
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local h = 0
			for p,h2 in pairs(tab) do
				local x2,z2 = unpack(string.split(p, " "))
				x2 = math.abs(x2-x)
				z2 = math.abs(z2-z)
				if x2 <= s
				and z2 <= s then
					local dist = math.hypot(z2, x2)
					dist = dist-h2
					dist = s*math.acos(dist/s)/(0.5*math.pi)
					h = math.max(h, dist)
				end
			end
			--[[for z2 = -s, s do
				for x2 = -s, s do
					local h2 = tab[x+x2.." "..z+z2]
					if h2 then
						--local dist = math.max(math.abs(z2), math.abs(x2))
						local dist = math.hypot(z2, x2)
						dist = dist-h2
						--h2 = 10-dist
						h = math.max(h, dist)
					end
				end
			end]]
			h = h/s_max-- -0.5
			--tab2[n] = {x=x, y=maxp.y-h, z=z}
			tab2[n] = {x=x, y=h, z=z}
			n = n+1
		end
	end
	print(string.format("[hnoise] calculated after ca. %.2fs", os.clock() - t1))
	return tab2
end

function hnoise(t)
	local n1 = hnoise_single(t)
	t.seed = t.seed+1
	local n2 = hnoise_single(t)
	t.seed = t.seed-1
	for i = 1,#n1 do
		n1[i].y = (n1[i].y-n2[i].y)*2
	end
	return n1
end

--[[
local function dif(z1, z2)
	return math.abs(z1-z2)
end

local function pymg(x1, x2, z1, z2)
	return math.max(dif(x1, x2), dif(z1, z2))
end

local function romg(x1, x2, z1, z2)
	return math.hypot(dif(x1, x2), dif(z1, z2))
end

local function py2mg(x1, x2, z1, z2)
	return dif(x1, x2) + dif(z1, z2)
end--] ]

minetest.register_node(":ac:hmg", {
	description = "hmg",
	tiles = {"ac_block.png"},
	groups = {snappy=1,bendy=2,cracky=1},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)
		local minp = vector.chunkcorner(pos)
		for _,p in pairs(hnoise({minp=minp, scale=10, seed=8})) do
			p.y = minp.y+p.y*10
			for y = p.y, p.y+3 do
				p.y = y -- might not work with luajit
				minetest.set_node(p, {name="default:desert_stone"})
			end
			--[[local p2 = {x=p.x, y=p.y+1, z=p.z}
			if p.y <= minp.y+7 then
				local p2 = {x=p.x, y=minp.y+6, z=p.z}
				local p3 = {x=p.x, y=p2.y+1, z=p.z}
				if minetest.get_node(p2).name ~= "default:desert_stone" then
					minetest.set_node(p2, {name="default:desert_stone"})
				end
				if minetest.get_node(p3).name ~= "default:desert_sand" then
					minetest.set_node(p3, {name="default:desert_sand"})
				end
			else
				if minetest.get_node(p).name ~= "default:desert_stone" then
					minetest.set_node(p, {name="default:desert_stone"})
				end
			end] ]
		end
	end,
})-- ]]


local dogen = false
if dogen then

minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode", flags="nolight"})
end)

local heights = {}
local function get_mapgen_heights(minp)
	local pstr = minp.x .. minp.z
	local done = heights[pstr]
	if done then
		return done
	end

	minp = {x=minp.x,y=0,z=minp.z}
	local tab = {}
	local noise_giant = hnoise({minp=minp, scale=3000, seed=55, size=79})
	local noise_big = hnoise({minp=minp, scale=2000, seed=36, size=79})
	local ps = hnoise({minp=minp, scale=100, seed=8, size=79})
	local noise_fine = hnoise({minp=minp, scale=10, seed=324, size=79})

	for n,p in pairs(ps) do
		local ytop = p.y*30
		ytop = ytop+noise_giant[n].y*1000
		ytop = ytop+noise_big[n].y*1000
		ytop = ytop+noise_fine[n].y*8
		ytop = math.floor(ytop+0.5)
		tab[n] = {p.x, ytop, p.z}
	end

	heights[pstr] = tab
	return tab
end

local c_stone = minetest.get_content_id("default:stone")
local c_grass = minetest.get_content_id("default:dirt_with_grass")

minetest.register_on_generated(function(minp, maxp, seed)
	local ps = get_mapgen_heights(minp)

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	for _,p in pairs(ps) do
		local x,ytop,z = unpack(p)
		if minp.y <= ytop then
			local rand = math.max(0, ytop-1500)
			local grass = rand == 0
			if not grass then
				local rand = rand/200
				grass = rand < 1
				if grass then
					grass = math.random() < rand
				end
			end
			for y = minp.y, maxp.y do
				if y == ytop then
					if grass then
						data[area:index(x,y,z)] = c_grass
					end
					break
				end
				data[area:index(x,y,z)] = c_stone
			end
		end
	end

	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map()
end)

end


print(string.format("[hnoise] loaded after ca. %.2fs", os.clock() - load_time_start))
