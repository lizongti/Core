--math.randomseed(os.time())  
math.randomseed(tostring(os.time()):reverse():sub(1, 7))

local a = 16807
local m = 2147483647
local b = 0--1013904223

--用法：
--     1.无参调用，math.random_ext(player) 产生[0, 1)之间的浮点随机数。
--
--　　　2.一个参数n，math.random_ext(player, n) 产生[1, n]之间的整数。
--
--　　　3.两个参数，math.random_ext(player, n, m) 产生[n, m]之间的整数。
math.random_ext = function(...)
	local arg = {...}
	local player = arg[1]
	if (player.character.rand_seed == 0) then
		player.character.rand_seed = player.id
	end

	player.character.rand_seed = math.fmod(a * player.character.rand_seed + b, m)
	player.character.rand_num = player.character.rand_num + 1

	if (#arg == 1) then
		local value = math.mod(player.character.rand_seed, 100)
		return value / 100
	elseif (#arg == 2) then
		local max = arg[2]
		local value = math.mod(player.character.rand_seed, max)
		return value + 1
	elseif (#arg == 3) then
		local min = arg[2]
		local max = arg[3]
		local value = math.mod(player.character.rand_seed, max - min + 1)
		return value + min
	end
end

math.log2 = function (a, b)
	return math.log(a)/math.log(b)
end

--给出一个概率计算是否触发
math.rand_prob = function(player, prob)
	local rand1 = math.random_ext(player, 0, 255)
	local rand2 = math.random_ext(player, 0, 255)
	local rand3 = math.random_ext(player, 0, 255)
	local rand4 = math.random_ext(player, 0, 255)
	return (rand1 * 16777216 + rand2 * 65536 + rand3 * 256  + rand4 + 1) <= 4294967296 * prob 
end
--给出一个概率表计算触发表里的哪一个对象 如：{[1]=0.1,[2]=0.2,[3]=0.3,[4]=0.4}
--通过对应value的概率值计算触发哪一个key
math.rand_weight = function(player, tab)
	if type(tab) ~= "table" then
		return
	end

	local rand_num = 0
	if (player == nil) then
		local rand1_1 = math.random(0, 255)
		local rand2_2 = math.random(0, 255)
		local rand3_3 = math.random(0, 255)
		local rand4_4 = math.random(0, 255)
		rand_num = rand1_1 * 16777216 + rand2_2 * 65536 + rand3_3 * 256  + rand4_4 + 1
	else
		local rand1 = math.random_ext(player, 0, 255)
		local rand2 = math.random_ext(player, 0, 255)
		local rand3 = math.random_ext(player, 0, 255)
		local rand4 = math.random_ext(player, 0, 255)	
		rand_num = rand1 * 16777216 + rand2 * 65536 + rand3 * 256  + rand4 + 1
	end

	local sum = 0
	local weight = 0
	for k,v in pairs(tab) do
		sum = sum + v
	end
	local last_key
	for k,v in pairs(tab) do
		weight =  v * 4294967296 / sum 
		if rand_num <= weight then
			return k
		end
		rand_num = rand_num - weight
		last_key = k
	end
	return last_key
end

math.rand_weights = function(player, weights, count)
	local r = {}
	
	for i=1, count do
		local index = math.rand_weight(player, weights)
		table.insert(r, index)
		weights[index] = 0
	end

	return r
end

math.unrepeated_random_set = function(limit)
	local rand = {}
	local i = 1
	while i <= limit do
		rand[i] = i
		i = i + 1
	end
	-- math.randomseed(os.time())
	local random_num
	i = 1
	local temp
	while i < limit do
		random_num = math.random(1, limit + 1 - i)
		temp = rand[random_num]
		rand[random_num] = rand[limit + 1 - i]
		rand[limit + 1 - i] = temp
		i = i + 1
	end
	return rand
end

math.disorder_table = function(tab)
	local tab_rand_weight = {}
	local count = 1
	for k, v in pairs(tab) do
		tab_rand_weight[count] = {
			rand = math.random(),
			value = v
		}
		count = count + 1
		tab[k] = nil
	end
	table.sort(tab_rand_weight, function(alpha, beta)
		return alpha.rand > beta.rand
	end)
	for k,v in pairs(tab_rand_weight) do
		tab[k] = tab_rand_weight[k].value
	end

	return tab
end
--返回一个值4舍5入
math.round = function ( value )
	return math.floor(value + 0.5)
end

----将table_list的排序打乱
math.rand_table = function(player, table_list)
	local rand_list = {}
	local random_tab = {}
	for i = 1, #table_list do
		table.insert(random_tab, 0.1)
	end

	local is_end = false
	while (not is_end) do
		local rad_index = math.rand_weight(player, random_tab)
		table.insert(rand_list, table_list[rad_index])
		random_tab[rad_index] = 0
		is_end = true
		for i = 1, #table_list do
			if (random_tab[i] ~= 0) then
				is_end = false
			end
		end
	end
	return rand_list
end

--简单计算万分之一的概率触发事件
math.rand_event = function(player, event_probability)
	return math.random_ext(player, 1,10000) <= event_probability * 10000
end

--最小数值和最大数值指定返回值的范围
math.clamp = function(value, min_value, max_value)
	if(value < min_value) then
		return min_value
	elseif(value > max_value) then
		return max_value
	else
		return value
	end
end

math.transform_hash = function(hash)
	if type(hash) == "number" then
		return hash
	elseif type(hash) == "string" then
		local sum = 0
		for _, v in pairs({string.byte(hash, 1, string.len(hash))}) do  
			sum = sum + v
		end
		return sum
	end
end

math.mod = function(a, b) 
	return a % b
end

math.rand_config = function(player, configs, key)
	local weights = {}
	for i=1, #configs do
		table.insert(weights, configs[i][key])
	end
	local index = math.rand_weight(player, weights)
	return configs[index], index
end