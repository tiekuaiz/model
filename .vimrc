##################################################
 # @author      : Xiwen Zhang (xiwen.zhang@nuvoltatech.com)
 # @file        : My_PKG.py
 # @created     : Thursday Dec 29, 2022 21:30:54 CST
 #
##################################################
#        NuVolta Technologies, Inc.
#        Confidential Information
#
#        Description:
#
#
#
#        History:
#        Date          Rev         who          Comments
#        29/12/2022     1.0         xwzhang     Initial release
#
#----------------------------------------------------------------------------------------


import os, sys, shutil, re, math
import logging, json
from logging import handlers
from datetime import datetime
from enum import Enum
from inspect import currentframe

real_z = "`wrealZState"
real_x = "`wrealXState"
bit0 = "1'b0"
bit1 = "1'b1"
bitx = "1'bx"
bitz = "1'bz"
PIN_RANGE_MAX = int(1e9)
PIN_RANGE_MIN = 0
chk_good = "chk_good"
wire = "wire"

class Threshold(Enum):
    Falling = 0
    Rising = 1

class Comp(Enum):
    Comp_2n = 0
    Comp_2p = 1

class Check_Type(Enum):
    CHECK_VOLTAGE = 0
    CHECK_CURRENT = 1

class EnumValueOutFormat(Enum):
    DECIMAL_VAL = 0
    HEX_VAL = 1
    BIN_VAL = 2

class Logger(object):
    level_relations = {
        'debug':logging.DEBUG,
        'info':logging.INFO,
        'warning':logging.WARNING,
        'error':logging.ERROR,
        'crit':logging.CRITICAL
    }#

    def __init__(self,filename = None,level='info',when='D',backCount=3,fmt='%(levelname)s: %(message)s'):
        self.filename = filename
        if filename is None:
            self.filename = os.path.dirname(os.path.abspath(__file__)) + os.sep + "log.log"
        self.logger = logging.getLogger(self.filename)
        format_str = logging.Formatter(fmt)#
        self.logger.setLevel(self.level_relations.get(level))#
        self.sh = logging.StreamHandler()#
        self.sh.setFormatter(format_str) #
        self.th = handlers.TimedRotatingFileHandler(filename=self.filename,when=when,backupCount=backCount,encoding='utf-8')#
        self.th.setFormatter(format_str)#
        self.logger.addHandler(self.sh) #
        self.logger.addHandler(self.th)
        current_date_and_time = datetime.now()
        self.logger.info(get_curr_time())
        self.logger.info("Writing to logfile: " + self.filename)

    def shut(self):
        self.logger.removeHandler(self.sh)
        self.logger.removeHandler(self.th)
        logging.shutdown()

