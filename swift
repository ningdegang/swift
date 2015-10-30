#!/usr/bin/env python
import os
import getopt,sys

def find_root():
    cur = os.path.abspath(os.path.curdir)
    rootfile = cur+"/BladeRoot"
    rootpath = cur
    while cur != "/":
        if(os.path.exists(rootfile) and os.path.isfile(rootfile)): return rootpath
        cur,short = os.path.split(cur)
        rootfile = cur+"/BladeRoot"
        rootpath = cur
    return ""
        

class cc_object(object):
    rootpath = find_root() 
    name = ""
    rebuild_lib = False

    def __init__(self, name="",src=list(),deps=list(),flags=""):
        self.name, self.src, self.deps, self.flags = name,src,deps,flags
        self.type = ""
        self.objs = list()
        self.deplibs= list()

    def compile(self):
        if cc_object.name != "" and cc_object.name != self.name: return 
        self.build_all_deps() 
        for filename in self.src:
            self.compile_single_file(filename)
        self.link_target()
        
    def gen_object_filename(self, filename):
        child_dir = os.path.abspath(os.path.curdir)[len(cc_object.rootpath):]
        objectdir = cc_object.rootpath+"/build"
        if (not os.path.exists(objectdir)):os.mkdir(objectdir)
        child_dir = child_dir.split("/")
        for child in child_dir:
            objectdir += "/" + child
            if (not os.path.exists(objectdir)):os.mkdir(objectdir)
        objectdir += "/objs" 
        if (not os.path.exists(objectdir)):os.mkdir(objectdir)
        name = os.path.basename(filename)
        name = os.path.splitext(name)[0]+".o"
        objectdir += "/" + name
        self.objs.append(objectdir)
        return objectdir

    def compile_single_file(self,filename):
        sourcefilename =  os.path.abspath(os.path.curdir) + "/" + filename
        objectfilename = self.gen_object_filename(filename)
        cmd = "g++ -c %s -o %s " % (sourcefilename, objectfilename) 
        for d in self.deps:
            d = cc_object.rootpath + d.split(":")[0]
            cmd += " -I%s " % d
        final_cmd = cmd +  " >/dev/null 2>&1"
        ret = os.system(final_cmd)
        if ret !=  0:  
            print cmd 
            print "Compile %s failed" % (filename)
            sys.exit(-1);
        else :
            print "Compiling %s  ...."  % filename
        
            
    def gen_dep_lib_name(self):
        for d in self.deps:
            dd = d.split(":")
            if len(dd) != 2:
                print "lib %s format invalid" % d 
                sys.exit(-1)
            name = cc_object.rootpath + "/build/" + dd[0] + "/lib"+ dd[1]+".a"
            self.deplibs.append(name)

    def build_all_deps(self):
        for d in self.deps:
            dd = d.split(":")
            if len(dd) != 2:
                print "lib %s format invaled" % d 
                sys.exit(-1)
            libname = cc_object.rootpath + "/build/" + dd[0] + "/lib"+ dd[1]+".a"
            if os.path.exists(libname) and os.path.isfile(libname) and cc_object.rebuild_lib != True: continue 
            name = cc_object.rootpath + "/" + dd[0] 
            cmd = "cd %s >/dev/null 2>&1 ; if [ $? -eq 0 ] ;" % (name)
            cmd += "then blade -n %s ; else exit $? ; fi" % (dd[1])
            ret = os.system(cmd)
            if ret !=  0:  
                print "Compile %s failed" % (d)
                sys.exit(1)
            else :
                print "Compiling %s  ...."  % (d)
            

    def gen_target_name(self):
        path = os.path.abspath(os.path.curdir)
        child_path = path[len(cc_object.rootpath):]
        if self.type == "binaray": targetpath= cc_object.rootpath+"/build"+child_path+"/"+self.name
        else : targetpath= cc_object.rootpath+"/build"+child_path+"/lib"+self.name + ".a"
        return targetpath
        
        
    def link_target(self):
        self.gen_dep_lib_name()
        if self.type == "binaray": cmd = "g++ -o %s " % (self.gen_target_name())
        else: cmd = "ar -crv "+ self.gen_target_name() 
        for obj in self.objs:
            cmd += " " + obj 
        for obj in self.deplibs:
            cmd += " " + obj 
        final_cmd = cmd +  " >/dev/null 2>&1"
        ret = os.system(final_cmd)
        if ret !=  0:  
            print cmd 
            print "link %s failed" % (self.name)
            sys.exit(-1);
        else :
            print "linking  %s  ...."  % (self.name)

class cc_binaray(cc_object):
    def __init__(self, name="",src=list(),deps=list(),flags=""):
        super(cc_binaray, self).__init__(name,src,deps,flags)
        self.type = "binaray"
        self.compile()
    

class cc_libaray(cc_object):
    def __init__(self, name="",src=list(),deps=list(),flags=""):
        super(cc_libaray, self).__init__(name,src,deps,flags)
        self.type = "libaray"
        self.compile()

def main():
    rootpath = find_root()
    if rootpath == "":
        print "There is no BladeRoot file found, or is in / path, which is not allowed"
        sys.exit(1)
    if(not os.path.exists("BUILD")):
        print "There is no BUILD file found"
        sys.exit(1)
    try:
        doc = open("BUILD").read()
        exec(doc)
    except:
        sys.exit(1)


def usage():  
    print("Usage:%s [-a|-o|-c] [--help|--output] args...." % sys.argv[0]);  
  
  
if "__main__" == __name__:  
    try:  
        opts,args = getopt.getopt(sys.argv[1:], "cn:N", ["clean", "help", "name"])
        for opt,arg in opts:  
            if opt in ("-h", "--help"):  print "2"; usage(); sys.exit(1)
            elif opt in ("-N"):
                print("rebuild all libs, objects and target")
                cc_object.rebuild_lib = True
            elif opt in ("-n", "--name"):
                cc_object.name = arg
            elif opt in ("-c", "--clean"):
                print("clean all object files and target")
    except getopt.GetoptError:  
        usage()
        sys.exit(1)
    main()