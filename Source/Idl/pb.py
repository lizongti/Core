import os
import re

# function pbload: register(file)
#    if not ends_with(file, ".proto") then
#        return
#     end
#     local f = io.open(file)
#     local s = f: read("*a")
#     local iter = s: gmatch("import%s+\"(%w+%.proto)")
#     for w, v in iter do
#         self: register("slotc/Protobuf/"..w)
#     end
#     local v = file: gsub("Protobuf", "pb")..".pb"
#     if not reg[v] then
#        pb.register_file(v)
#     end
#     reg[v] = true
# end

def register(path, l):
    with open(path, 'r') as f:
        data = f.read()
        m = re.findall("import\s+\"(\w+\.proto)", data)
        if m:
            for k in m:
                register(k, l)
    l.append(path)

def run():
    l = []
    w = []
    os.chdir("Protobuf")
    files = os.listdir(".")
    for k in files:
        if k.endswith(".proto"):
            val = "protoc --descriptor_set_out ../../Lua/pb/%s.pb %s" % (k, k)
            print(val)
            os.system(val)
            register(k, l)
            with open(k, 'r') as f:
                data = f.read()
    s = ""
    for word in l:
        if word not in w:
            w.append(word)
            print(word+".pb")
            s += "\t\""+word+".pb\",\n"
    os.chdir("..")
    f = open("../Lua/Protocol/pbgen.lua", "w")
    f.write("pbc_gen ={\n%s}" % (s))

run()