class HDL_Processor():
    def __init__(self, model_file, logger):
        self.logger = logger
        self.logger.info(self.class_info())
        self.all_port_dirs = "input output inout".split(" ")
        self.base_dir = get_file_dir(model_file)
        self.view_name = os.path.basename(self.base_dir)
        self.view_ext = "sv" if self.view_name == "systemVerilog" else "vams"
        self.seperate_pins = False if self.view_name == "systemVerilog" else True
        self.orig_model_file = self.base_dir + os.sep + "verilog." + self.view_ext
        self.port_file = self.base_dir + os.sep + "port_map.txt"
        self.extra_file = self.base_dir + os.sep + "extra.txt"
        self.missing_file = self.base_dir + os.sep + "missing.txt"
        self.port_map = load_from_jsonfile(self.port_file) if os.path.isfile(self.port_file) else {}
        #print(self.port_map)
        #store the port name, dir, range in pnr_map
        self.existing_pnr_map = self.get_existing_pin_info()
        #print(self.existing_pnr_map)
        if not self.port_map:
            self.pnr_map = self.existing_pnr_map
        else:
            self.pnr_map = self.extract_pnr(self.port_map)
        self.missing_pins = load_from_jsonfile(self.missing_file) if os.path.isfile(self.missing_file) else []
        if len(self.missing_pins) == 0:
            self.missing_pins = self.find_missing_pins()
        self.extra_pins = load_from_jsonfile(self.extra_file) if os.path.isfile(self.extra_file) else []
        if len(self.extra_pins) == 0:
            self.extra_pins = self.find_extra_pins()
        self.cell_name = get_block_name(self.orig_model_file)
        self.lib_name = get_lib_name(self.orig_model_file)
        self.test_run = False
        self.vdd = "DVDD"
        self.vss = "DVSS"
        logger.info("base_dir = " + self.base_dir)
        logger.info("lib_name = " + self.lib_name)
        logger.info("cell_name = " + self.cell_name)
        self.user_name = os.environ["USER"]

    def class_info(self):
        self.class_str = "It is used to regenerate the HDL header, module definition and port declaration"
        self.logger.info(self.class_str)
        return(self.class_str)

    def find_missing_pins(self):
        missing_pins = []
        for pin in self.pnr_map.keys():
            if pin not in self.existing_pnr_map.keys():
                missing_pins.append(pin)
        return(missing_pins)

    def find_extra_pins(self):
        extra_pins = []
        for pin in self.existing_pnr_map.keys():
            if pin not in self.pnr_map.keys():
                extra_pins.append(pin)
        return(extra_pins)

    def set_vdd(self, vdd):
        self.vdd = vdd

    def set_vss(self, vss):
        self.vss = vss

    def set_sources(self, vdd, vss):
        self.set_vdd(vdd)
        self.set_vss(vss)

    def regen_model_file(self):
        outfile = self.base_dir + os.sep + "temp.sv"
        out_lines = []
        top_comment_lines = self.gen_top_lines()
        top_comment_lines += self.gen_extra_lines()
        top_comment_lines += self.gen_missing_line()
        out_lines += self.gen_comment_lines(top_comment_lines)
        out_lines.append("")
        with open(self.orig_model_file) as fh:
            no_append = False
            for line in fh:
                if re.search(r"\bmodule\b", line) and not re.search(r"\/\/.*\bmodule\b", line):
                    no_append = True
                    out_lines += self.gen_module_def_lines()
                    out_lines += self.gen_port_def_lines()
                if re.search(r"end of pin definition", line):
                    no_append = False
                if not no_append:
                    line = re.sub(r"\n$", "", line)
                    out_lines.append(line)
        if self.test_run:
            write_to_file(outfile, out_lines, "", True, self.logger)
        else:
            write_to_file(self.orig_model_file, out_lines, "", True, self.logger)
        #print("".join(out_lines))

    def get_existing_pin_info(self):
        port_dict = {}
        with open(self.orig_model_file) as fh:
            module_def_start = 0
            last_line = ""
            for line in fh:
                line = line.strip()
                if is_blank(line):
                    continue
                if re.search(r"\bmodule\b\s*.*\(", line):
                    module_def_start += 1
                if module_def_start == 1 and re.search(r"\)\s*;", line):
                    module_def_start += 1
                elif module_def_start == 2:
                    if re.search(r"\s*end of pin definition", line):
                        break
                    line_content = line
                    line_comment = ""
                    line_mi = match_items(r"\s*(.*?)\s*\/\/(.*)", line)
                    if line_mi is not None:
                        line_content = line_mi[0]
                        line_comment = line_mi[1]
                    lmi = match_items(r"^\s*\/\/(.*)$", last_line)
                    if lmi is not None:
                        line_comment = lmi

                    pss = None
                    if re.search(r"\(.*\)", line_content):
                        mss = match_items(r"\((.*)\)", line_content)
                        line_content = re.sub(r"\(.*\)", " ", line_content)
                        pss = self.extract_ss(mss)
                    if pss is None:
                        pss = []
                    pin_strs = list(map(remove_pr_tr_spaces, re.split(r";", line_content)))
                    pin_strs = [x for x in pin_strs if not is_blank(x)]
                    #print(pin_strs)
                    for pin_str in pin_strs:
                        pin_name = self.extra_pin_info_from_def(pin_str, port_dict)
                        port_dict[pin_name][3] = line_comment
                        if len(port_dict[pin_name][4]) == 0:
                            port_dict[pin_name][4] = pss
                last_line = line
        return(port_dict)

    def extract_ss(self, in_str):
        return(match_items(r"supplySensitivity\s*=\s*\"(.*)\".*groundSensitivity\s*=\s*\"(.*)\"", in_str))

    def gen_ss(self, in_arr):
        if len(in_arr) == 2:
            return("(* integer supplySensitivity = \"{0}\";integer groundSensitivity = \"{1}\";*)".format(in_arr[0], in_arr[1]))
        return("")

    def extra_pin_info_from_def(self, in_str, port_dict):
        pin_range = ""
        mi = match_items(r"(\[.*\])", in_str)
        if mi is not None:
            pin_range = mi
            in_str = re.sub(r"\[.*\]", " ", in_str)
            in_str = remove_pr_tr_spaces(in_str)
            in_str = re.sub(r"\s+", " ", in_str)
        mss = match_items(r"(\(.*\))", in_str)
        pss = None
        if mss is not None:
            pss = self.extract_ss(mss)
            in_str = re.sub(r"\(.*\)", " ", in_str)
        if pss is None:
            pss = []
        items = re.split(r"\s+", in_str)
        port_name = items[-1]
        if port_name not in port_dict.keys():
            port_dict[port_name] = ["", "", "", "", pss]
        port_dict[port_name][0] = [pin_range]
        if len(items) == 3:
            if items[0] in self.all_port_dirs:
                port_dict[port_name][1] = items[0]
                port_dict[port_name][2] = items[1]
        elif len(items) == 2:
            port_prop = items[0]
            if port_prop in self.all_port_dirs:
                port_dict[port_name][1] = items[0]
            elif port_dict[port_name][1] in self.all_port_dirs:
                port_dict[port_name][2] = items[0]
        return(port_name)

    def extract_pnr(self, port_map):
        pnr_map = dict()
        for pt in port_map.keys():
            pin_name, pin_range = self.extract_port_info(pt)
            if pin_name in pnr_map.keys():
                pnr_map[pin_name][0].append(pin_range)
            else:
                pnr_map[pin_name] = [[pin_range], port_map[pt], "", "", []]
        for pin_name in pnr_map.keys():
            pin_ranges = pnr_map[pin_name][0]
            pnr_map[pin_name][0] = sorted(pin_ranges, reverse = True, key = range_key)
        return(pnr_map)

    def extract_port_info(self, in_str):
        items = match_items(r"(.*)<(.*)>", in_str)
        if items:
            pin_name = items[0]
            pin_range = items[1]
        else:
            pin_name = in_str
            pin_range = ""
        return(pin_name, pin_range)

    def guess_pin_types(self, pin_name, view_ext):
            low_pin_name = pin_name.lower()
            pin_type = ""
            e_type = "`REAL_NET" if self.view_ext == "sv" else "electrical"
            w_type = "wire"
            if re.search(r"^d2a_", low_pin_name) or re.search(r"^a2d_", low_pin_name) or re.search(r"^d_", low_pin_name):
                pin_type = w_type
            elif re.search(r"^a_", low_pin_name):
                pin_type = e_type
            else:
                supplies = "dvdd dvss vbg avss avdd agnd pgnd sub pwr_vcp v1p8 v3p3".split(" ")
                if low_pin_name in supplies:
                    pin_type = e_type
                currents = "vref ref vss ibn ibp".split(" ")
                for cr in currents:
                    if re.search(r"^" + re.escape(cr), low_pin_name):
                        pin_type = e_type
            if pin_type == "":
                return([e_type, w_type])
            else:
                return([pin_type])

    def merge_pin_range(self, pin_ranges):
        np = len(pin_ranges)
        pin_min = PIN_RANGE_MAX
        pin_max = PIN_RANGE_MIN
        for pin_range in pin_ranges:
            if is_blank(pin_range):
                continue
            if ":" in pin_range:
                pin_nums = [int(x) for x in pin_range.split(":")]
            else:
                pin_nums = [int(pin_range)]
            for pin_num in pin_nums:
                pin_min = min(pin_min, pin_num)
                pin_max = max(pin_max, pin_num)
        if pin_min == PIN_RANGE_MAX and pin_max == PIN_RANGE_MIN:
            return("")
        return("[{0}:{1}]".format(pin_max, pin_min))

    def gen_pin_def_lines(self, pin_name, pin_props):
        pin_ranges, pin_dir, pin_type, pin_comment, pss = pin_props
        #if not re.search(r"^\s*$", pin_range):
        #pin_range = "[{0}]".format(pin_range)
        pin_range = self.merge_pin_range(pin_ranges)
        type_is_guessed = False
        if pin_type == "":
            type_is_guessed = True
            pin_types = self.guess_pin_types(pin_name, self.view_ext)
            if not re.search(r"Guessed Type", pin_comment):
                pin_comment += "Guessed Type. Check."
                if len(pin_types) > 1:
                    pin_comment += " Please only keep 1 definition."
        else:
            pin_types = [pin_type]
        out_lines = []
        if pin_comment != "":
            out_lines.append("    //" + pin_comment)
        for pin_type in pin_types:
            out_lines.append("    " + self.gen_pin_def_line(pin_name, pin_range, pin_dir, pin_type, pss))
        return(out_lines)

    def gen_pin_def_line(self, pin_name, pin_range, pin_dir, pin_type, pss = []):
        items = []
        pt_last = False
        has_pss = False
        if pin_type == "`REAL_NET":
            pt_last = True
        items.append(pin_dir)
        if not is_blank(pin_range):
            items.append(pin_range)
        if self.view_ext == "vams" and pin_type in ["wire", "reg"]:
            if len(pss) == 0:
                pss.append(self.vdd)
            if len(pss) == 1:
                pss.append(self.vss)
            items.append(self.gen_ss(pss))
            has_pss = True
        items.append("{0};".format(pin_name))
        if len(items[-2]) > 50:
            items.append("\n")
        items.append(pin_type)
        if not pt_last and not is_blank(pin_range):
            items.append(pin_range)
        if pt_last and not is_blank(pin_range):
            items.append("{0}".format(pin_name))
            items.append(pin_range + ";")
        else:
            items.append("{0};".format(pin_name))
        ret = " ".join(items)
        ret = re.sub(r" \n ", "\n    ", ret)
        return(ret)

    def gen_top_lines(self):
        lines = ["{0} HDL for <\"{1}\", \"{2}\", \"{0}\"> updated by {3}".format(self.view_name, self.lib_name, self.cell_name, self.user_name)]
        lines.append("on {0}".format(get_curr_time()))
        return(lines)

    def gen_extra_lines(self):
        lines = []
        if len(self.extra_pins) > 0:
            lines += ["Removed extra pins"]
            lines += gen_wid_lim_lines(self.extra_pins, 60, 0)
        return(lines)

    def gen_missing_line(self):
        lines = []
        if len(self.missing_pins) > 0:
            lines += ["Added missing pins"]
            lines += gen_wid_lim_lines(self.missing_pins, 60, 0)
        return(lines)

    def gen_comment_lines(self, in_lines):
        return(["//" + x for x in in_lines])

    def gen_module_def_lines(self):
        #ports_arr = sorted(self.pnr_map.keys())
        ports_arr = self.gen_port_arr(self.pnr_map)
        ports_lines = gen_wid_lim_lines(ports_arr)
        ports_lines[0] = "module {0}({1}".format(self.cell_name, ports_lines[0])
        ports_lines[-1] = "{0});".format(ports_lines[-1])
        return(ports_lines)

    def gen_port_arr(self, pnr_map):
        ports_arr = []
        for port in sorted(pnr_map.keys()):
            if not self.seperate_pins or len(pnr_map[port][0]) <= 1:
                ports_arr.append(port)
            else:
                for port_range in pnr_map[port][0]:
                    #if ":" not in port_range:
                        #port_range = "{0}:{0}".format(port_range)
                    ports_arr.append("{0}[{1}]".format(port, port_range))
        return(ports_arr)

    def gen_port_def_lines(self):
        out_lines = []
        all_pins_by_dir = [[], [], []]
        print(self.pnr_map)
        for pin_name in self.pnr_map.keys():
            if self.pnr_map[pin_name][1] == "output":
                aind = 0
            elif self.pnr_map[pin_name][1] == "input":
                aind = 1
            elif self.pnr_map[pin_name][1] == "inout":
                aind = 2
            all_pins_by_dir[aind].append(pin_name)
        for pin_list in all_pins_by_dir:
            for pin_name in sorted(pin_list):
                if pin_name in self.existing_pnr_map.keys():
                    #existing pin_type
                    self.pnr_map[pin_name][2] = self.existing_pnr_map[pin_name][2]
                    #existing pin_comment
                    self.pnr_map[pin_name][3] = self.existing_pnr_map[pin_name][3]
                    self.pnr_map[pin_name][4] = self.existing_pnr_map[pin_name][4]
                out_lines += self.gen_pin_def_lines(pin_name, self.pnr_map[pin_name])
        return(out_lines)

class Log_Processor():
    def __init__(self, in_file, logger):
        self.logger = logger
        logger.info(class_info())
        self.in_file = in_file

    def class_info(self):
        return("It is used to process the simulation log")

    def get_file_list(self):
        pass

class Model_Readin():
    def __init__(self, in_file, logger):
        super().__init__(outputLogFile, "debug")
        self.logger = logger
        self.logger.info("This class is used for reading in the models")
        self.in_file = in_file
        if not os.path.isfile(in_file):
            self.logger.error("{0} is not a valid file.".format(in_file))
            return

    def readin_file(self):
        if not self.in_file:
            self.logger.error("{0} is not a valid file.".format(self.in_file))
            return
        fp = File_Processor(self.in_file, self.logger)
        lines = fp.remove_comments()
        dir_dict = dict()
        term_dict = dict()
        for line in lines:
            pass

    def get_module_info(self, in_lines):
        module_start = 0
        module_line = ""
        for line in in_lines:
            new_line = line.strip()
            new_line = re.sub(r"\".*?\"", "", new_line)
            mi = match_items(r"\bmodule\s+(.*)", new_line)
            if mi is not None:
                module_start = 1
            if module_start:
                module_line += new_line
                if re.search(r"\)\s*;", line):
                    module_start = 0
                    mi = match_items(r"\bmodule\s+(\w+)\s*\((.*)\)", module_line)
                    if mi is not None:
                        module_name = mi[0]
                        all_pins = split_pins(mi[1])
                        return(module_name, all_pins)
                    break
        return(None)

