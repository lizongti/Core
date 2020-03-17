---------------
-- Container --
---------------
require "Base/HashCache"
require "Util/PrintExt"

_G.Container = {
    repo = {},
	cache = {},
}

function Container:LoadFinished()
	local all_loaded = true
	for repo_name, _ in pairs(self.cache) do
		if self.cache[repo_name].load_finished == false then
			all_loaded = false
			break
		end
	end
	return all_loaded
end

function Container:CheckLoadFinished(repo_name)
	return self.cache[repo_name] and self.cache[repo_name].load_finished or false
end

function Container:Get(repo_name, use_cache)
	self.repo[repo_name] = self.repo[repo_name] or {}
    return self.repo[repo_name]
end

function Container:GetHash(repo_name, load_finished_callback)
	self.repo[repo_name] = self.repo[repo_name] or HashCache:InitNewHash(repo_name)
	self.cache[repo_name] = self.cache[repo_name] or {
		loaded = false,
		load_finished = false,
		load_finished_callback = load_finished_callback,
	}
	return self.repo[repo_name]
end

function Container:Update(session)
	for repo_name, _ in pairs(self.cache) do
		Container:LoadCache(session, repo_name)
	end
	for repo_name, _ in pairs(self.cache) do
		Container:StoreCache(session, repo_name)
	end
end

function Container:LoadCache(session, repo_name)
	if self.cache[repo_name].loaded == true then
		return
	end

	self.cache[repo_name].loaded = true

	local task = Task:New()
	task:Init(function()
		local hash = Container:Get(repo_name)
		local async_request = HashCache:GetBuildCommand(repo_name)
		local async_response = session:ContactJson("CacheClientService", task, async_request, repo_name)
		hash = HashCache:BuildHash(async_response, repo_name, hash)
		Container.cache[repo_name].load_finished = true
		if Container.cache[repo_name].load_finished_callback then
			Container.cache[repo_name].load_finished_callback(hash)
		end
	end)
	task:Start()
	return hash
end

function Container:StoreCache(session, repo_name)
	local hash = Container:Get(repo_name)
	if not hash then
		return
	end
	local async_request = HashCache:GetActionCommand(hash)
	if #async_request == 0 then
		return
	end
	local task = Task:New()
	task:Init(function()
		session:ContactJson("CacheClientService", task, async_request, repo_name)
	end)
	task:Start()
end