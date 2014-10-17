--V1
local function get_random(a, b, seed)
	return PseudoRandom(math.abs(a+b*5)+seed)
end

local r_chs = {}

local function hnoise_single(minp, s, seed, range, scale)
	if not r_chs[s] then
		r_chs[s] = math.floor(s/3+0.5)
	end
	scale = scale or 15
	local r_ch = r_chs[s]
	local maxp = vector.add(minp, scale)

	local tab = {}
	local sm = range or (s+r_ch)*2
	for z = -sm, scale+sm do
		local pz = z+minp.z
		if pz%s == 0 then
			for x = -sm, scale+sm do
				local px = x+minp.x
				if px%s == 0 then
					local pr = get_random(px, pz, seed)
					local pstring = px+pr:next(-r_ch, r_ch).." "..pz+pr:next(-r_ch, r_ch)
					tab[pstring] = pr:next(0, 10)
				end
			end
		end
	end

	local tab2,n = {},1
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			local h = 0
			for z2 = -10, 10 do
				for x2 = -10, 10 do
					local h2 = tab[x+x2.." "..z+z2]
					if h2 then
						local dist = math.max(math.abs(z2), math.abs(x2))
						dist = dist-h2
						--h2 = 10-dist
						h = math.max(h, dist)
					end
				end
			end
			--tab2[n] = {x=x, y=maxp.y-h, z=z}
			tab2[n] = {x=x, y=h, z=z}
			n = n+1
		end
	end
	return tab2
end

local function hnoise(minp, s, seed, range, scale)
	local n1 = hnoise_single(minp, s, seed, range, scale)
	local n2 = hnoise_single(minp, s, seed+1, range, scale)
	for i = 1,#n1 do
		n1[i].y = (n1[i].y+n2[i].y)/2
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
end]]

minetest.register_node(":ac:hmg", {
	description = "hmg",
	tiles = {"ac_block.png"},
	groups = {snappy=1,bendy=2,cracky=1},
	sounds = default_stone_sounds,
	on_construct = function(pos)
		local minp = vector.chunkcorner(pos)
		for _,p in pairs(hnoise(minp, 10, 8)) do
			p.y = minp.y+p.y
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
			end]]
		end
	end,
})