class File_Processor():
    def __init__(self, in_file, logger):
        self.logger = logger
        self.logger.info("This class is used for reading in the models")
        self.in_file = None
        if not os.path.isfile(in_file):
            self.logger.error("{0} is not a valid file.".format(in_file))
            return
        self.in_file = in_file

    def remove_comments(self):
        lines = []
        with open(self.in_file) as fh:
            comment_start = 0
            new_line = ""
            for line in fh:
                if not comment_start:
                    if new_line != "":
                        lines.append(new_line)
                        new_line = ""
                ln = len(line)
                ii = 0
                while ii < ln:
                    ch = line[ii]
                    if comment_start:
                        if ch == "*" and ii < ln - 1 and line[ii + 1] == "/":
                            comment_start = 0
                            ii += 2
                        else:
                            ii += 1
                    else:
                        if ch == "/" and ii < ln - 1:
                            if line[ii + 1] == "/":
                                break
                            elif line[ii + 1] == "*":
                                comment_start = 1
                                ii += 2
                            else:
                                new_line += ch
                                ii += 1
                        else:
                            new_line += ch
                            ii += 1
            if new_line != "":
                lines.append(new_line)
        return(lines)

    def change_compile_file(self, lines):
        out_lines = []
        last_line = ""
        for line in lines:
            if is_blank(line):
                continue
            mi = match_items(r"-amscompilefile\s*\"file:(.*?)\s+", line)
            if mi is not None:
                out_lines.append(mi + "\n")
        return(out_lines)

    def remove_vams_lines(self, lines):
        out_lines = []
        last_line = ""
        ts = False
        for line in lines:
            if re.search(r"^\s*`include.*vams", line):
                continue
            if re.search(r"^\s*`noworklib", line):
                continue
            if re.search(r"^\s*`worklib", line):
                continue
            if re.search(r"^\s*`noview", line):
                continue
            if re.search(r"^\s*`view", line):
                continue
            if re.search(r"^\s*\(\* cds_ams_schematic \*\)", line):
                continue
            if is_blank(line) and re.search(r"^\s*wire\b", last_line):
                continue
            if is_blank(line) and is_blank(last_line):
                continue

            if re.search(r"^\s*`timescale", line):
                if not ts:
                    ts = True
                else:
                    continue
            last_line = line
            out_lines.append(line)
        return(out_lines)

