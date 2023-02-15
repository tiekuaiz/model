##################################################
 # @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 # @file        : gen_filelist.py
 # @created     : Friday Nov 11, 2022 00:29:54 CST
 #
##################################################
#        NuVolta Technologies, Inc.
#        Confidential Information
#
#        Description:
#        Automatically generate a file list from the current folder
#
#
#        History:
#        Date          Rev         who          Comments
#        11/11/2022     1.0         xwzhang     Initial release
#
#----------------------------------------------------------------------------------------


import os, sys, shutil, re

def main():
    #pwd = os.path.abspath(os.getcwd())
    pwd = os.popen("pwd").read()
    pwd = os.path.abspath(pwd.strip())
    print(pwd)
    fs = os.listdir(pwd)
    fdir = os.path.basename(pwd)
    ofname = fdir + "_filelist.f"
    with open(ofname, "w") as fh:
        lines = []
        for f in fs:
            if re.search(r"Makefile", f) or re.search(r"^\.", f) or re.search(r"\.py$", f) or re.search(r"\.f$", f):
                continue
            ff = pwd + os.sep + f
            #print(os.environ['PROJ_HOME'])
            ff = re.sub(re.escape(os.environ['PROJ_HOME']), "${PROJ_HOME}", ff)
            lines.append(ff)
        fh.write("\n".join(lines))

if __name__ == "__main__":
    main()

