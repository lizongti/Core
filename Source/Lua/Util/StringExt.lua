function string.split(str, split_char)
	local sub_str_tab = {};
	while true do
		local pos = string.find(str, split_char, nil, true);
		if not pos then
			sub_str_tab[#sub_str_tab + 1] = str;
			break;
		end
		local sub_str = string.sub(str, 1, pos - 1);
		sub_str_tab[#sub_str_tab + 1] = sub_str;
		str = string.sub(str, pos + 1, #str);
	end
	return sub_str_tab;
end

function string.get_readable_number( num, split )
	if not split then
		split = ','
	end
	local str = tostring(num)
	local ret = ''
	local index = 3
	while index < #str do
		ret = split..string.sub(str, -index, -index + 2)..ret
		index = index + 3
	end
	return string.sub(str, 1, -index + 2)..ret
end

function string.encode(value)
	value = string.gsub(value, " ", "@")
	return value
end

function string.decode(value)
	value = string.gsub(value, "@", " ")
	return value
end

function string.check_special_char(str, extra_char)
	if type(str) ~= 'string' then
		return false
	end
    extra_char = extra_char or {}
	local function has_value(index)
		for _, val in pairs(extra_char) do
			if string.byte(val) == index then
				return true
			end
		end
		return false
	end
	for k = 1, #str do
		local c = string.byte(str, k)
		if not c then return false end
		if c <= 47 or (58 <= c and c <= 64) or 
			(91 <= c and c <= 96) or (c >= 123 and c <=127) then
			if not has_value(c) then
				return false
			end
		end
	end
	return true
end

function string.filter_client_string(str)
	local ret = ""
	for k = 1, #str do
		local c = string.byte(str, k)
		if not c then return "" end
		if c >= 48 and c <= 57 or c >= 65 and c <= 90 or c >= 97 and c <= 122 
			or c == 46 or c == 58 or c == 45 then
			ret = ret..string.char(c)
		else
			ret = ret.."_"
		end
	end
	return ret
end

function string.mod(str, mod_count)
	local sum = 0
	for k = 1, #str do
		local c = string.byte(str, k)
		if c then
			sum = sum + c
		end
	end
	return sum % mod_count
end

function string.join(sep, ...)
	return table.concat({...}, sep)
end

function string.chip(chip)
	if chip == 0 then return "0" end
	local neg = false
	if chip < 0 then
		neg = true
		chip = -chip
	end
	local s = tostring(chip)
	local v = ""
	local n = 1
	for i=#s, 1, -1 do
		v = s:sub(i,i)..v
		if n%3 == 0 and n~=#s then
			v = ","..v
		end
		n = n+1
	end
	if neg then
		v = "-"..v
	end
	return v
end