class Code_Gen():
    def __init__(self, block_name_abbv, real_wire_def, in_file, out_file, logger, nspace = 4, use_hdlp = True, indent = True):
        self.logger = logger
        self.block_name = get_block_name(in_file)
        self.file_dir = get_file_dir(in_file)
        self.main_file_name = get_file_name(in_file)
        self.out_file = out_file
        self.wire_type = real_wire_def
        self.block_name_abbv = block_name_abbv
        self.logger.info(self.class_info())
        self.pre = ""
        self.all_lines = ["//Autogen Starts"]
        self.chks = []
        self.vchks = []
        self.ichks = []
        self.nspace = nspace
        self.indent = indent
        self.pre += nsp(nspace)
        self.append_line = True
        self.old_append = None
        self.write_mode = "w"
        self.voltage_check_dict = dict()
        self.current_check_dict = dict()
        self.voltage_sigs_set = set()
        self.current_sigs_set = set()
        if use_hdlp:
            self.hdlp = HDL_Processor(in_file, logger)

    def set_vdd(self, vdd):
        self.vdd = vdd

    def set_vss(self, vss):
        self.vss = vss

    def set_sources(self, vdd, vss):
        self.set_vdd(vdd)
        self.set_vss(vss)

    def class_info(self):
        return("Generating code bases for sv files")

    def assign_self_vars(self, thds_v, hyst, comp_dir, comp_in, comp_name, comp_en, mux_rev = 1, mux_en = "1'b1"):
        self.thds_v = thds_v
        self.hyst = hyst
        self.comp_dir = comp_dir
        self.rev_comp_dir = "F" if comp_dir == "R" else "R"
        (self.thr_type, self.comp_type) = self.get_thr_comp_type(comp_dir)
        self.comp_in = comp_in
        self.comp_name = comp_name
        self.comp_en = comp_en
        self.mux_rev = mux_rev
        self.mux_en = mux_en
        self.thds_v = self.conv_orig_val(self.thds_v)
        self.comp_desp = self.comp_in + "_" + self.comp_name
        self.block_comp_desp = "{0}_{1}".format(self.block_name_abbv, self.comp_desp)
        self.mux_pre = self.gen_mux_pre()
        self.sel_bits = self.gen_sel_bits()
        self.comp_out = self.gen_comp_out()

    def gen_mux_comp_codes(self, thds_v, hyst, comp_dir, comp_in, comp_name, comp_en, mux_rev = 1, mux_en = "1'b1"):

        self.assign_self_vars(thds_v, hyst, comp_dir, comp_in, comp_name, comp_en, mux_rev, mux_en)
        self.new_vals = self.gen_new_th(self.thds_v, self.hyst, self.thr_type)
        self.thds = self.gen_thds(self.thds_v, self.new_vals, self.thr_type)
        curr_lines = self.gen_mux_comp()
        if self.append_line:
            self.all_lines += curr_lines
        return(curr_lines)

    def pre_lines(self):
        return([""])

    def post_lines(self):
        return([])

    def conv_orig_val(self, in_vals):
        return(in_vals)

    def recover_append_line(self):
        if self.old_append != None:
            self.append_line = self.old_append
            self.old_append = None

    def store_append_line(self, change_to = False):
        if self.old_append == None:
            self.old_append = self.append_line
        self.append_line = change_to

    def gen_mux_pre(self):
        return("{0}_{1}".format(self.block_comp_desp, "THD"))

    def gen_sel_bits(self):
        return("D2A_{0}_{1}_1P8".format(self.mux_pre, self.comp_dir))

    def gen_comp_out(self):
        return("A2D_{0}_1P8".format(self.block_comp_desp))

    def gen_mux_comp(self):
        desps = "R F".split()
        all_lines = self.pre_lines()
        all_lines.append("//Generating {1} based on spec of".format(self.pre, self.comp_out))
        all_lines.append("//rising:{0}".format(self.gen_arr_display(self.thds[0])))
        all_lines.append("//falling:{0}".format(self.gen_arr_display(self.thds[1])))
        self.mux_nodes = []
        for ii in range(len(desps)):
            self.mux_nodes.append(self.mux_pre + "_" + desps[ii])
        self.store_append_line()
        all_lines.append(self.gen_wire_def(self.wire_type, self.mux_nodes))
        self.recover_append_line()
        for ii in range(len(desps)):
            all_lines += self.gen_sv_mux_num(self.thds[ii], self.sel_bits, self.mux_nodes[ii], self.mux_rev, self.mux_en)
        if self.comp_type == Comp.Comp_2n:
            all_lines.append(self.gen_sv_comp_2n(self.comp_in, self.mux_nodes[0], self.mux_nodes[1], self.comp_en, self.comp_out))
        if self.comp_type == Comp.Comp_2p:
            all_lines.append(self.gen_sv_comp_2p(self.mux_nodes[0], self.mux_nodes[1], self.comp_in, self.comp_en, self.comp_out))
        all_lines += self.post_lines()
        return(all_lines)

    def gen_thds(self, in_vals, new_vals, th_type = Threshold.Falling):
        if th_type == Threshold.Falling:
            return([in_vals, new_vals])
        return([new_vals, in_vals])

    def gen_new_th(self, in_vals, hyst, th_type = Threshold.Falling):
        out_vals = []
        for val in in_vals:
            new_val = val + hyst
            if th_type == Threshold.Falling:
                new_val = val - hyst
            if th_type == Threshold.Rising:
                new_val = val + hyst
            out_vals.append(new_val)
        return(out_vals)

    def gen_arr_display(self, in_arr, unit = "", ratio = 1):
        l = len(in_arr)
        out_arr = []
        for ii in range(l):
            out_arr.append("{0}{2}({1})".format(self.conv(in_arr[ii] * ratio), ii, unit))
        return(out_arr)

    def gen_sv_mux_num(self, in_settings, sel_bits, out_name, rev = 0, en = "1'b1"):
        lines = []
        if rev:
            in_settings.reverse()
        l = len(in_settings)
        #self.logger.info(in_settings)
        nbits = int(math.log(l, 2))
        thds_in = "{0}_INS".format(out_name)
        old_append = self.append_line
        self.append_line = False
        thd_rg = "[{0}:0]".format(l - 1)
        lines.append(self.gen_wire_def(self.wire_type, ["{0}{1}".format(thds_in, thd_rg)]))
        in_settings_str = [str(self.conv(x)) for x in in_settings]
        lines.append(self.gen_assign(thds_in, "'{{{0}}}".format(", ".join(in_settings_str))))
        lines.append("nvt_sv_mux #(.NUM_BITS({1})) mux_{3}(.in({0}), .sel({2}), .en({5}), .out({3}));".format(thds_in, nbits, sel_bits, out_name, self.pre, en))
        self.append_line = old_append
        return(lines)

    def gen_assign(self, out_val, in_val):
        items = ["assign", out_val, "=", in_val]
        line = "{0};".format(" ".join(items))
        if self.append_line:
            self.all_lines.append(line)
        return(line)

    def gen_sv_mux(self, in_settings, sel_bits, out_name, rev = 0, en = "1'b1"):
        l = len(in_settings)
        #self.logger.info(in_settings)
        nbits = int(math.log(l, 2))
        if rev:
            in_settings.reverse()
        pin_settings = []
        for in_set in in_settings:
            pin_settings.append(self.conv(in_set))
        return("nvt_sv_mux #(.NUM_BITS({1})) mux_{3}(.in('{{{0}}}), .sel({2}), .en({5}), .out({3}));".format(", ".join(pin_settings), nbits, sel_bits, out_name, self.pre, en))

    def gen_sv_comp_2n(self, pin, n1, n2, comp_en, out_name):
        return("nvt_sv_comp_hyst_2n comp_2n_{3}(.p({0}), .n1({1}), .n2({2}), .en({5}), .out({3}));".format(pin, n1, n2, out_name, self.pre, comp_en))

    def gen_sv_comp_2p(self, p1, p2, nin, comp_en, out_name):
        return("nvt_sv_comp_hyst_2p comp_2p_{3}(.p1({0}), .p2({1}), .n({2}), .en({5}), .out({3}));".format(p1, p2, nin, out_name, self.pre, comp_en))

    def gen_osci(self, en, node, def_freq = "1e6", def_duty = "0.5"):
        param_defs = []
        lines = ["//Generating an oscillator with a switching frequency of {0}Hz and Duty ratio of {1}".format(def_freq, def_duty)]
        def_values = "1e6 0.5".split(" ")
        params = "def_freq def_duty".split(" ")
        in_values = [def_freq, def_duty]
        param_def = self.gen_param_defs_with_list(params, def_values, in_values)
        stat = "nvt_sv_osci {2}osc{1}(.en({0}), .out({1}));".format(en, node, param_def)
        lines.append(stat)
        lines.append("")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_buf_delay(self, in_node, out_node, rise_delay = "10", fall_delay = "10"):
        stats = []
        stats.append("//Generating {0} from {1} with a rising delay of {2}ns and falling delay of {3}ns".format(out_node, in_node, rise_delay, fall_delay))
        stats.append("wire {0};".format(out_node))
        stats.append("buf #({0}, {1}) buf_{2}({2}, {3});".format(rise_delay, fall_delay, out_node, in_node))
        stats.append("")
        if self.append_line:
            self.all_lines += stats
        return(stats)

    def insert_blankline(self):
        self.all_lines.append("")

    def gen_clkcnt_good(self, clk, good_target, en, clk_cnt, clk_good, cnt_max):
        lines = ["//Generating the clk counter for {0} and the clk good asserts high when {1} hits {2}".format(clk, clk_cnt, good_target)]
        lines.append("reg {0} = 1'b0;".format(clk_good))
        lines.append("int {0} = 0;".format(clk_cnt))
        lines.append("always @(negedge {0} or posedge {1}) begin".format(en, clk))
        indt1 = nsp(1, self.pre)
        indt2 = nsp(2, self.pre)
        lines.append("{0}if(!{1}) begin".format(indt1, en))
        lines.append("{0}{1} = 0;".format(indt2, clk_cnt))
        lines.append("{0}{1} = 1'b0;".format(indt2, clk_good))
        lines.append("{0}end".format(indt1))
        lines.append("{0}else begin".format(indt1))
        lines.append("{0}{1} = {1} + 1;".format(indt2, clk_cnt))
        lines.append("{0}if({2} == {3}) {1} = 1'b1;".format(indt2, clk_good, clk_cnt, good_target))
        lines.append("{0}{1} = {1} % {2};".format(indt2, clk_cnt, cnt_max))
        lines.append("{0}end".format(indt1))
        lines.append("end")
        lines.append("")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_clk_div(self, in_cnt, en, out_clk, ratio, def_out = 0):
        #tot = 1 << ratio
        tot = ratio
        half = int(tot / 2)
        lines = []
        lines.append("//Generating a divided clock with a ratio of {0}".format(ratio))
        line = "assign {0} = (({1} % {2}) < {3})".format(out_clk, in_cnt, tot, half)
        line = self.gen_en_out(en, line, def_out)
        lines.append(line)
        lines.append("")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_en_out(self, en, in_sig, def_out = 0):
        line = "{0}".format(in_sig)
        if def_out:
            line += " | ~{0};".format(en)
        else:
            line += " & {0};".format(en)
        return(line)

    def gen_vsrcs(self, node, ns, ne, en = "1'b1", steps = 50):
        ii = ns
        inc = ne >= ns
        lines = []
        while True:
            lines.append("nvt_sv_src #(.nstep({2})) src{0}_{3}(.out({0}[{3}]), .en({1}));".format(node, en, steps, ii))
            if ii == ne:
                break
            if inc:
                ii += 1
            else:
                ii -= 1
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_vsrcs_sets(self, node, ns, ne, ini, dv):
        ii = ns
        inc = ne >= ns
        lines = []
        cv = ini
        while True:
            lines.append("src{0}_{2}.ramp_src_val({1}, 10e-6);".format(node, self.conv(cv), ii))
            cv += dv
            if ii == ne:
                break
            if inc:
                ii += 1
            else:
                ii -= 1
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_vsrc(self, node, en = "1'b1", steps = 50):
        stat = "nvt_sv_src #(.nstep({2})) src{0}(.out({0}), .en({1}));".format(node, en, steps)
        if self.append_line:
            self.all_lines.append(stat)
        return(stat)

    def gen_vcheck(self, node, exp_val, exp_tor = 0.1):
        sig_good = "{0}_good".format(node)
        self.vchks.append("{0}_good".format(node))
        lines = ["//Generating a voltage checker signal {3} for {0}, expected value of {1} with an accuracy spec of {2}".format(node, exp_val, exp_tor, sig_good)]
        chk_stat = "`def_vchk_val({0}, {1}, {2})".format(node, exp_val, exp_tor)
        lines.append(chk_stat)
        if self.append_line:
            self.all_lines += lines
        return(chk_stat)

    def gen_nmos(self, out, data, ctrl):
        lines = ["//nmos model with out = {0}, data = {1}, control = {2})".format(out, data, ctrl)]
        lines += ["nmos nmos_{0}({0}, {1}, {2});".format(out, data, ctrl)]
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_sel(self, wire_def, node, sel, a, b):
        lines = ["//when {2} == 1, {0} is {1} else {3}".format(node, a, sel, b)]
        lines.append(" ".join([wire_def, node, "=", sel, "?", a, ":", b]) + ";")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_param_defs_with_list(self, param_names, def_values, in_values):
        param_defs = []
        for ii in range(len(param_names)):
            if in_values[ii] != def_values[ii]:
                param_defs.append(self.gen_param_def(param_names[ii], in_values[ii]))
        return(self.gen_param_defs(param_defs, True))

    def gen_vams_switch(self, a, b, en, to_corr = True, tr = "100n", tf = "100n", ron = "1m", roff = "10e6", gmin = "1e-12"):
        if to_corr:
            self.gen_corr(en, "")
            en = "{0}_corr".format(en)
        def_values = "100n 100n 1m 10e6 1e-12".split(" ")
        params = "tr tf ron roff gmin".split(" ")
        in_values = [tr, tf, ron, roff, gmin]
        param_def = self.gen_param_defs_with_list(params, def_values, in_values)
        port_def = self.gen_port_defs("p n en".split(" "), [a, b, en])
        lines = ["nvt_swth {0}swth_{1}_{2}{3};".format(param_def, a, b, port_def)]
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_vams_isrc(self, node, en, itype = 0):
        if itype == 0:
            pnode = node
            nnode = self.vss
        else:
            pnode = self.vdd
            nnode = node
        ports = "p n en".split(" ")
        conns = [pnode, nnode, en]
        node_name = self.gen_node_src_name(node)
        lines = []
        param_def = ""
        self.src_name = "nvt_isrc_{0}".format(node_name)
        lines.append("nvt_isrc {0}{1}{2};".format(param_def, self.src_name, self.gen_port_defs(ports, conns)))
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_func_cases(self, func_name, in_vals, ret_type):
        l = len(in_vals)
        nbits = int(math.log(l, 2))
        if nbits > 1:
            rg = "[{0}:0] ".format(nbits - 1)
        else:
            rg = ""
        in_val = "in_val"
        lines = []
        lines.append("function {0} {1}(input {2}{3});".format(ret_type, func_name, rg, in_val))
        lines.append("begin")
        lines += self.add_pre(self.gen_cases(in_val, in_vals, func_name), 1)
        lines.append("end")
        lines.append("endfunction //{0}".format(func_name))
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def add_blank_lines(self, n = 1):
        for ii in range(n):
            self.all_lines.append("")

    def gen_port_def(self, port_name, port_dir, port_type, port_range, port_comment = "", pss = []):
        pin_props = [[port_range], port_dir, port_type, port_comment, pss]
        lines = self.hdlp.gen_pin_def_lines(port_name, pin_props)
        lines.append(", {0}".format(port_name))
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_current_sel_lines(self, bits, bits_range, src_node, func_name, func_type, vals, itype = 0):
        bits_corr = "{0}_corr".format(bits)
        ien = "{0}_en".format(bits.lower())
        self.all_lines.append("//Generating current on node {0} with selection bits {1} and values of [{2}].".format(src_node, bits, ", ".join(self.gen_arr_display(vals, "mA", 1000))))
        self.gen_corr(bits, bits_range)
        self.gen_wire_and("wire", ien, [chk_good, "({0}_corr != 0)".format(bits)])
        self.gen_vams_isrc(src_node, ien, itype)
        self.gen_func_cases(func_name, vals, func_type)
        self.gen_sel_logic(ien, func_name, bits_corr)
        self.add_blank_lines()

    def gen_sel_logic(self, en, func_name, sel_bits):
        lines = ["always @(*) begin"]
        lines.append("{0}if({1}) begin".format(self.pre, en))
        lines.append("{0}{1}.set_isrc_val({2}({3}));".format(nsp(2, self.pre), self.src_name, func_name, sel_bits))
        lines.append("{0}end".format(self.pre))
        lines.append("end")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_cases_general(self, in_var, vals_list, vals_dict):
        lines = []
        lines.append("case({0})".format(in_var))
        wid = self.gen_width(vals_list, 1)
        for val in vals_list:
            act = ""
            if val in vals_dict.keys():
                act = vals_dict[val]
            statement_end = ";"
            if re.search(r"end\s*$", act) or re.search(r";\s*$", act):
                statement_end = ""
            curr = "{0}{1}{2}: {3}{4}".format(self.pre, val, nsp(wid - len(val), " "), act, statement_end)
            lines.append(curr)
        lines.append("endcase")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_cases(self, in_var, in_vals, out_var):
        l = len(in_vals)
        nbits = int(math.log(l, 2))
        bf = "0{0}b".format(nbits)
        vals_dict = dict()
        vals_list = list()
        for ii in range(l):
            val = "{0}'b{1}".format(nbits, format(ii, bf))
            key = "{0} = {1}".format(out_var, in_vals[ii])
            vals_list.append(val)
            vals_dict[val] = key
        return(self.gen_cases_general(in_var, vals_list, vals_dict))

    def gen_vams_icheck(self, node, exp_val, rval = 200e3, accuracy = 0.1):
        params_arr = []
        if exp_val != 1e-6:
            params_arr.append(self.gen_param_def("exp_val", exp_val))
        if rval != 200e3:
            params_arr.append(self.gen_param_def("rval", rval))
        if accuracy != 0.1:
            params_arr.append(self.gen_param_def("accuracy", self.conv(accuracy * exp_val)))
        param_def = self.gen_param_defs(params_arr)
        oexp_val = exp_val
        if exp_val > 0:
            pnode = node
            nnode = self.vss
        else:
            exp_val = -exp_val
            pnode = self.vdd
            nnode = node
        node_good = "{0}_good".format(node)
        self.ichks.append(node_good)
        lines = ["//Genearting check for {0} with an expected value of {1} with an accuracy of +-{2} * exp_val.".format(node, oexp_val, accuracy)]
        self.gen_wire_def("wire", [node_good])
        ports = "p n ig".split(" ")
        conns = [pnode, nnode, node_good]
        node_name = self.gen_node_src_name(node)
        lines.append("nvt_ichk {0}nvt_ichk_{1}{2};".format(param_def, node_name, self.gen_port_defs(ports, conns)))
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def get_max_len(self, in_strs):
        mval = 0
        for cstr in in_strs:
            mval = max(mval, len(cstr))
        return(mval)

    def gen_width(self, in_strs, extra = 2):
        mval = self.get_max_len(in_strs)
        cnspace = self.nspace if self.nspace > 0 else 4
        nval = int((mval / cnspace + extra) * cnspace)
        return(min(40, nval))

    def gen_analog_assertions_from_file(self, in_file, out_file, sig_type = Check_Type.CHECK_VOLTAGE):
        lines = []
        sigs = []
        self.store_append_line()
        with open(in_file) as fh:
            for line in fh:
                line = line.strip()
                #self.logger.info(line)
                sigs += self.gen_sigs_from_sig(line)
                #self.logger.info(lines)
        lines = self.gen_analog_assertion_task_from_sigs_list(sigs, sig_type)
        write_to_file(out_file, lines, "", True, self.logger)
        self.recover_append_line()
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_sigs_from_sig(self, sig):
        sigs = []
        if is_blank(sig):
            return(sigs)
        sig, rg, ed, st = self.parse_signal_range(sig)
        sigs = self.regen_sigs(sig, ed, st)
        return(sigs)

    def get_sig_set(self, sig_type = Check_Type.CHECK_VOLTAGE):
        curr_set = set()
        if sig_type == Check_Type.CHECK_VOLTAGE:
            curr_set = self.voltage_sigs_set
        if sig_type == Check_Type.CHECK_CURRENT:
            curr_set = self.current_sigs_set
        return(curr_set)

    def gen_analog_assertion_task_from_sigs_list(self, sigs, sig_type = Check_Type.CHECK_VOLTAGE):
        lines = []
        curr_set = self.get_sig_set(sig_type)
        self.store_append_line()
        for sig in sorted(sigs):
            if not sig in curr_set:
                curr_set.add(sig)
                #self.logger.info(sig)
                lines += self.gen_analog_assertion_task(sig, sig_type)
        self.recover_append_line()
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_analog_assertion_task_from_sig(self, sig, sig_type = Check_Type.CHECK_VOLTAGE):
        #self.logger.info(sigs)
        sigs = self.gen_sigs_from_sig(sig)
        return(self.gen_analog_assertion_task_from_sigs_list(sigs, sig_type))

    def regen_sigs(self, sig, ed, st):
        sigs = []
        if st == -1:
            return([sig])
        if ed < st:
            tmp = st
            st = ed
            ed = tmp
        ii = st
        while ii <= ed:
            sigs.append("{0}[{1}]".format(sig, ii))
            ii += 1
        return(sigs)

    def gen_terminal_assertions(self, in_file):
        lines = []
        self.store_append_line()
        with open(in_file) as fh:
            for line in fh:
                line = line.strip()
                sig, rg, ed, st = self.parse_signal_range(line)
                if not is_blank(sig):
                    lines += self.gen_dig_assertion_task("dig_io_", sig, rg, "`digtop.")
        self.recover_append_line()
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def parse_signal_range(self, in_str):
        sig = in_str
        rg = ""
        ran = ""
        st = -1
        ed = -1
        mis = match_items(r"(.*)<(.*)>", in_str)
        if mis:
            sig = mis[0]
            ran = mis[1]
            nums = ran.split(":")
            if len(nums) == 1:
                st = int(nums[0])
                ed = int(nums[0])
            else:
                st = int(nums[0])
                ed = int(nums[1])
                if st > ed:
                    tp = ed
                    ed = st
                    st = tp
                if st != ed:
                    rg = " [{0}:0]".format(ed - st)
        return(sig, rg, ed, st)

    def gen_dig_assertion_task(self, task_name_sub, sig, rg, sig_path):
        lines = []
        if is_blank(sig):
            return(lines)
        self.store_append_line()
        task_name = "check_{1}{0}".format(sig.lower(), task_name_sub)
        params_list = ["in_val"]
        params_def_list = ["logic{0}".format(rg)]
        lines += self.gen_task_header_from_list(task_name, params_list, params_def_list)
        if not re.search(r"\.$", sig_path) and not self.is_blank(sig_path):
            sig_path += "."
        lines += ["{0}ASSERT_CHECK_{1}: assert(check_dig_values({3}{2}, in_val, \"{1}_CHECK\"));".format(self.pre, sig.upper(), sig, sig_path)]
        lines += self.gen_endtask(task_name)
        self.recover_append_line()
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_analog_current_assertion_task(self, sig):
        return(self.gen_analog_assertion_task(sig, Check_Type.CHECK_CURRENT))

    def gen_analog_voltage_assertion_task(self, sig):
        return(self.gen_analog_assertion_task(sig, Check_Type.CHECK_VOLTAGE))

    def gen_analog_assertion_task(self, sig, sig_type = Check_Type.CHECK_VOLTAGE):
        lines = []
        if is_blank(sig):
            return(lines)
        self.store_append_line()
        sig_items = re.split(r"\.", sig)
        #self.logger.info(sig_items)
        sig_name = sig_items[-1]
        #self.logger.info(sig_name)
        #remove the top tb but replace with topq
        sig_sub_path = "." + ".".join(sig_items[1:])
        check_sig = "{{{0}, \"{1}\"}}".format("`topq", sig_sub_path)
        print_sig = "{0}{1}".format("`top", sig_sub_path)
        sig_name_seq = sig_name
        sig_name_seq = re.sub(r"\[", "", sig_name_seq)
        sig_name_seq = re.sub(r"\]", "", sig_name_seq)
        task_name_sub = "voltage"
        sig_seq_dict = dict()
        #self.logger.info(task_name_sub)
        if sig_type == Check_Type.CHECK_CURRENT:
            #self.logger.info("The signal type is {0}.".format(sig_type))
            task_name_sub = "current"
            sig_seq_dict = self.current_check_dict
            if len(sig_items) > 2:
                sig_name_seq = sig_items[-2] + "__" + sig_name_seq
        #self.logger.info(task_name_sub)
        #self.logger.info(sig_type)
        if sig_type == Check_Type.CHECK_VOLTAGE:
            sig_seq_dict = self.voltage_check_dict
        #self.logger.info(sig_type)
        if sig_name_seq in sig_seq_dict.keys():
            last_seq = sig_seq_dict[sig_name_seq]
            new_seq = last_seq + 1
            sig_seq_dict[sig_name_seq] = new_seq
            sig_name_seq += "_" + str(new_seq)
            sig_seq_dict[sig_name_seq] = 0
        else:
            sig_seq_dict[sig_name_seq] = 0

        task_name = "check_{1}_{0}".format(sig_name_seq, task_name_sub)
        params_list = ["min_val", "max_val", "check_desp = \"\""]
        params_def_list = ["input real", "input real", "input string"]
        lines += self.gen_task_header_from_list(task_name, params_list, params_def_list)
        lines.append("{0}string desp;".format(self.pre))
        lines.append("{0}desp = check_desp == \"\"? check_desp : $sformatf(\"(%0s)\", check_desp);".format(self.pre))
        lines += ["{0}ASSERT_CHECK_{3}__{1}: assert(check_analog_{5}({2}, min_val, max_val, $sformatf(\"CHECK_{3}_{1}: {4}%0s.\", desp)));".format(self.pre, sig_name_seq.upper(), check_sig, task_name_sub.upper(), print_sig, task_name_sub)]
        lines += self.gen_endtask(task_name)
        self.recover_append_line()
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_adc_enum(self, channels, enum_name, prefix = "ADC_CHANNEL_"):
        cn = len(channels)
        #print(wid)
        enum_list = list()
        enum_dict = dict()
        enum_key = "{2}{1}".format(self.pre, "NONE", prefix)
        enum_val = 0
        enum_list.append(enum_key)
        enum_dict[enum_key] = enum_val

        for ii in range(cn):
            enum_val = 1 << ii
            enum_key = "{2}{1}".format(self.pre, channels[ii], prefix)
            enum_list.append(enum_key)
            enum_dict[enum_key] = enum_val
        lines = self.gen_enum(cn, enum_name, enum_list, enum_dict, EnumValueOutFormat.BIN_VAL, '0')
        return(lines)

    def gen_dict(self, dict_name, in_param_type, out_param_type, params_list, params_dict):
        lines = ["{0} {1}[{2}] = '{{".format(out_param_type, dict_name, in_param_type)]
        wid = self.gen_width(params_list, 2)
        pn = len(params_list)
        for ii in range(pn):
            param = params_list[ii]
            param_val = ""
            if param in params_dict.keys():
                param_val = params_dict[param]
            if "," in param_val:
                line = "{0}{1}{2}: '{{{3}}}".format(self.pre, param, nsp(wid - len(param), " "), param_val)
            else:
                line = "{0}{1}{2}: {3}".format(self.pre, param, nsp(wid - len(param), " "), param_val)
            if ii < pn - 1:
                line += ","
            lines.append(line)
        lines.append("};")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_endtask(self, task_name):
        lines = ["endtask //{0}".format(task_name)]
        lines.append("")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_task_header_from_list(self, task_name, params_list, params_def_list):
        params_dict = self.gen_field_dict(params_list, params_def_list)
        return(self.gen_task_header(task_name, params_list, params_dict))

    def gen_task_header(self, task_name, params_list, params_dict):
        param_dec_list = list()
        for param in params_list:
            param_dec_list.append("{0} {1}".format(params_dict[param], param))
        lines = ["task automatic {0}({1});".format(task_name, ", ".join(param_dec_list))]
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_field_dict(self, fields_list, fields_def_list):
        fn = min(len(fields_list), len(fields_def_list))
        fields_dict = dict()
        if len(fields_list) != len(fields_def_list):
            self.logger.warning("Length of the fields and def list not the same")
        for ii in range(fn):
            fields_dict[fields_list[ii]] = fields_def_list[ii]
        return(fields_dict)

    def gen_struct_from_list(self, struct_name, fields_list, fields_def_list):
        fields_dict = self.gen_field_dict(fields_list, fields_def_list)
        return(self.gen_struct(struct_name, fields_list, fields_dict))

    def gen_struct(self, struct_name, fields_list, fields_dict):
        lines = ["typedef struct{"]
        for field in fields_list:
            field_type = fields_dict[field];
            lines.append("{0}{1} {2};".format(self.pre, field_type, field))
        lines.append("}}{0};".format(struct_name))
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_enum(self, enum_num_bits, enum_main_name, enum_list, enum_dict, enum_val_format = EnumValueOutFormat.HEX_VAL, filler = '0', explicit_value = False, extra_sp = 0):
        tl = 1 << enum_num_bits
        en = len(enum_list)
        max_enum_val = en - 1
        pval = -1
        for enum_name in enum_list:
            curr = pval + 1
            if enum_name in enum_dict.keys():
                curr = enum_dict[enum_name]
            max_enum_val = max(max_enum_val, curr)
            pval = curr
        if max_enum_val > tl:
            self.logger.warning("Number Bits is not succifient to cover all the list for {0}".format(enum_main_name))
            while (1 << enum_num_bits) < max_enum_val:
                enum_num_bits += 1
        lines = ["typedef enum logic[{0}:0] {{".format(enum_num_bits - 1)]
        wid = self.gen_width(enum_list, extra_sp)
        pval = -1
        for ii in range(en):
            enum_name = enum_list[ii]
            curr_val = pval + 1
            if enum_name in enum_dict.keys():
                curr_val = enum_dict[enum_name]
                enum_val = self.conv_dec_to_format_val(enum_num_bits, enum_val_format, curr_val, filler)
                enum_val_len = len(enum_val)
            else:
                if len(enum_dict) > 0:
                    self.logger.warning("{0} is not in dict keys.".format(enum_name))
                enum_val = self.conv_dec_to_format_val(enum_num_bits, enum_val_format, curr_val, filler)
                enum_val_len = len(enum_val)
                if not explicit_value:
                    enum_val = ""
            curr_line = self.gen_enum_line(wid, enum_name, enum_val)
            if ii < en - 1:
                if enum_val == "":
                    curr_line += nsp(enum_val_len + 2, " ")
                curr_line += ','
            else:
                curr_line = re.sub(r"\s*$", "", curr_line)
            lines.append(curr_line)
            pval = curr_val
        lines.append("}}{0};".format(enum_main_name))
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def conv_dec_to_format_val(self, num_bits, val_format, in_val, filler = '0'):
        ret = in_val
        num_wid = len(str(1 << num_bits))
        num_pre = 'd'
        if val_format == EnumValueOutFormat.HEX_VAL:
            ret = hex(in_val)[2:]
            num_wid = num_bits / 4
            if num_bits % 4 > 0:
                num_wid += 1
            num_pre = 'h'
        elif val_format == EnumValueOutFormat.BIN_VAL:
            ret = bin(in_val)[2:]
            num_wid = num_bits
            num_pre = 'b'
        while len(filler) > 0 and len(ret) < num_wid:
            ret = filler + ret
        ret = "{0}'{2}{1}".format(num_bits, ret, num_pre)
        return(ret)

    def gen_enum_line(self, wid, enum_var, enum_val):
        line = "{0}{1}".format(self.pre, enum_var)
        line += nsp(wid - len(line), " ")
        if enum_val != "":
            line += "= " + enum_val
        return(line)

    def gen_node_src_name(self, in_str):
        out_str = re.sub(r"\[", "_", in_str)
        out_str = re.sub(r"\]", "", out_str)
        return(out_str)

    def gen_port_defs(self, ports, conns):
        pn = len(ports)
        if len(conns) < pn:
            ii = len(conns)
            while ii < pn:
                conns.append(ports[ii])
                ii += 1
        port_defs = []
        for ii in range(pn):
            port_defs.append(self.gen_param_def(ports[ii], conns[ii]))
        return(self.gen_param_defs(port_defs, False))

    def gen_param_def(self, param, val):
        return(".{0}({1})".format(param, val))

    def gen_param_defs(self, params_arr, is_param = True):
        if len(params_arr) == 0:
            if is_param:
                return("")
            else:
                return("()")
        pd = ""
        sp = ""
        if is_param:
            pd = "#"
            sp = " "
        return("{1}({0}){2}".format(", ".join(params_arr), pd, sp))

    def gen_icheck(self, node, exp_val, exp_tor = 0.1):
        sig_good = "{0}_good".format(node)
        self.ichks.append(sig_good)
        lines = ["//Generating a current checker {3} for {0}, expected value of {1} with an accuracy spec of {2}".format(node, exp_val, exp_tor, sig_good)]
        chk_stat = "`def_ichk_val({0}, {1}, {2})".format(node, exp_val, exp_tor)
        lines.append(chk_stat)
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_chk_good(self, add_inputs = [], include_v = True, include_i = True):
        self.chks = self.vchks
        self.chks += self.ichks
        self.chks += add_inputs
        chk_name = "chk_good"
        if include_v and not include_i:
            chk_name = "v" + chk_name
        elif include_i and not include_v:
            chk_name = "i" + chk_name
        chk_stat = self.gen_wire_and("wire", chk_name, self.chks)
        return(chk_stat)

    def gen_pwr_intf_sig(self, node):
        low_node = node.lower()
        lines = ["real {0}_val = 0.0;".format(low_node)]
        lines.append("real {0}_ramp_time = 100e-6;".format(low_node))
        #lines.append("integer {0}_nstep = 50;".format(low_node))
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_vsrc_define(self, node):
        lines = ["`def_vsrc_tasks(vsrc_{0}, {0})".format(node)]
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_ramp_tasks(self, node, pwr_sig = ""):
        low_node = node.lower()
        if pwr_sig == "":
            pwr_sig = low_node + "_val"
        lines = ["always @(pwr.{0}) begin".format(pwr_sig)]
        lines.append("{0}if(pwr.{2} > 0) begin".format(self.pre, node, pwr_sig))
        lines.append("{0}`stim.en_{1} = 1'b1;".format(nsp(2, self.pre), low_node))
        lines.append("{0}ramp_{1}(pwr.{2}, pwr.{3}_ramp_time);".format(nsp(2, self.pre), node, pwr_sig, low_node))
        lines.append("{0}end else begin".format(self.pre))
        lines.append("{0}`stim.en_{1} = 1'b0;".format(nsp(2, self.pre), low_node))
        lines.append("{0}end".format(self.pre))

        lines.append("end")
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def get_cnt(rg):
        mis = match_items(r"\s*(\d+)\s*:\s*(\d+)\s*")
        if mis:
            v1 = int(mis[0])
            v2 = int(mis[1])
            return(abs(v1 - v2) + 1)
        else:
            return(int(rg))

    def gen_corr(self, node, rg):
        node_noxz = "{0}_noxz".format(node)
        node_corr = "{0}_corr".format(node)
        lines = []
        lines.append(self.gen_wire_def("wire", [node_noxz]))
        xor = ""
        bit_cnt = 1
        if rg:
            xor = "^"
            bit_cnt = self.get_cnt(rg)
        lines.append(self.gen_wire_and("assign", node_noxz, ["{1}{0} !== 1'bx".format(node, xor), "{1}{0} !== 1'bz".format(node, xor)]))
        nodes = []
        node_corr_full = node_corr
        if rg:
            node_corr_full = "{0} {1}".format(rg, node_corr_full)
        nodes.append(node_corr_full)
        lines.append(self.gen_wire_def("wire", nodes))
        lines += self.gen_sel("assign", node_corr, node_noxz, node, "{0}'b0".format(bit_cnt))
        #if self.append_line:
            #self.all_lines += lines
        return(lines)

    def gen_wire_and(self, wire_type, out_node, in_nodes, n = 0):
        stat = "{3}{0} {1} = {2};".format(wire_type, out_node, " & ".join(in_nodes), nsp(n, self.pre))
        if self.append_line:
            self.all_lines.append(stat)
        return(stat)

    def gen_wire_or(self, wire_type, out_node, in_nodes, n = 0):
        stat = "{3}{0} {1} = {2};".format(wire_type, out_node, " | ".join(in_nodes), nsp(n, self.pre))
        if self.append_line:
            self.all_lines.append(stat)
        return(stat)

    def append_from_file(self, in_file, n = 0):
        npre = nsp(n, self.pre)
        with open(in_file) as fh:
            for line in fh:
                line = re.sub(r"\n$", "", line)
                self.all_lines.append("{0}{1}".format(npre, line))

    def add_pre(self, in_arr, n = 0):
        out_arr = []
        npre = nsp(n, self.pre)
        for line in in_arr:
            out_arr.append("{0}{1}".format(npre, line))
        return(out_arr)

    def gen_always(self, sslist = ["*"], block_name = ""):
        line = "always({0}) begin".format(" or ".join(sslist))
        if block_name != "":
            line += " : {0}".format(block_name)
        if self.append_line:
            self.all_lines.append(line)
        return(line)

    def gen_end(self, n = 0):
        line = "{0}end".format(nsp(n, self.pre))
        if self.append_line:
            self.all_lines.append(line)
        return(line)

    def gen_for(self, var_name, var_start, var_end, n = 0):
        lines = ["{3}for(int {0} = {1}; {0} <= {2}; {0} = {0} + 1) begin".format(var_name, var_start, var_end, nsp(n, self.pre))]
        if self.append_line:
            self.all_lines += lines
        return(lines)

    def gen_wire_def(self, wire_type, nodes):
        line = "{0} {1};".format(wire_type, ", ".join(nodes), self.pre)
        if self.append_line:
            self.all_lines.append(line)
        return(line)

    def conv(self, in_num):
        ns = str(in_num)
        if "." not in ns:
            return(ns)
        if abs(in_num) < 1e-4 and abs(in_num) > 0:
            ns = "{0:.3e}".format(in_num)
        else:
            pind = ns.index(".")
            l = len(ns)
            if l - pind > 6:
                ns = "{0:.4f}".format(in_num)
        l = len(ns)
        ch = ns[l - 1]
        r = l - 1
        while ns[r] == "0":
            r -= 1
        if ns[r] == ".":
            return(ns[0:r + 2])
        return(ns[0:r + 1])

    def get_thr_comp_type(self, comp_dir):
        self.thr_type = Threshold.Rising if comp_dir == "F" else Threshold.Falling
        self.comp_type = Comp.Comp_2p if comp_dir == "F" else Comp.Comp_2n
        return(self.thr_type, self.comp_type)

    def print_to_outfile(self, in_lines):
        this_pre = self.pre if self.indent else ""
        write_to_file(self.out_file, in_lines, this_pre, True, self.logger, self.write_mode)

    def print_endmodule(self):
        lines = ["{0}//Autogen Ends".format(self.pre if self.indent else "")]
        lines += ["endmodule"]
        lines += ["//end of module {0}".format(self.block_name)]
        write_to_file(self.out_file, lines, "", True, self.logger, "a")

