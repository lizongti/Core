# -*- coding: utf-8 -*-

import os

pkgs = []

def find_pkgs(name):
	for rt, dirs, files in os.walk("./"):
		for f in files:
			if (f.find(name) >=0 or len(name) == 0) and f.endswith(".pkg"):
				pkgs.append(f[:f.find(".pkg")])

def call_tolua():
	for pkg in pkgs:
		print("====================================================================================")
		cmd = "tolua++ -n %s -o ../../Cxx/Intf/%sIntf.cpp %s.pkg" % (pkg, pkg, pkg)
		print(cmd)
		os.system(cmd)
		
if __name__ == '__main__':
	#find_pkgs("DispatcherService")
	find_pkgs("")
	call_tolua()
	
