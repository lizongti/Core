------------------
-- Event Center --
------------------

EventCenter = {
	entry_list = {}
}

EventCenter.event = {}

function EventCenter:Trigger(entry_name, args)
	if entry_name == nil or args == nil then
		return
	end
	if self.entry_list[entry_name] == nil then 
		return
	end
	for k,v in pairs(self.entry_list[entry_name]) do
		if type(v["Entry"]) == "function" then
			LuaSession:Work(function()
				if v:CheckDate() then
					v:Entry(args)
				end
			end)	
		end
	end
end

function EventCenter:Setup(entry_name, task_class)
	if entry_name == nil or task_class == nil then
		return
	end
	if self.entry_list[entry_name] == nil then 
		self.entry_list[entry_name] = {}
	end
	table.insert(self.entry_list[entry_name], task_class)
end

EventBase = {}

function EventBase:New(instance)
	instance = instance or {}
	setmetatable(instance, self)
	self.__index = self
	return instance
end

function EventBase:CheckDate()
	if self.open_session == nil then
		return true
	end
	local now = os.time()

	local function is_time_table_valid(tab)
		if tab and type(tab) == "table" then
			if tab["year"] and tab["month"] and tab["day"] and tab["hour"] and tab["min"] and tab["sec"] then
				return true
			end
		end
		return false
	end

	for k,v in pairs(self.open_session) do
		if is_time_table_valid(v["start"]) and is_time_table_valid(v["finish"]) then
			if os.time(v["start"]) <= now and os.time(v["finish"]) >= now then
				return true
			end
		end
	end
	return false
end