class Code_Gen_Output_Post_Process(Code_Gen):
    def __init__(self, block_name_abbv, real_wire_def, in_file, out_file, logger, real_out_name, nspace = 4):
        super().__init__(block_name_abbv, real_wire_def, in_file, out_file, logger, nspace)
        self.real_out_name = real_out_name

    def class_info(self):
        return("Generating code bases for sv with post processing on the outputs")

    def pre_lines(self):
        return(super().pre_lines() + ["wire {0};".format(self.temp_out_name)])

    def gen_comp_out(self):
        #self.temp_out_name = "{0}".format(self.block_comp_desp)
        self.temp_out_name = self.block_comp_desp
        return(self.temp_out_name)

    def post_lines(self):
        self.real_out_line = "assign {0} = {1}".format(self.real_out_name, self.gen_en_out(self.comp_en, "~" + self.temp_out_name, 0))
        return(["//Generating post processing of sig {0} from sig {1}".format(self.real_out_name, self.temp_out_name), self.real_out_line])

class Code_Gen_Hyst_Option(Code_Gen):
    def __init__(self, block_name_abbv, real_wire_def, in_file, out_file, logger, nspace = 4):
        super().__init__(block_name_abbv, real_wire_def, in_file, out_file, logger, nspace)

    def class_info(self):
        return("Generating code bases for sv files with hyst options")

    def assign_self_vars(self, thds_v, hyst, comp_dir, comp_in, comp_name, comp_en, mux_rev = 1, mux_en = "1'b1"):
        super().assign_self_vars(thds_v, hyst, comp_dir, comp_in, comp_name, comp_en, mux_rev, mux_en)
        self.hyst_sel = "_".join(["D2A", self.block_name_abbv, self.comp_in, self.comp_name, "HYS", self.rev_comp_dir, "1P8"])
        self.hyst_sig = "_".join([self.block_name_abbv, self.comp_in, self.comp_name, self.rev_comp_dir])

    def pre_lines(self):
        return(self.thre_lines)

    def gen_new_th(self, in_vals, hysts, th_type = Threshold.Falling):
        ii = 0
        out_sigs = []
        out_lines = []
        all_lines = ["", "//Generating {0} from bits {2} based on hyst of {1}".format(self.hyst_sig, hysts, self.hyst_sel)]

        for val in in_vals:
            out_vals = []
            for hyst in hysts:
                new_val = val + hyst
                if th_type == Threshold.Falling:
                    new_val = val - hyst
                if th_type == Threshold.Rising:
                    new_val = val + hyst
                out_vals.append(new_val)
            curr_sig = self.hyst_sig + "_" + str(ii)
            out_lines += self.gen_sv_mux_num(out_vals, self.hyst_sel, curr_sig, self.mux_rev, self.mux_en)
            out_sigs.append(curr_sig)
            ii += 1
        all_lines.append(self.gen_wire_def(self.wire_type, out_sigs))
        #self.gen_wire_def(self.wire_type, out_sigs)
        all_lines += out_lines
        self.thre_lines = all_lines
        self.logger.info(all_lines)
        return(out_sigs)

