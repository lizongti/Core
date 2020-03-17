# -*- coding: utf8 -*-

import os

protocols = []

def find_protocols():
	for rt, dirs, files in os.walk("./"):
		for f in files:
			if f.endswith(".proto"):
				protocols.append(f)

def call_proto_gen_lua():
	for protocol in protocols:
		print("====================================================================================")
		cmd = "protoc --lua_out=../../Lua/Protocol/ --plugin=`which protoc-gen-lua` %s" % (protocol)
		print(cmd)
		os.system(cmd)

if __name__ == '__main__':
	find_protocols()
	call_proto_gen_lua()
	
