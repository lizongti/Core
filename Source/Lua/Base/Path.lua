-----------------
--     Path    --
-----------------
Base.Enviroment.package_path =
{
	"/usr/local/lib/lua/5.1/",
	"/usr/local/lib/lua/5.1/protobuf/",
	"/usr/lib/lua/5.1/",
	"/usr/share/lua/5.1/",
	Base.Enviroment.cwd.."/../Source/Lua/",
}
Base.Enviroment.package_cpath = 
{
	"/usr/local/lib/lua/5.1/protobuf/",
	"/usr/lib/lua/5.1/",
	"/usr/local/lib64/lua/5.1/",
	"/usr/local/lib64/",
	"/usr/local/lib/",
	"/usr/lib64/lua/5.1/",
    "/usr/local/lib/lua/5.1/",
	"/usr/lib64/",
	"/usr/lib/"
}
package.path = package.path..";"
for _,path in pairs(Base.Enviroment.package_path) do
	package.path = package.path .. path .. "?.lua;"
end
package.cpath = package.cpath..";"
for _,cpath in pairs(Base.Enviroment.package_cpath) do
	package.cpath = package.cpath .. cpath .. "?.so;"
end