class Connection_Parser():
    def __init__(self, conn_file, inst_file, inst_pin_file, pin_checks, logger, out_file):
        self.incr = 0
        self.logger = logger
        self.conn_dict = load_from_jsonfile(conn_file)
        self.flatten_dict(self.conn_dict, "conn_dict")
        #print(conn_dict)
        self.inst_dict = load_from_jsonfile(inst_file)
        #print(len(self.inst_dict))
        self.flatten_dict(self.inst_dict, "inst_dict")
        #print(len(self.inst_dict))
        self.logger.info("Increased count: {0}".format(self.incr))
        #print(inst_dict)
        self.inst_pin_dict = load_from_jsonfile(inst_pin_file)
        self.pin_checks = pin_checks
        self.out_file = out_file
        #print(inst_pin_dict)

    def format_pin(self, in_name):
        out_pins = []
        if type(in_name) == list:
            for name in in_name:
                out_pins += self.format_pin_str(name)
        else:
            out_pins = self.format_pin_str(in_name)
        return(out_pins)

    def format_pin_str(self, in_name):
        out_pins = []
        if re.search(",", in_name):
            all_pins = in_name.split(",")
            inst_path = ".".join(all_pins[0].split(".")[0 : -1])
            curr_pins = []
            for ii in range(len(all_pins)):
                if ii == 0:
                    curr_pins.append(all_pins[ii])
                else:
                    curr_pins.append("{0}.{1}".format(inst_path, all_pins[ii]))
            for pin in curr_pins:
                out_pins += self.format_pin(pin)
        elif re.search(r"<\d+:\d+:\d+>", in_name):
            mstr = match_items(r"(<\d+:\d+:\d+>)", in_name)
            nums = [int(x) for x in match_items(r"<(\d+):(\d+):(\d+)>", in_name)]
            num1 = nums[0]
            num2 = nums[1]
            change = nums[2]
            ii = num1
            curr_pins = []
            if num1 > num2:
                while ii >= num2:
                    new_pin = re.sub(re.escape(mstr), "<{0}>".format(ii), in_name, 1)
                    curr_pins.append(new_pin)
                    ii -= change
            else:
                while ii <= num2:
                    new_pin = re.sub(re.escape(mstr), "<{0}>".format(ii), in_name, 1)
                    curr_pins.append(new_pin)
                    ii += change
            for pin in curr_pins:
                out_pins += self.format_pin(pin)
        elif re.search(r"<\d+:\d+>", in_name):
            mstr = match_items(r"(<\d+:\d+>)", in_name)
            nums = [int(x) for x in match_items(r"<(\d+):(\d+)>", in_name)]
            num1 = nums[0]
            num2 = nums[1]
            ii = num1
            curr_pins = []
            if num1 > num2:
                while ii >= num2:
                    new_pin = re.sub(re.escape(mstr), "<{0}>".format(ii), in_name, 1)
                    curr_pins.append(new_pin)
                    ii -= 1
            else:
                while ii <= num2:
                    new_pin = re.sub(re.escape(mstr), "<{0}>".format(ii), in_name, 1)
                    curr_pins.append(new_pin)
                    ii += 1
            for pin in curr_pins:
                out_pins += self.format_pin(pin)
        elif re.search(r"<\*\d+>", in_name):
            cnt = int(match_items(r"<\*(\d+)>", in_name))
            main_name = re.sub(r"<\*\d+>", "", in_name)
            curr_pins = []
            for ii in range(cnt):
                curr_pins.append(main_name)
            for pin in curr_pins:
                out_pins += self.format_pin(pin)
        else:
            out_pins = [in_name]
        return(out_pins)


    def flatten_dict(self, in_dict, desp = ""):
        dk = list(in_dict.keys())
        for k in dk:
            pks = self.format_pin(k)
            kv = in_dict[k]
            pkvs = self.format_pin(kv)
            self.incr += len(pks) - 1
            del in_dict[k]
            if len(pks) == len(pkvs):
                for ii in range(len(pks)):
                    in_dict[pks[ii]] = pkvs[ii]
            else:
                #self.logger.info("{2} : {0} cannot match with {1}".format(k, kv, desp))
                for ii in range(len(pks)):
                    if ii < len(pkvs):
                        in_dict[pks[ii]] = pkvs[ii]
                    else:
                        in_dict[pks[ii]] = pkvs[-1]

    def check_pins(self):
        self.logger.info("Checking the pin connections")
        out_arr = []
        for inst in sorted(self.inst_dict.keys()):
            inst_device = self.inst_dict[inst]
            inst_pins = self.inst_pin_dict[inst_device]
            for check_pin in self.pin_checks:
                if check_pin in inst_pins:
                    pin = "{0}.{1}".format(inst, check_pin)
                    pin_conn = self.find_pin_conn(pin)
                    pln = len(pin_conn.split("/"))
                    to_print = False
                    if pln > 2:
                        to_print = True
                    if re.search(r"nmos", inst_device):
                        if check_pin == "B" and not (re.search(r"vss", pin_conn.lower()) or re.search(r"gnd", pin_conn.lower())):
                            to_print = True
                    if to_print:
                        #self.logger.warning("{0}({2}) -> {1}".format(pin, pin_conn, inst_device))
                        out_arr.append("{0}({2}) -> {1}".format(pin, pin_conn, inst_device))
        if out_arr:
            write_to_file(self.out_file, out_arr, "", True, self.logger)
                    #if check_pin == "SUB" and not re.search("sub", pin_conn.lower()):
                        #self.logger.warning("{0} -> {1}".format(pin, pin_conn))

    def find_pin_conn(self, in_str):
        if in_str in self.conn_dict.keys():
            self.conn_dict[in_str] = self.find_pin_conn(self.conn_dict[in_str])
            return(self.conn_dict[in_str])
        else:
            return(in_str)

def match_items(in_creteria, in_str):
    rec = re.compile(in_creteria)
    res = rec.search(in_str)
    if res:
        reg = res.groups()
        if len(reg) == 1:
            return(reg[0])
        return(reg)

def rep_mspaces(in_str):
    out_str = in_str
    out_str = re.sub(r"\s+", " ", out_str)
    return(out_str)

def remove_pr_tr_spaces(in_str):
    out_str = in_str
    out_str = re.sub(r"^\s*|\s*$", "", out_str)
    return(out_str)

def split_pins(in_str):
    out_str = remove_pr_tr_spaces(in_str)
    out_arr = [rep_mspaces(remove_pr_tr_spaces(x)) for x in re.split(",", out_str)]
    return(out_arr)

def dump_to_jsonfile(in_struct, out_file):
    with open(out_file, "w") as fh:
        json.dump(in_struct, fh)

def load_from_jsonfile(in_file):
    with open(in_file) as fh:
        return(json.load(fh))
    return(None)

def write_to_file(out_file, in_lines, pre = "", new_line = None, logger = None, mode = "w"):
    logger_line = ""
    writting_mode = "Writing" if mode == "w" else "Appending"
    if logger:
        logger_line += ("{1} to {0} with the following content: \n".format(out_file, writting_mode))
    join_ch = ""
    if new_line:
        join_ch = "\n"
    #join_ch += pre
    with open(out_file, mode) as fh:
        out_lines = ""
        ln = len(in_lines)
        for ii in range(ln):
            line = in_lines[ii]
            print(line)
            if is_blank(line):
                line = join_ch
            else:
                line = pre + line + join_ch
            out_lines += line
        fh.write(out_lines)
        if logger:
            logger_line += out_lines
            logger.info(logger_line)

def get_pin_info(in_str):
    in_str = remove_pr_tr_spaces(in_str)
    mi = match_items(r"(\w*)\s*\[(.*)\]\s*(\w*)", in_str)
    if mi is not None:
        return(mi)
    mi = re.split("\s+", in_str)
    return(mi)

def gen_wid_lim_lines(in_arr, lim = 60, ind = 2, sep = ", "):
    line = ""
    all_lines = []
    an = len(in_arr)
    ii = 0
    psp = nsp(ind)
    for val in in_arr:
        line += val
        if ii < an - 1:
            line += sep
        if len(line) > lim:
            line = re.sub(r"\s*$", "", line)
            all_lines.append(line)
            line = psp
        ii += 1
    if line != psp:
        all_lines.append(line)
    return(all_lines)

def get_lib_name(in_file = __file__):
    dname = os.path.dirname(os.path.abspath(in_file))
    dname_comps = re.split(re.escape(os.sep), dname)
    return(dname_comps[-3])

def get_block_name(in_file = __file__):
    dname = os.path.dirname(os.path.abspath(in_file))
    dname_comps = re.split(re.escape(os.sep), dname)
    return(dname_comps[-2])

def get_file_dir(in_file = __file__):
    return(os.path.dirname(os.path.abspath(in_file)))

def get_file_name(in_file = __file__):
    return(os.path.splitext(os.path.basename(in_file))[0])

def get_file_last_ext(in_file = __file__):
    return(os.path.splitext(os.path.basename(in_file))[-1])

def get_file_rem_ext(in_file = __file__):
    return(".".join(os.path.splitext(os.path.basename(in_file))[1:]))

def get_file_pre_ext(in_file = __file__):
    return(".".join(os.path.splitext(os.path.basename(in_file))[0:-1]))

def prepare_setups(block_name_abbv, real_wire_def, in_file = __file__, out_file_name = "temp.sv", use_hdlp = True, nspace = 4, indent = True):
    file_dir = get_file_dir(in_file)
    main_file_name = get_file_name(in_file)
    my_logger = Logger(file_dir + os.sep + main_file_name + ".log")
    logger = my_logger.logger
    out_code_file = file_dir + os.sep + out_file_name
    cg = Code_Gen(block_name_abbv, real_wire_def, in_file, out_code_file, logger, nspace, use_hdlp, indent)
    return(file_dir, main_file_name, my_logger, logger, out_code_file, cg)

def get_linenumber():
    cf = currentframe()
    return cf.f_back.f_lineno

def get_curr_time():
    now = datetime.now()
    ds = now.strftime("%b.  %d %H:%M:%S %Y")
    return(ds)

def nsp(num, rep = " "):
    ret = ""
    for ii in range(num):
        ret += rep
    return(ret)

def is_blank(in_str):
    if re.search(r"^\s*$", in_str):
        return(True)
    return(False)

def range_key(in_str):
    if is_blank(in_str):
        return(-1)
    if not re.search(":", in_str):
        try:
            return(int(in_str))
        except:
            return(0)
    else:
        pin_ranges = [int(remove_pr_tr_spaces(x)) for x in in_str.split(":") if not is_blank(x)]
        return(max(pin_ranges))

def main():
    print("Hello")
    print(get_curr_time())

if __name__ == "__main__":
    main()

