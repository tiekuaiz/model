function! Gen_AMS(module_spec, ...)
    if match(a:module_spec, ",") >= 0 && !(match(a:module_spec, " ") >= 0)
        let l:module_info = split(a:module_spec, ",")
    else
        let l:module_info = split(a:module_spec)
    endif
    "module name is the hash key which has the module information
    let l:all_hashes = Gen_AMS_Hashes()
    let l:current_line_num = line(".")
    let l:all_modules_hash = all_hashes[0]
    "num is the hash key
    let l:all_modules_num_hash = all_hashes[1]
    "module name is the hash key which shows the number of what hash it is
    let l:all_modules_def_num_hash = all_hashes[2]
    "name is the hash key
    let l:inst_def = ""
    if len(l:module_info) >= 1
        let l:module_name = module_info[0]
        if has_key(l:all_modules_num_hash, l:module_name)
            let l:module_name = l:all_modules_num_hash[l:module_name]
        endif
        if has_key(l:all_modules_hash, l:module_name)
            let l:module_pin_def = split(l:all_modules_hash[l:module_name][0])
            "let l:module_name_def = split(l:all_modules_hash[l:module_name][1])
            let l:module_name_def = l:all_modules_hash[l:module_name][1]
            let l:module_param_list = split(l:all_modules_hash[l:module_name][2])
            let l:module_param_value_list = split(l:all_modules_hash[l:module_name][3])
            if len(l:module_info) >= 2
                let l:pin_param_arrays = Split_pin_param(l:module_info[1:])
            else
                let l:pin_param_arrays = Split_pin_param([])
            endif
            let l:pin_array = l:pin_param_arrays[0]
            let l:param_array = l:pin_param_arrays[1]
            let l:pin_def_lists = Gen_module_pin_def(l:module_name, l:module_pin_def, l:pin_array)
            let l:pin_def_str = l:pin_def_lists[0]
            let l:des_pin_list = l:pin_def_lists[1]
            if len(l:pin_array) == 0
                let l:param_str = Gen_default_param_str(l:module_param_list, l:module_param_value_list, l:param_array)
            else
                let l:param_str = Gen_param_def(l:param_array)
            endif
            "let l:inst_name = toupper(Gen_module_name(l:module_name_def, l:des_pin_list))
            "echo a:0
            let l:inst_name = Gen_module_name(l:module_name_def, l:des_pin_list)
            if a:0 > 0
                let l:inst_name = Gen_module_name(l:module_name_def, l:des_pin_list, a:1)
            endif
            let l:inst_def = "    " . l:module_name . " " . l:param_str . l:inst_name . l:pin_def_str . ";"
            if match(l:module_name, "ams.*src.*") >= 0 && len(l:pin_array) > 0
                let l:source_array = Get_vdd_vss()
                let l:supply_str = l:source_array[0]
                if l:supply_str == ""
                    let l:supply_str = "vdd"
                endif
                let l:ground_str = l:source_array[1]
                if l:ground_str == ""
                    let l:ground_str = "vss"
                endif
                let l:source_array = [l:supply_str, l:ground_str]
                let l:critical_node = l:des_pin_list[0]
                if index(l:source_array, l:critical_node) >= 0
                    let l:critical_node = l:des_pin_list[1]
                endif
                let l:src_strs = Gen_src(l:module_name, l:inst_name, l:critical_node)
            end
            if l:module_name == "ams_switch" && len(l:pin_array) > 0
                let l:switch_control_reg = Gen_switch_strs(l:des_pin_list[-1])
                if l:switch_control_reg != ""
                    let l:inst_def = join([l:switch_control_reg, l:inst_def], "\n")
                endif
            endif
        else
            echo "Cannot find " . l:module_name . "\n"
        endif
    else
        echo "Not enough parameters in " . a:module_spec . "\n"
    endif
    execute ":" . l:current_line_num
    let @z = l:inst_def
    put z
    "call setline(".", getline(".") . l:inst_def)
    "call Replace_whole_file("tendtask", "endtask")
    "return l:inst_def
endfunction

function! Gen_reg_portion(start_bit, num_bits, table_name, last_item, ...)
    let l:current_line_num = line(".")
    let l:end_bit = a:start_bit - a:num_bits + 1
    let l:in_data_str = "in_value[" . a:start_bit . ":" . l:end_bit . "]"
    if a:last_item == 1
        let l:end_comma = ""
    else
        let l:end_comma = ","
    endif
    let l:orig_data_format = a:num_bits . "'b%" . a:num_bits . "b"
    if len(a:000) >= 1
        let l:my_func_array = My_split(a:000[0])
        let l:func_name = l:my_func_array[0]
        if len(l:my_func_array) >= 2
            let l:func_unit = l:my_func_array[1]
            if len(l:my_func_array) >= 3
                let l:func_params = [l:in_data_str] + l:my_func_array[2:]
            else
                let l:func_params = [l:in_data_str]
            endif
        else
            let l:func_unit = ""
            let l:func_params = [l:in_data_str]
        endif
        let l:func_format = "%0d"
        let l:sformat_str = "$sformatf(\"" .  a:table_name . " = " . l:func_format . l:func_unit . "(" . l:orig_data_format . ")\", " . l:func_name . "(" . join(l:func_params, ", ") . "), " . l:in_data_str . ")"
    else
        let l:sformat_str = "$sformatf(\"" . a:table_name . " = " . l:orig_data_format . "\", " . l:in_data_str . ")"
    endif
    if match(a:table_name, "table") >= 0
        let l:out_str = Gen_num_spaces(8) . a:start_bit . "   :   '{" . a:num_bits . ", $sformatf(\"%s(" . l:orig_data_format . ")\", " . a:table_name . "[" . l:in_data_str . "], " . l:in_data_str . ")}" . l:end_comma
    else
        let l:out_str = Gen_num_spaces(8) . a:start_bit . "   :   '{" . a:num_bits . ", " . l:sformat_str ."}" . l:end_comma
    endif
    execute ":" . l:current_line_num
    let @z = l:out_str
    put z
    return l:out_str
endfunction

"Gen_iref_good("node1 node2 en cur_value node_index vol_ref_value")
function! Gen_iref_good(in_str)
    let l:ref_info = My_split(a:in_str)
    if len(l:ref_info) >= 3
        let l:node1 = l:ref_info[0]
        let l:node2 = l:ref_info[1]
        let l:en = l:ref_info[2]
        let l:cur_value = Conv_str_num(l:ref_info[3])
        let l:node_index = 0
        let l:vol_ref_value = 0.5
        if len(l:ref_info) >= 5
            let l:node_index = str2nr(l:ref_info[4])
            if len(l:ref_info) >= 6
                let l:vol_ref_value = Conv_str_num(l:ref_info[5])
            endif
        endif
        let l:res_value = Convert_num_str_unit(l:vol_ref_value / l:cur_value)
        "let l:out_str = "Resistor values is " . l:res_value
        "let l:out_str = l:out_str . "\n" . join(l:ref_info[0 : 1] + [l:res_value], " ")
        "let l:out_str = l:out_str . printf("\nref : %1.3f, current %1.3e\n", l:vol_ref_value, l:cur_value)
        "let l:out_str = l:out_str . join(["ams_switch"] + l:ref_info[0 : 1] + ["~" . l:en], " ")
        "let l:out_str = l:out_str . "\n" . join(l:ref_info[0 : 1] + [Remove_tr_fl_zeros(printf("%1.3f", l:vol_ref_value))] + [printf("%d", l:node_index)], " ")
        "let @z = l:out_str
        "put z
        call Gen_resistor(join(l:ref_info[0 : 1] + [l:res_value], " "))
        call Gen_AMS(join(["ams_switch"] + l:ref_info[0 : 1] + ["~" . l:en], " "))
        call Gen_ref_good(join(l:ref_info[0 : 1] + [Remove_tr_fl_zeros(printf("%1.3f", l:vol_ref_value))] + [printf("%d", l:node_index)], " "))
    else
        let @z="    //Gen_iref_good(\"node1 node2 en cur_value node_index vol_ref_value\")\n"
        put z
    endif
endfunction

function! Conv_str_num(in_str)
    let l:units = My_split("T t G g M x K k m u U n N p P f F")
    let l:unit_numbers = My_split("e12 e12 e9 e9 e6 e6 e3 e3 e-3 e-6 e-6 e-9 e-9 e-12 e-12 e-15 e-15")
    let l:unit_index = 0
    let l:out_str = a:in_str
    for l:unit in l:units
        if match(a:in_str, l:unit) >= 0
            if match(a:in_str, "\\.") < 0
                let l:out_str = substitute(a:in_str, l:unit, ".0" . l:unit_numbers[l:unit_index], "g")
            else
                let l:out_str = substitute(a:in_str, l:unit, l:unit_numbers[l:unit_index], "g")
            endif
            break
        endif
        let l:unit_index += 1
    endfor
    let l:out_num = str2float(l:out_str)
    return l:out_num
endfunction

"Gen_ref_good("node ref_node ref_voltage optionl_ref_num")
function! Gen_ref_good(in_str)
    let l:ref_info = My_split(a:in_str)
    if len(l:ref_info) >= 3
        let l:node = l:ref_info[0]
        let l:ref_node = l:ref_info[1]
        let l:ref_voltage = str2float(l:ref_info[2])
        if l:ref_voltage > 1.5
            let l:bot_ref = l:ref_voltage * 0.9
            let l:top_ref = l:ref_voltage * 1.1
            let l:hyst = l:ref_voltage * 0.04
        elseif l:ref_voltage > 0.5
            let l:bot_ref = l:ref_voltage * 0.8
            let l:top_ref = l:ref_voltage * 1.2
            let l:hyst = l:ref_voltage * 0.08
        else
            let l:bot_ref = l:ref_voltage - 0.1
            let l:top_ref = l:ref_voltage + 0.1
            let l:hyst = 0.04
        endif
        let l:nets_array = []
        let l:comp_array = []
        for l:ref_value in [l:bot_ref, l:top_ref]
            if len(l:ref_info) >= 4 && l:ref_info[3] != "0"
                let l:comp_info_array = Gen_comp(l:node, l:ref_node, l:ref_value, l:hyst, 1)
            else
                let l:comp_info_array = Gen_comp(l:node, l:ref_node, l:ref_value, l:hyst)
            endif
            let l:nets_array = add(l:nets_array, l:comp_info_array[0])
            let l:comp_array = add(l:comp_array, l:comp_info_array[1])
        endfor
        if len(l:ref_info) >= 4
            let l:node_good = printf("%s_good", l:ref_node)
        else
            let l:node_good = printf("%s_good", l:node)
        endif
        let l:node_good_def = printf("    assign %s = %s & ~%s;", l:node_good, l:nets_array[0], l:nets_array[1])
        let l:nets_array = add(l:nets_array, l:node_good)
        let l:nets_def = "    wire " . join(l:nets_array, ", ") . ";"
        let l:comp_def = join(l:comp_array, "\n")
        let l:out_def = join([l:nets_def, l:comp_def, l:node_good_def], "\n")
        let @z = l:out_def
        put z
        return l:out_def
    else
        echo "Not enough information for generating the comparators"
    endif
endfunction

function! Gen_comp(node_name, ref_node, ref_value, hyst_value, ...)
    let l:offset_value = -a:ref_value
    let l:refp = Convert_num_strp(a:ref_value)
    if len(a:000) >= 1
        let l:out_node = printf("%s__gt%s", a:ref_node, l:refp)
    else
        let l:out_node = printf("%s__gt%s", a:node_name, l:refp)
    endif
    let l:OUT_NODE = toupper(l:out_node)
    let l:comp_desp = printf("//  Comparator compares between %s and %s with a threshold of %s\n", a:node_name, a:ref_node, Convert_num_str(a:ref_value))
    let l:comp_def = printf("%s    ams_compEn39 #(.offset(%s), .hyst(%s)) COMP_%s(.p(%s), .n(%s), .en(1'b1), .out(%s));", l:comp_desp, Convert_num_str(l:offset_value), Convert_num_str(a:hyst_value), l:OUT_NODE, a:node_name, a:ref_node, l:out_node)
    return [l:out_node, l:comp_def]
endfunction

function! Convert_num_str_unit(in_num)
    let l:units_list = My_split("T G M K 0 m u n p f")
    let l:units_conv_list = My_split("1.0e12 1.0e9 1.0e6 1.0e3 1 1.0e-3 1.0e-6 1.0e-9 1.0e-12 1.0e-15")
    let l:ii = 0
    let l:in_num_float = a:in_num * 1.0
    if l:in_num_float > 1.0e15 || l:in_num_float < 1.0e-15
        let l:out_num = printf("%1.3e", l:in_num_float)
    else
        let l:unit_found = 0
        while l:ii < len(l:units_list)
            let l:unit = l:units_list[l:ii]
            let l:unit_conv_num = Conv_str_num(l:units_conv_list[l:ii])
            if l:in_num_float >= l:unit_conv_num
                let l:out_unit = l:unit
                let l:out_unit_conv_num = l:unit_conv_num
                let l:unit_found = 1
                break
            endif
            let l:ii += 1
        endwhile
        if l:out_unit_conv_num == 1
            let l:out_unit = ""
        endif
        let l:out_num = Remove_tr_fl_zeros(printf("%1.3f", l:in_num_float / l:out_unit_conv_num))
        let l:out_num = printf("%s%s", l:out_num, l:out_unit)
    endif
    return l:out_num
endfunction

function! Convert_num_str_int(in_num)
    let l:num_str = printf("%d", float2nr(a:in_num))
    return l:num_str
endfunction

function! Convert_num_str(in_num)
    let l:num_str = printf("%1.3f", a:in_num)
    let l:num_str = substitute(l:num_str, "0*$", "", "g")
    let l:num_str = substitute(l:num_str, "\\.$", ".0", "g")
    return l:num_str
endfunction

function! Convert_num_strp(in_num)
    let l:num_str = Convert_num_str(a:in_num)
    let l:num_str = substitute(l:num_str, "\\.", "p", "g")
    let l:num_str = substitute(l:num_str, "-", "m", "g")
    return l:num_str
endfunction

function! My_split(in_str)
    let l:local_str = Remove_tr_fl_spaces(a:in_str)
    let l:out_array = []
    if match(l:local_str, ",") >= 0
        let l:temp_out_array = Remove_tr_fl_spaces_array(split(l:local_str, ","))
        for l:array_item in l:temp_out_array
            let l:local_out_array = split(l:array_item)
            for l:local_array_item in l:local_out_array
                let l:out_array = add(l:out_array, l:local_array_item)
            endfor
        endfor
    else
        let l:out_array = split(l:local_str)
    endif
    return l:out_array
endfunction

function! Gen_bits_info(bits_desp, bits_info)
    let l:current_line_num = line(".")
    let l:bits_array = My_split(a:bits_info)
    let l:bits_q_array = []
    for l:item in l:bits_array
        let l:bits_q_array = add(l:bits_q_array, "\"" . l:item . "\"")
    endfor
    let l:out_str = Gen_num_spaces(4) . a:bits_desp . " = '{" . join(l:bits_q_array, ", ") . "};"
    let @z = l:out_str
    put z
    execute ":" . l:current_line_num
    return l:out_str
endfunction

"Gen_enum_name_tble("enum_name enum0 ... enumnnnn")
function! Gen_enum_name_table(enum_names)
    let l:current_line_num = line(".")
    let l:task_name_pres = split(a:enum_names)
    let l:out_str = ""
    if len(l:task_name_pres) >= 2
        let l:num_bits = Get_num_bits(len(l:task_name_pres) - 1)
        let l:enum_def = l:task_name_pres[0]
        let l:enum_list = l:task_name_pres[1:]
        let l:CAP_enum_def = toupper(l:enum_def)
        let l:lower_enum_def = tolower(l:enum_def)
        let l:CAP_enum_list_value = Gen_enum_list_value(Capitize_all_array(l:enum_list))
        let l:CAP_enum_list = l:CAP_enum_list_value[0]
        let l:CAP_enum_value_list = l:CAP_enum_list_value[1]
        let l:out_array = [Gen_enum_def(l:enum_def, l:CAP_enum_list, l:CAP_enum_value_list), Gen_enum_def_table(l:enum_def, l:CAP_enum_list)]
        let l:all_enums = [l:CAP_enum_def . "_E", "table_" . l:lower_enum_def] + l:CAP_enum_list
        let l:existing_array = Filter_str_by_existence(l:all_enums, 1)
        if len(l:existing_array) >= 1
            let l:out_str = "//Nodes " . join(l:existing_array, ", ") . " exist. Regenerate enum names.. please."
        else
            let l:out_str = join(l:out_array, "\n\n") . "\n\n"
            "echo l:out_str
        endif
    else
        let l:out_str = "//Not enough information provided for the enum."
    endif
    execute ":" . l:current_line_num
    let @z = l:out_str
    put z
    execute ":" . l:current_line_num
    return l:out_str
endfunction

"Generate enumerator value and enum lists
function! Gen_enum_list_value(enum_list)
    let l:out_array = []
    let l:out_enum = []
    let l:out_enum_value = []
    if len(a:enum_list) >= 1
        let l:ii = 0
        let l:jj = -1
        while l:ii < len(a:enum_list)
            let l:curr_item = a:enum_list[l:ii]
            if match(l:curr_item, "=") > 0
                let l:split_items = split(l:curr_item, "=")
                let l:enum_name = l:split_items[0]
                let l:jj = l:split_items[1]
            else
                let l:enum_name = l:curr_item
                let l:jj += 1
            endif
            let l:out_enum = add(l:out_enum, l:enum_name)
            let l:out_enum_value = add(l:out_enum_value, l:jj)
            let l:ii += 1
        endwhile
    endif
    let l:out_array = [l:out_enum, l:out_enum_value]
    return l:out_array
endfunction

"Generate enumerator definition
function! Gen_enum_def(enum_name, enum_list, enum_value_list)
    let l:enum_lines = []
    let l:num_bits = Get_num_bits(a:enum_value_list[-1])
    let l:aligned_enum_list = Gen_aligned_array(a:enum_list, 4, "=")
    let l:ii = 0
    for l:item in l:aligned_enum_list
        let l:enum_lines = add(l:enum_lines, l:item . "   " . l:num_bits . "'h" . printf("%x", a:enum_value_list[l:ii]))
        let l:ii += 1
    endfor
    let l:CAP_enum_name = toupper(a:enum_name) . "_E"
    let l:enum_str = "typedef enum bit[" . (l:num_bits - 1) . ":0]{\n" . join(l:enum_lines, ",\n") . "\n}" . l:CAP_enum_name . ";"
    return l:enum_str
endfunction

function! Gen_enum_def_table(enum_name, enum_list)
    let l:table_name = "table_" . tolower(a:enum_name)
    let l:CAP_enum_name = toupper(a:enum_name) . "_E"
    let l:aligned_enum_list = Gen_aligned_array(a:enum_list, 4, ":")
    let l:table_lines = []
    let l:ii = 0
    for l:item in l:aligned_enum_list
        let l:table_lines = add(l:table_lines, l:item . "   \"" . Capitize_first(substitute(a:enum_list[l:ii], "_", " ", "g")) . "\"")
        let l:ii += 1
    endfor
    let l:table_str = "string " . l:table_name . "[" . l:CAP_enum_name . "] = '{\n" . join(l:table_lines, ",\n") . "\n};"
    return l:table_str
endfunction

"replace all underscore to spaces
function! Replace_all_us_sp(in_array)
    let l:new_array = []
    for l:item in a:in_array
        let l:new_array = add(l:new_array, substitute(l:item, "_", " ", "g"))
    endfor
    return l:new_array
endfunction

function! Capitize_first_array(in_array)
    let l:new_array = []
    for l:item in a:in_array
        let l:new_array = add(l:new_array, Capitize_first(l:item))
    endfor
    return l:new_array
endfunction

function! Capitize_all_array(in_array)
    let l:new_array = []
    for l:item in a:in_array
        let l:new_array = add(l:new_array, toupper(l:item))
    endfor
    return l:new_array
endfunction

function! Capitize_first(in_str)
    let l:out_str = ""
    let l:ii = 0
    while l:ii < len(a:in_str)
        let l:char = a:in_str[l:ii]
        if l:ii == 0
            let l:out_str = l:out_str . toupper(l:char)
        else
            let l:out_str = l:out_str . tolower(l:char)
        endif
        let l:ii += 1
    endwhile
    return l:out_str
endfunction

function! Get_max_len(in_array)
    let l:max_len = 0
    if len(a:in_array) >= 1
        for l:item in a:in_array
            if len(l:item) > l:max_len
                let l:max_len = len(l:item)
            endif
        endfor
    endif
    return l:max_len
endfunction

function! Gen_aligned_array(in_array, prefill_num_tab, append_symbol)
    let l:out_array = []
    if len(a:in_array) >= 1
        let l:array2 = Fill_array_space(a:in_array, a:prefill_num_tab)
        let l:max_len = Get_max_len(l:array2)
        let l:str_len = Get_aligned_num(l:max_len)
        for l:item in l:array2
            let l:new_item = l:item . Gen_num_spaces(l:str_len - len(l:item)) . a:append_symbol
            let l:out_array = add(l:out_array, l:new_item)
        endfor
    endif
    "for l:item in l:out_array
        "echo l:item
    "endfor
    return l:out_array
endfunction

function! Get_aligned_num(in_num)
    let l:out_num = (a:in_num / 4 + 1) * 4
    "echo l:out_num
    return l:out_num
endfunction

function! Get_num_bits(in_num)
    let l:out_num = a:in_num
    if l:out_num == 0
        let l:num_bits = 1
    else
        let l:num_bits = 0
    endif
    while l:out_num >= 2
        let l:out_num = l:out_num / 2
        let l:num_bits += 1
    endwhile
    if l:out_num == 1
        let l:num_bits += 1
    endif
    "echo l:num_bits
    return l:num_bits
endfunction

"Gen_func('Gen_valid_enum', 'enum_name', 'num_bits')
"defnition of function Gen_valid_enum
function! Gen_enum_funcs(enum_name, num_bits)
    let l:current_line_num = line(".")
    let l:out_str_array = []
    let l:msb_num = a:num_bits - 1
    let l:ext = expand("%:e")
    let l:comment_head = Comment_char()
    if l:ext == "sv"
        let l:class_func_names = ["validateEnum", "getThisEnum", "getThisEnumName"]
        let l:return_types = ["bit", a:enum_name, "string"]
        let l:func_comments = ["Check to see if bitValue is a valid " . a:enum_name, "Get " . a:enum_name . " enumerator of bitValue", "Get " . a:enum_name . " enumerator name of bitValue"]
        let l:func_index = 0
        for l:func in ["valid", "get", "get"]
            let l:func_name = l:func . "_" . a:enum_name
            if l:func_index == 2
                let l:func_name = l:func . "_" . a:enum_name . "_name"
            endif
            let l:line = "function " . l:return_types[l:func_index] . " " . l:func_name . "(input logic [" . string(l:msb_num) . ":0] bitValue); "
            let l:line .= l:comment_head . l:func_comments[l:func_index]
            let l:out_str_array = add(l:out_str_array, l:line)
            let l:line = "    validEnum #(.T(" . a:enum_name ."), .numOfBits(" . a:num_bits . ")) regClass;"
            let l:out_str_array = add(l:out_str_array, l:line)
            let l:out_str_array = add(l:out_str_array, "    begin")
            let l:out_str_array = add(l:out_str_array, "        regClass = new();")
            let l:out_str_array = add(l:out_str_array, "        " . l:func_name . " = regClass." . l:class_func_names[l:func_index] ."(bitValue);")
            let l:out_str_array = add(l:out_str_array, "    end")
            let l:out_str_array = add(l:out_str_array, "endfunction " . l:comment_head . l:func_name)
            let l:out_str_array = add(l:out_str_array, "")
            let l:func_index += 1
        endfor
    endif
    execute ":" . l:current_line_num
    let l:out_str_array = add(l:out_str_array, "")
    let l:out_str = join(l:out_str_array, "\n")
    let @z = l:out_str
    put z
    "echo l:out_str
    execute ":" . l:current_line_num
    return l:out_str
endfunction "end of function! Gen_valid_enum

function! Comment_char()
    let l:ext = expand("%:e")
    let l:comment_head = ""
    if l:ext == "vim"
        let l:comment_head = "\""
    elseif l:ext == "il"
        let l:comment_head = ";"
    elseif l:ext == "py" || l:ext == "pl"
        let l:comment_head = "#"
    elseif l:ext == "vams" || l:ext == "v" || l:ext == "sv" || l:ext == "ev"
        let l:comment_head = "//"
    endif
    return l:comment_head
endfunction

"Gen_case(variable name, num of cases, output variable(list), num of pre
"spaces of line, output value array, output value array)
function! Gen_case(case_var, case_num, out_vars, num_space, ...)
    let l:current_line_num = line(".")
    let l:ext = expand("%:e")
    let l:case_array = []
    let l:values_array = []
    if len(a:000) >= 1
        let l:ii = 0
        for l:item in a:000
            echo l:item
            let l:values_array = add(l:values_array, l:item)
            let l:ii += 1
        endfor
    endif
    if l:ext == "vams" || l:ext == "v" || l:ext == "sv" || l:ext == "ev"
        let l:case_array = add(l:case_array, "case(" . a:case_var . ")")
        if a:case_num > 1
            let l:ii = 0
            while l:ii <= a:case_num
                if l:ii < a:case_num
                    let l:case_index = l:ii
                else
                    let l:case_index = "default"
                endif
                if len(a:out_vars) == 1
                    if len(l:values_array) >= 1 && l:ii < len(l:values_array[0])
                        let l:var_value = l:values_array[0][l:ii]
                    else
                        let l:var_value = ""
                    endif
                    "echo l:var_value
                    let l:case_array = add(l:case_array, "    " . l:case_index . " : " . a:out_vars[0] . " = " . l:var_value . ";")
                elseif len(a:out_vars) > 1
                    let l:case_array = add(l:case_array, "    " . l:case_index . " : begin")
                    let l:jj = 0
                    for l:out_var in a:out_vars
                        if len(l:values_array) >= 1 && l:jj < len(l:values_array) && l:ii < len(l:values_array[l:jj])
                            let l:var_value = l:values_array[l:jj][l:ii]
                        else
                            let l:var_value = ""
                        endif
                        let l:case_array = add(l:case_array, "        " . l:out_var . " = " . l:var_value . ";")
                        let l:jj += 1
                    endfor
                    let l:case_array = add(l:case_array, "    end //end case " . l:case_index )
                endif
                let l:ii += 1
            endwhile
        endif
        let l:case_array = add(l:case_array, "endcase //" . a:case_var)
    endif
    let l:case_str = join(Fill_array_space(l:case_array, a:num_space), "\n")
    let @x = l:case_str
    put x
    execute ":" . l:current_line_num
    return l:case_str
endfunction "end of function! Gen_case

"fill the array items with leading spaces
function! Fill_array_space(in_array, num_space)
    let l:current_line_num = line(".")
    let l:spaces = Gen_num_spaces(a:num_space)
    let l:out_array = []
    for l:item in a:in_array
        let l:new_item = l:item
        if match(l:item, "^ *$") < 0
            let l:new_item = l:spaces . l:item
        endif
        let l:out_array = add(l:out_array, l:new_item)
    endfor
    execute ":" . l:current_line_num
    return l:out_array
endfunction "end of function! Fill_array_space

function! Gen_num_spaces(num_space)
    let l:current_line_num = line(".")
    if a:num_space > 0
        let l:spaces = ""
        let l:ii = 0
        while l:ii < a:num_space
            let l:spaces = l:spaces . " "
            let l:ii += 1
        endwhile
    else
        let l:spaces = ""
    endif
    execute ":" . l:current_line_num
    return l:spaces
endfunction "end of function! Gen_num_spaces

"defnition of function Gen_src
function! Gen_src(ams_source_name, inst_source_name, node_name)
    let l:current_line_num = line(".")
    let l:task_name_pres = split("set ramp dis en")
    let l:task_vars = ["newVal", "newVal rampTime", "1'b0", "1'b1"]
    let l:subtask_names = ["set", "ramp", "setEnable", "setEnable"]
    let l:entask_name = "en" . Captalize_first_letter_keep_remaining(a:node_name)
    let l:pretask_names = [l:entask_name, l:entask_name, "", ""]
    let l:task_index = 0
    let l:task_strs = []
    let l:post_set_ramp = ""
    let l:en_loc = match(a:ams_source_name, "_en")
    if  l:en_loc > 0
        let l:ams_en_source = 1
        let l:pre_en_loc = l:en_loc - 1
        let l:true_source = toupper(a:ams_source_name[0 : l:pre_en_loc] . ".")
    else
        let l:ams_en_source = 0
        let l:true_source = ""
    endif
    if match(a:ams_source_name, "vsrc") >= 0
        let l:post_set_ramp = "Volt"
    endif
    if match(a:ams_source_name, "isrc") >= 0
        let l:post_set_ramp = "Current"
    endif
    for l:task_name_pre in l:task_name_pres
        if l:ams_en_source == 0 || l:task_index < 2
            "let l:task_name = l:task_name_pre . "_" . a:node_name
            let l:task_name = l:task_name_pre . "" . Captalize_first_letter_keep_remaining(a:node_name)
            let l:task_def = "task " . l:task_name . ";"
            let l:task_strs = add(l:task_strs, l:task_def)
            let l:task_var_array = split(l:task_vars[l:task_index])
            if len(l:task_var_array) > 0
                for l:task_var in l:task_var_array
                    if match(l:task_var, "^[0-9]") >= 0 || match(l:task_var, "^'") >= 0
                        echo l:task_var
                    else
                        let l:task_strs = add(l:task_strs, "input real " . l:task_var . ";")
                    endif
                endfor
            endif
            let l:task_strs = add(l:task_strs, "begin")
            let l:pretask = l:pretask_names[l:task_index]
            if l:pretask != "" && l:ams_en_source == 0
                let l:task_strs = add(l:task_strs, "    " . l:pretask . ";")
            endif
            if l:task_index >= 2
                let l:post_subtask = ""
            else
                let l:post_subtask = l:post_set_ramp
            endif
            let l:main_task = "    " . a:inst_source_name . "." . l:true_source . l:subtask_names[l:task_index] . l:post_subtask . "(" . join(l:task_var_array, ", ") . ");"
            let l:task_strs = add(l:task_strs, l:main_task)
            let l:task_strs = add(l:task_strs, "end")
            let l:task_strs = add(l:task_strs, "endtask    // " . l:task_name)
            let l:task_strs = add(l:task_strs, "")
        endif
        let l:task_index += 1
    endfor
    let l:task_strs = add(l:task_strs, "")
    let l:put_success = Put_module_end(join(Fill_array_space(l:task_strs, 4), "\n"))
    execute ":" . l:current_line_num
    return join(Fill_array_space(l:task_strs, 4), "\n")
endfunction "end of function! Gen_src

function! Gen_func(func_name, ...)
    let l:current_line_num = line(".")
    let l:ext = expand("%:e")
    let l:this_func_name = a:func_name
    let l:comment_head = Comment_char()
    let l:func_def = ""
    let l:func_params = ""
    let l:func_body = ""
    let l:func_end = ""

    let l:func_pre = ""
    if l:ext == "vim"
        let l:func_pre = l:comment_head . "defnition of function " . a:func_name . "\n"
        let l:func_def =  "function! "
        let l:func_params = "(" . join(a:000, ", ") . ")"
        let l:func_body = "    let l:current_line_num = line(\".\")\n    let l:out_str = \"\"\n    execute \":\" . l:current_line_num\n    let @z = l:out_str\n    return l:out_str"
        let l:this_func_name = toupper(l:this_func_name[0]) . l:this_func_name[1:]
        let l:func_end = "endfunction"
    elseif l:ext == "py"
        let l:func_def = "def "
        let l:func_params = "(" . join(a:000, ", ") . ")"
        let l:func_body = ""
        let l:func_end = "endfunction"
    elseif l:ext == "pl"
        let l:func_def = "sub "
        let l:func_params = "{"
        let l:func_body = ""
        let l:func_end = "}"
    elseif l:ext == "il"
        let l:func_def = "procedure("
        let l:func_params = "(" . join(a:000, ", ") . ")"
        let l:func_body = "    let(()\n    )\n"
        let l:func_end = ")"
    elseif l:ext == "vams" || l:ext == "v" || l:ext == "sv" || l:ext == "ev"
        let l:func_def = "    function "
        let l:func_end = "    endfunction"
        let l:func_params = ";\n    input " . join(a:000, ", ") . ";"
        let l:func_body = "    begin\n    end"
        if len(a:000) >= 1
            if a:1 == 1
                let l:func_def = "    task "
                let l:func_params = ";\n    input " . join(a:000[1:], ", ") . ";"
                let l:func_end = "    endtask"
            endif
        endif
    endif
    let l:func_def_head = l:func_pre . l:func_def . l:this_func_name . l:func_params
    "echo l:func_def_head
    let l:func_def_name = Remove_tr_fl_spaces(l:func_def)
    let l:func_def_name = substitute(l:func_def_name, "(", "", "")
    let l:func_end = l:func_end . " " . l:comment_head . "end of " . l:func_def_name . " " . l:this_func_name
    let l:func_def_all = join([l:func_def_head, l:func_body, l:func_end],"\n")
    let @w = l:func_def_all
    put w
    execute ":" . l:current_line_num
    return l:func_def_all
endfunction

function! Remove_tr_fl_spaces_array(in_array)
    let l:out_array = []
    for l:item in a:in_array
        let l:out_array = add(l:out_array, Remove_tr_fl_spaces(l:item))
    endfor
    return l:out_array
endfunction

function! Remove_tr_fl_zeros(in_str)
    let l:current_line_num = line(".")
    let l:out_str = a:in_str
    let l:out_str = substitute(l:out_str, "^0*", "", "")
    let l:out_str = substitute(l:out_str, "0*$", "", "")
    let l:out_str = substitute(l:out_str, "\\.$", ".0", "")
    execute ":" . l:current_line_num
    return l:out_str
endfunction "end of function!  Remove_tr_fl_spaces

function! Remove_tr_fl_spaces(in_str)
    let l:current_line_num = line(".")
    let l:out_str = a:in_str
    let l:out_str = substitute(l:out_str, "^ *", "", "")
    let l:out_str = substitute(l:out_str, " *$", "", "")
    execute ":" . l:current_line_num
    return l:out_str
endfunction "end of function!  Remove_tr_fl_spaces

"Generate the switch strings
function! Gen_switch_strs(control_sig)
    let l:current_line_num = line(".")
    let l:control_statement = ""
    let l:local_control = substitute(a:control_sig, "\\~", "", "g")
    if  Exist_in_file(l:local_control) == 0 && match(a:control_sig, "\\&") < 0 && match(a:control_sig, "\\|") < 0 && match(a:control_sig, "\\~") < 0
        let l:control_statement = "    reg " . a:control_sig . " = 1'b0;"
        if match(a:control_sig, "regConn") >= 0
            let l:control_task_main = substitute(a:control_sig, "regConn", "", "g")
        else
            let l:control_task_main = a:control_sig
        endif
        let l:tasks = ["conn", "disconn"]
        let l:task_array = []
        let l:reg_value = 1
        for l:task in l:tasks
            "let l:task_name = l:task . "_" . l:control_task_main
            let l:task_name = l:task . "" . Captalize_first_letter_keep_remaining(l:control_task_main)
            let l:task_array = add(l:task_array, "    task " . l:task_name . ";")
            let l:task_array = add(l:task_array, "    begin")
            let l:task_array = add(l:task_array, "        " . a:control_sig . " = 1'b" . l:reg_value . ";")
            let l:task_array = add(l:task_array, "    end")
            let l:task_array = add(l:task_array, "    endtask //" . l:task_name)
            let l:reg_value -= 1
        endfor
        let l:put_success = Put_module_end(join(l:task_array, "\n"))
    endif
    execute ":" . l:current_line_num
    return l:control_statement
endfunction

"defnition of function put_module_end
function! Put_module_end(in_str)
    let l:current_line_num = line(".")
    let @y = a:in_str
    let l:module_end = search("\\<endmodule\\>")
    if l:module_end > 1
        let l:before_module_end = l:module_end - 1
        execute ":" l:before_module_end
        let l:put_success = 1
    else
        execute ":$"
        let l:put_success = 0
    endif
    put y
    execute ":" . l:current_line_num
    return l:put_success
endfunction "end of function! Put_module_end

function! Gen_node_def(node_def, nodes_array)
    if len(a:nodes_array) >= 1
        let l:out_str = "    " . a:node_def . " " . join(a:nodes_array, ", ") . ";\n"
    else
        let l:out_str = ""
    endif
    return l:out_str
endfunction

function! Gen_reg_ctrl(in_nodes, ...)
    let l:real_def_array = []
    let l:absdelta_def_array = []
    for l:in_node in split(a:in_nodes)
        let l:real_var = "v_" . tolower(l:in_node)
        if len(l:node_additional) >= 1
            let l:v_node = "V(" . l:node_additional . "." . l:in_node . ")"
        else
            let l:v_node = "V(" . l:in_node . ")"
        endif
        let l:absdelta_var = "    //voltage value for node " . l:in_node . "\n    always @(absdelta(" . l:v_node . ", 1m, 1u, 0.01m)) " . l:real_var . " = " . l:v_node . ";\n"
        let l:real_def_array = add(l:real_def_array, l:real_var)
        let l:absdelta_def_array = add(l:absdelta_def_array, l:absdelta_var)
    endfor
    let l:real_var = "    real " . join(l:real_def_array, ", ") . ";\n"
    let l:absdelta_var = join(l:absdelta_def_array, "")
    let @x = l:real_var . l:absdelta_var
    put x
endfunction

function! Gen_absdelta(in_nodes, ...)
    let l:real_def_array = []
    let l:absdelta_def_array = []
    if len(a:000) >= 1 && strlen(a:000[0]) >= 1
        let l:node_additional = "`" . a:000[0]
    else
        let l:node_additional = ""
    endif
    for l:in_node in split(a:in_nodes)
        let l:real_var = "v_" . tolower(l:in_node)
        if len(l:node_additional) >= 1
            let l:v_node = "V(" . l:node_additional . "." . l:in_node . ")"
        else
            let l:v_node = "V(" . l:in_node . ")"
        endif
        let l:absdelta_var = "    //voltage value for node " . l:in_node . "\n    always @(absdelta(" . l:v_node . ", 1m, 1u, 0.01m)) " . l:real_var . " = " . l:v_node . ";\n"
        let l:real_def_array = add(l:real_def_array, l:real_var)
        let l:absdelta_def_array = add(l:absdelta_def_array, l:absdelta_var)
    endfor
    let l:real_var = "    real " . join(l:real_def_array, ", ") . ";\n"
    let l:absdelta_var = join(l:absdelta_def_array, "")
    let @x = l:real_var . l:absdelta_var
    put x
endfunction

function! GC(in_nodes)
    call Gen_capacitor(a:in_nodes)
endfunction

function! GL(in_nodes)
    call Gen_inductor(a:in_nodes)
endfunction

function! GR(in_nodes)
    call Gen_resistor(a:in_nodes)
endfunction

function! GS(module_spec, ...)
    let l:my_specs = My_split(a:module_spec)
    let l:ctrl_bit = l:my_specs[len(l:my_specs) - 1]
    let @x = "    reg " . l:ctrl_bit . " = 1'b0;"
    put x
    if a:0 > 0
        call Gen_AMS(a:module_spec, a:000)
    else
        call Gen_AMS(a:module_spec)
    endif
endfunction

function! GA(module_spec,...)
    if a:0 > 0
        call Gen_AMS(a:module_spec, a:000)
    else
        call Gen_AMS(a:module_spec)
    endif
endfunction

function! Gen_capacitor(in_nodes)
    let l:cap_array = split(a:in_nodes)
    let @x = "    //capacitor of value " . l:cap_array[2] . " from ". l:cap_array[0] . " to " . l:cap_array[1] . ".\n"
    put x
    let @x = Gen_node_def("electrical", Filter_str_by_existence(l:cap_array[0:1], 0))
    put x
    let l:cap_array[2] = "c=" . l:cap_array[2]
    call Gen_AMS("capacitor " . join(l:cap_array, " "))
endfunction

function! Gen_inductor(in_nodes)
    let l:ind_array = split(a:in_nodes)
    let @x = "    //inductor of value " . l:ind_array[2] . " from ". l:ind_array[0] . " to " . l:ind_array[1] . ".\n"
    put x
    let @x = Gen_node_def("electrical", Filter_str_by_existence(l:ind_array[0:1], 0))
    put x
    let l:ind_array[2] = "l=" . l:ind_array[2]
    call Gen_AMS("inductor " . join(l:ind_array, " "))
endfunction

function! Gen_resistor(in_nodes)
    let l:res_array = split(a:in_nodes)
    let @x = "    //resistor of value " . l:res_array[2] . " from ". l:res_array[0] . " to " . l:res_array[1] . ".\n"
    put x
    let @x = Gen_node_def("electrical", Filter_str_by_existence(l:res_array[0:1], 0))
    put x
    let l:res_array[2] = "r=" . l:res_array[2]
    call Gen_AMS("resistor " . join(l:res_array, " "))
endfunction

"generate the correction signals for in_nodes
function! Gen_corr(in_nodes)
    for l:in_node in split(a:in_nodes)
        let l:out_node = l:in_node . "_corr"
        let l:in_node_name = l:in_node
        let l:node_range_start = match(l:in_node, "[")
        let l:node_range_end = match(l:in_node, "]")
        let l:xor = ""
        let l:node_range = ""
        if  l:node_range_start >= 0 && l:node_range_end >= 0
            let l:out_node = substitute(l:in_node, "\\[.*\\]", "", "g")
            let l:out_node = substitute(l:out_node, " *$", "", "g")
            let l:in_node_name = l:out_node
            let l:out_node = l:out_node . "_corr"
            let l:node_range = " " . l:in_node[l:node_range_start : l:node_range_end]
            let l:xor = "^"
        endif
        let l:xor_node = l:xor . l:in_node_name
        let @x = "    //correction signals for " . l:in_node . "\n"
        put x
        let @x = "    wire" . l:node_range . " " . l:out_node . " = (" . l:xor_node . " === 1'bx || " . l:xor_node . " === 1'bz) ? 'b0 : " . l:in_node . ";\n"
        put x
    endfor
endfunction

"generate the reg control signals for in_nodes
function! Gen_reg(in_nodes)
    let l:all_out_str = ""
    for l:in_node in split(a:in_nodes)
        let l:out_node = l:in_node . "_reg"
        let l:in_node_name = l:in_node
        let l:node_range_start = match(l:in_node, "[")
        let l:node_range_end = match(l:in_node, "]")
        "echo l:node_range_start
        "echo l:node_range_end
        let l:xor = ""
        let l:node_range = " "
        if l:node_range_start >= 0 && l:node_range_end >= 0
            let l:out_node = substitute(l:in_node, "\\[.*\\]", "", "g")
            let l:out_node = Remove_tr_fl_spaces(l:out_node)
            "echo l:out_node
            let l:in_node_name = l:out_node
            let l:out_node = l:out_node . "_reg"
            let l:node_just_range = l:in_node[l:node_range_start : l:node_range_end]
            let l:range_num_ports = Extract_range_num(l:node_just_range)
            if l:range_num_ports > 1
                let l:node_range = " " . l:node_just_range . " "
            endif
        else
            let l:range_num_ports = 1
        endif
        let l:out_str = ""
        let l:out_str = l:out_str . "    //reg control signals for " . l:in_node_name . "\n"
        let l:out_str = l:out_str . "    reg" . l:node_range . l:out_node . " = " . l:range_num_ports . "'b0;\n"
        let l:out_str = l:out_str . "    assign " . l:in_node_name . " = " . l:out_node . ";\n"
        let @x = l:out_str
        put x
        let l:ctrl_task = Reg_ctrl_task(l:in_node_name, l:range_num_ports)
        let l:put_success = Put_module_end(l:ctrl_task)
        let l:out_str = l:out_str . l:ctrl_task
        let l:all_out_str = l:all_out_str . l:out_str
    endfor
    return l:all_out_str
endfunction

function! Reg_ctrl_task(in_node_name, in_range_num_ports)
    let l:out_str = "    task set_" . a:in_node_name .";\n"
    if a:in_range_num_ports > 1
        let l:node_range = " [" . Convert_num_str_int(a:in_range_num_ports - 1) . ":0] "
    else
        let l:node_range = " "
    endif
    let l:task_name = "set_" . a:in_node_name
    let l:reg_name = a:in_node_name . "_reg"
    let l:out_str = "    task " . l:task_name .";\n"
    let l:out_str = l:out_str . "    input" . l:node_range . "inVal;\n"
    let l:out_str = l:out_str . "    begin\n"
    let l:out_str = l:out_str . "        " . l:reg_name ." = inVal;\n"
    let l:out_str = l:out_str . "    end\n"
    let l:out_str = l:out_str . "    endtask    //". l:task_name ."\n"
    return l:out_str
endfunction

function! Extract_range_num(in_range)
    let l:out_node = substitute(a:in_range, "[", "", "g")
    let l:out_node = substitute(l:out_node, "]", "", "g")
    let l:colum_loc = match(l:out_node, ":")
    if l:colum_loc >= 0
        let l:ranges = split(l:out_node, ":")
        let l:num_ports = Remove_tr_fl_spaces(l:ranges[0]) - Remove_tr_fl_spaces(l:ranges[1])
        if l:num_ports < 0
            let l:num_ports = -l:num_ports
        endif
        let l:num_ports = l:num_ports + 1
    else
        let l:num_ports = 1
    endif
    return l:num_ports
endfunction


"Generate the resistor for current branch
function! Gen_curr_resistor(in_node)
    let l:current_line_num = line(".")
    let l:source_array = Get_vdd_vss()
    let l:supply_str = l:source_array[0] == ""? "vdd" : l:source_array[0]
    let l:ground_str = l:source_array[1] == ""? "vss" : l:source_array[1]
    if match(tolower(a:in_node), "^n") >= 0
        let l:node1 = l:supply_str
        let l:node2 = a:in_node
    elseif match(tolower(a:in_node), "^p") >= 0
        let l:node1 = a:in_node
        let l:node2 = l:ground_str
    else
        let l:node1 = a:in_node
        let l:node2 = l:ground_str
    endif
    let l:node_active = a:in_node . "_active"
    execute ":" . l:current_line_num
    let @y = "    //resistor on ". a:in_node . " such that current will not blow up\n"
    put y
    let @x = Gen_node_def("electrical", Filter_str_by_existence([l:node1, l:node2], 0))
    put x
    let @x = Gen_node_def("wire", Filter_str_by_existence([l:node_active], 0))
    put x
    call Gen_AMS(join(["resistor", l:node1, l:node2, "r=500k"], " "))
    call Gen_AMS(join(["ams_compEn39", l:node1, l:node2, "EN_int", l:node_active, "offset=-0.3"], " "))
endfunction

function! Execute_current_line()
    let l:current_line_num = line(".")
    let l:current_line = getline(".")
    let l:comment_head = Comment_char()
    let l:content = substitute(l:current_line, "^ *" . l:comment_head, "", "")
    let l:call_content = "call " . l:content
    let l:newline = l:comment_head . l:content
    execute l:call_content
    execute ":" . l:current_line_num
    call setline(".", l:newline)
endfunction

"filter the in_array by testing if the items in array exist
function! Filter_str_by_existence(in_array, find_exist)
    let l:current_line_num = line(".")
    let l:out_array = []
    for l:str in a:in_array
        if (Exist_in_file(l:str) == 0 && a:find_exist == 0) || (Exist_in_file(l:str) == 1 && a:find_exist == 1)
            let l:out_array = add(l:out_array, l:str)
        endif
    endfor
    execute ":" . l:current_line_num
    return l:out_array
endfunction

"Does the in_str exists in the file
function! Exist_in_file(in_str)
    let l:current_line_num = line(".")
    execute ":1"
    let l:search_lines = []
    let l:pure_str = substitute(Remove_tr_fl_spaces(a:in_str), " *\\[.*\\]", "", "g")
    let l:full_in_str = "\\<" . l:pure_str . "\\>"
    let l:line_searched = search(l:full_in_str)
    let l:str_exist = 0
    if l:line_searched > 0
        while index(l:search_lines, l:line_searched) < 0
            let l:search_lines = add(l:search_lines, l:line_searched)
            let l:current_line = getline(".")
            if match(l:current_line, "\/\/.*" . l:full_in_str) < 0
                let l:str_exist = 1
            endif
            let l:line_searched = search(l:full_in_str)
        endwhile
    endif
    execute ":" . l:current_line_num
    return l:str_exist
endfunction

"replace the whole file with new_string
function! Replace_whole_file(old_string, new_string)
    let l:current_line_num = line(".")
    if a:old_string != ""
        let l:full_old_string = "\\<" . a:old_string . "\\>"
        while search(l:full_old_string) > 0
            let l:current_line = getline(".")
            let l:new_line = substitute(l:current_line, l:full_old_string, a:new_string, "g")
            call setline(".", l:new_line)
        endwhile
    endif
    execute ":" . l:current_line_num
endfunction

function! Conv_us_camel(in_str)
    let l:out_str = ""
    let l:ii = 0
    let l:is_us = 0
    while l:ii < len(a:in_str)
        let l:char = a:in_str[l:ii]
        if l:char == "_"
            let l:is_us = 1
        else
            if l:is_us == 1
                let l:out_str = l:out_str . toupper(l:char)
            else
                let l:out_str = l:out_str . l:char
            endif
            let l:is_us = 0
        endif
        let l:ii += 1
    endwhile
    return l:out_str
endfunction

"Split the pin to be pin def and param def
function! Split_pin_param(in_array)
    let l:pin_array = []
    let l:param_array = []
    for l:pin in a:in_array
        if match(l:pin, "=") >= 0
            let l:param_array = add(l:param_array, l:pin)
        else
            let l:pin_array = add(l:pin_array, l:pin)
        endif
    endfor
    return [l:pin_array, l:param_array]
endfunction

"Generate the parameter definitions in the module instantiation
function! Gen_param_def(in_array)
    let l:out_param_array = []
    for l:str in a:in_array
        let l:params_array = split(l:str, "=")
        if len(l:params_array) >= 2
            let l:param_str = "." . l:params_array[0] . "(" . l:params_array[1] . ")"
        else
            let l:param_str = l:params_array[0] . "(" . ")"
        endif
        let l:out_param_array = add(l:out_param_array, l:param_str)
    endfor
    if len(l:out_param_array) >= 1 
        let l:param_pond = "#("
        let l:param_full_str = l:param_pond . join(l:out_param_array, ", ") . ") "
    else
        let l:param_full_str = ""
    endif
    return l:param_full_str
endfunction

function! Gen_default_param_str(param_list, param_values_list, in_array)
    if len(a:param_list) != len(a:param_values_list)
        echo "length of params_list and param_values_list are not equal"
    endif
    let l:in_param_value_hash = {}
    for l:str in a:in_array
        let l:params_array = split(l:str, "=")
        if len(l:params_array) >= 2
            let l:in_param_value_hash[l:params_array[0]] = l:params_array[1]
        endif
    endfor
    let l:param_value_pair = []
    let l:param_index = 0
    for l:param in a:param_list
        let l:param_value = a:param_values_list[l:param_index]
        if has_key(l:in_param_value_hash, l:param)
            let l:param_value = l:in_param_value_hash[l:param]
        endif
        let l:param_value_pair = add(l:param_value_pair, l:param . "=" . l:param_value)
        let l:param_index += 1
    endfor
    return Gen_param_def(l:param_value_pair)
endfunction

function! Gen_module_pin_def(module_name, orig_pin_array, pin_spec_array)
    let l:current_line_num = line(".")
    let l:des_pin_array = a:pin_spec_array
    let l:pin_index = 0
    let l:pin_def_array = []
    let l:complete_pin_array = []
    let l:source_array = Get_vdd_vss()
    if len(a:orig_pin_array) >= 1
        for l:orig_pin in a:orig_pin_array
            if len(l:des_pin_array) == 0
                let l:des_pin = ""
            else
                if l:pin_index > len(l:des_pin_array) - 1
                    let l:des_pin = l:orig_pin
                else
                    let l:des_pin = l:des_pin_array[l:pin_index]
                    if l:des_pin == ""
                        let l:des_pin = l:orig_pin
                        let l:supply_str = l:source_array[0]
                        let l:ground_str = l:source_array[1]
                        if l:orig_pin == "p" || match(tolower(l:orig_pin), "vdd") >= 0
                            let l:des_pin = l:supply_str == ""? l:orig_pin : l:supply_str 
                        elseif l:orig_pin == "n" || match(tolower(l:orig_pin), "vss") >= 0
                            let l:des_pin = l:ground_str == ""? l:orig_pin : l:ground_str 
                        endif
                    endif
                endif
            endif
            if a:module_name == "ams_switch" && l:pin_index == len(a:orig_pin_array) - 1 && l:pin_index > len(l:des_pin_array) - 1
                "let l:des_pin = "reg_conn_" . join(l:complete_pin_array, "__")
                let l:des_pin = "regConn" . join(Captalize_first_letter_array(l:complete_pin_array, 1), "")
            endif
            if match(l:des_pin, ",") >= 0
                let l:des_pin = "{" . l:des_pin . "}"
            endif
            if l:orig_pin == ""
                let l:pin_def_array = add(l:pin_def_array, l:des_pin)
            else
                let l:pin_def_array = add(l:pin_def_array,  "." . l:orig_pin . "(" . l:des_pin. ")")
            endif
            let l:complete_pin_array = add(l:complete_pin_array,  l:des_pin)
            let l:pin_index += 1
        endfor
    else
        for l:des_pin in l:des_pin_array
            if match(l:des_pin, ",") >= 0
                let l:des_pin = "{" . l:des_pin . "}"
            endif
            let l:pin_def_array = add(l:pin_def_array, l:des_pin)
            let l:complete_pin_array = add(l:complete_pin_array,  l:des_pin)
            let l:pin_index += 1
        endfor
    endif
    let l:pin_def_pre = "("
    let l:pin_def_str = l:pin_def_pre . join(l:pin_def_array, ", ") . ")"
    return [l:pin_def_str, l:complete_pin_array]
endfunction

function! Gen_ihn(in_str)
    let l:my_ihn = My_split(a:in_str)
    if len(l:my_ihn) == 0
        let l:my_ihn = My_split("powr grnd")
    endif

    "//Global power and ground for digtop signals
    "wire (* integer inh_conn_prop_name = "vdd";integer inh_conn_def_value = "cds_globals.\\vdd! "; *) powr;
    "wire (* integer inh_conn_prop_name = "vss";integer inh_conn_def_value = "cds_globals.\\vss! "; *) grnd;
    let l:ihn_str = printf("    wire (* integer inh_conn_prop_name = \"vdd\";integer inh_conn_def_value = \"cds_globals.\\\\vdd! \"; *) %s;\n", l:my_ihn[0])
    if len(l:my_ihn) >= 2
        let l:ihn_str = printf("%s    wire (* integer inh_conn_prop_name = \"vss\";integer inh_conn_def_value = \"cds_globals.\\\\vss! \"; *) %s;", l:ihn_str, l:my_ihn[1])
    endif
    "let l:ihn_str = printf("%s;", l:ihn_str)
    let @z = l:ihn_str
    put z
    return l:ihn_str
endfunction

function! Gen_ss(in_str)
    let l:my_ss = My_split(a:in_str)
    if len(l:my_ss) == 0
        let l:my_ss = My_split("vddd vssd")
    elseif len(l:my_ss) == 1
        let l:my_ss = add(l:my_ss, "vssd")
    endif
    let l:ss_str = printf("    (* integer supplySensitivity = \"%s\" ; integer groundSensitivity = \"%s\";*)", l:my_ss[0], l:my_ss[1])
    if len(l:my_ss) >= 3
        let l:ss_str = printf("%s %s", l:ss_str, l:my_ss[2])
    endif
    let l:ss_str = printf("%s;", l:ss_str)
    let @z = l:ss_str
    put z
    return l:ss_str
endfunction

function! Get_vdd_vss()
    let l:current_line_num = line(".")
    execute ":1"
    let l:matched_lines = []
    let l:supply_test = 'supplySensitivity = "vddd" ;groundSensitivity = "vsss";'
    let l:line_num = search("supplySensitivity.*groundSensitivity.*")
    if l:line_num <= 0
        execute ":" . l:current_line_num
        return["", ""]
    endif
    let l:current_line = getline(".")
    "while match(l:current_line, "=") < 0
    while index(l:matched_lines, l:line_num) < 0
        let l:matched_lines = add(l:matched_lines, l:line_num)
        let l:current_line = getline(".")
        if match(l:current_line, "=") >= 0 && match(l:current_line, "\\") < 0
            break
        endif
        let l:line_num = search("supplySensitivity.*groundSensitivity.*")
    endwhile
    if match(l:current_line, "=") >= 0 && match(l:current_line, "supplySensitivity.*groundSensitivity.*") >= 0
        let l:supply_str = Extract_vdd_vss(current_line, "supplySensitivity") 
        let l:ground_str = Extract_vdd_vss(current_line, "groundSensitivity") 
    else
        let l:supply_str = ""
        let l:ground_str = ""
    endif
    execute ":" . l:current_line_num
    return [l:supply_str, l:ground_str]
endfunction

function! Extract_vdd_vss(in_str, creteria)
    let l:this_line = a:in_str
    let l:match_index = match(l:this_line, a:creteria) 
    let l:equal_index = match(l:this_line, "=", l:match_index) 
    let l:sc_index = match(l:this_line, ";", l:match_index) 
    if l:match_index >= 0 && l:equal_index >= 0 && l:sc_index >= 0
        let l:supply_str = l:this_line[l:equal_index + 1 : l:sc_index - 1]
        let l:supply_str = substitute(l:supply_str, " ", "", "g")
        let l:supply_str = substitute(l:supply_str, "\"", "", "g")
    else
        let l:supply_str = ""
    endif
    return l:supply_str

endfunction

function! Captalize_first_letter_array(in_array, cap_method)
    let l:out_array = []
    for l:elem in a:in_array
        if (a:cap_method == 0)
            let l:new_elem = Captalize_first_letter(l:elem)
        else
            let l:new_elem = Captalize_first_letter_keep_remaining(l:elem)
        endif
        let l:out_array = add(l:out_array, l:new_elem)
    endfor
    return l:out_array
endfunction

function! Captalize_first_letter_keep_remaining(in_name)
    let l:upper_name = toupper(a:in_name)
    let l:out_name = l:upper_name[0] . a:in_name[1:]
    return l:out_name
endfunction

function! Captalize_first_letter(in_name)
    let l:upper_name = toupper(a:in_name)
    let l:lower_name = tolower(a:in_name)
    let l:out_name = l:upper_name[0] . l:lower_name[1:]
    return l:out_name
endfunction

function! Gen_module_name(pin_name_spec, complete_pin_list, ...)
    if a:0 > 0
        let l:module_name_prename = a:1[0]
    else
        let l:pin_name_specs = split(a:pin_name_spec)
        let l:module_name_prefix = l:pin_name_specs[0] . "_"
        let l:model_name_pins = []
        for l:post_index in l:pin_name_specs[1:]
            let l:model_name_pins = add(l:model_name_pins, Captalize_first_letter_keep_remaining(Re_bracket(a:complete_pin_list[l:post_index])))
        endfor

        let l:module_name_postfixes = join(l:model_name_pins, "__")
        let l:module_name_prename = l:module_name_prefix . "" . l:module_name_postfixes
    endif
    let l:module_name = Re_gen_name(l:module_name_prename)
    return l:module_name
endfunction

function! Re_bracket(in_name)
    let l:out_name = substitute(a:in_name, "[", "_", "g")
    let l:out_name = substitute(l:out_name, "]", "", "g")
    let l:out_name = substitute(l:out_name, "-", "_", "g")
    let l:out_name = substitute(l:out_name, ":", "_", "g")
    return l:out_name
endfunction

function! Re_gen_name(in_name)
    let l:current_line_num = line(".")
    let l:module_name = a:in_name
    let l:module_name_prename = l:module_name
    let l:name_index = 0
    if !(l:module_name == "")
        while search("\\<".l:module_name."\\>") > 0
            let l:name_index = l:name_index + 1
            let l:module_name = l:module_name_prename . "" . l:name_index
        endwhile
    endif
    execute ":" . l:current_line_num
    return l:module_name
endfunction

function! Gen_AMS_Hashes()
    let l:all_modules_hash = {}
    let l:all_modules_hash["ams_bbm"] = ["in out1 out2", "Bbm 0", "tt", "10n"]
    let l:all_modules_hash["ams_capacitor"] = ["p n", "Cap 0", "c ic rout rinit gmin td tchg ttol", "1.0 0.0 1m 1 1e-12 0 1u 10n"]
    let l:all_modules_hash["ams_changedet"] = ["p n chg", "ChangeDet 0", "step tpulse sampl_time", "0.01 100.0n 1n"]
    let l:all_modules_hash["ams_clock"] = ["en clk", "Clock 1", "freq duty trim_accuracy end_delay", "10k 0.5 0.05 2"]
    let l:all_modules_hash["ams_comp"] = ["p n en out", "Comp 3", "offset hyst trdelay tfdelay out_default sampl_time", "0 0 0 0 0 1u"]
    let l:all_modules_hash["ams_compEn"] = ["p n en out", "Comp 3", "offset hyst trdelay tfdelay out_default sampl_time", "0m 1m 10n 10n 0 100n"]
    let l:all_modules_hash["ams_compEn39"] = ["p n en out", "Comp 3", "offset hyst expr_tol time_tol trdelay tfdelay out_default", "0m 1m 1m 1u 10 10 0"]
    let l:all_modules_hash["ams_compEn_supply"] = ["VDD VSS p n en out", "Comp 5", "offset hyst trdelay tfdelay out_default idc trise tfall tdis gmin sampl_time", "0m 1m 10n 10n 0 1u 1u 1u 1u 1e-12 1n"]
    let l:all_modules_hash["ams_compEn_wreal"] = ["p n en out", "Comp 3", "offset hyst trdelay tfdelay out_default", "0m 1m 10n 10n 0"]
    let l:all_modules_hash["ams_comp_3in"] = ["p1 p2 n en out", "Comp 4", "offset trdelay tfdelay out_default sampl_time", "0 0 0 0 1u"]
    let l:all_modules_hash["ams_comp_3in_2n"] = ["p n1 n2 en out", "Comp 4", "offset trdelay tfdelay out_default sampl_time", "0 0 0 0 1u"]
    let l:all_modules_hash["ams_comp_3in_2p"] = ["p1 p2 n en out", "Comp 4", "offset trdelay tfdelay out_default sampl_time", "0 0 0 0 1u"]
    let l:all_modules_hash["ams_comp_new"] = ["p n en out", "Comp 3", "offset hyst trdelay tfdelay out_default sampl_time", "0 0 0 0 0 1u"]
    let l:all_modules_hash["ams_comp_old"] = ["p n en out", "Comp 3", "offset hyst trdelay tfdelay out_default sampl_time", "0 0 0 0 0 1u"]
    let l:all_modules_hash["ams_comp_pwmlog"] = ["p n en out", "Comp 3", "offset hyst trdelay tfdelay out_default sampl_time", "0 0 0 0 0 1u"]
    let l:all_modules_hash["ams_comp_2p_hyst"] = ["prise pfall n en out", "Comp 4", "offset hyst expr_tol time_tol trdelay tfdelay out_default", "0m 1m 1m 1u 10 10 0"]
    let l:all_modules_hash["ams_comp_supply"] = ["VDD VSS p n out", "Comp 4", "offset hyst trdelay tfdelay out_default idc trise tfall tdis gmin sampl_time", "0m 1m 10n 10n 0 1u 1u 1u 1u 1e-12 1n"]
    let l:all_modules_hash["ams_comp_vth"] = ["p n en out out_default", "Comp 3", "rth fth time_tol expr_tol trdelay tfdelay", "0 0 10n 1m 0 0"]
    let l:all_modules_hash["ams_crtrans"] = ["ip in op on", "CRtrans 0", "tau rFilt rout", "100u 1k 0.01"]
    let l:all_modules_hash["ams_crtrans_1"] = ["ip in op on", "CRtrans1 0", "tau rFilt rout", "100u 1k 0.01"]
    let l:all_modules_hash["ams_dac"] = ["refh refl dacin dacout", "Dac 0", "numOfBits Rout Tr steps", "12 0.1 1u 2**(numOfBits)-1"]
    let l:all_modules_hash["ams_debounce"] = ["in out", "DB 0", "updebounce downdebounce", "500n 500n"]
    let l:all_modules_hash["ams_delays"] = ["in en out", "DLY 2", "updelay downdelay defaultdelay hi_z", "500n 500n 500n 1'b1"]
    let l:all_modules_hash["ams_diode"] = ["p n", "Diode 0", "rcont is gmin", "0.01 1e-12 1e-12"]
    let l:all_modules_hash["ams_icomp"] = ["p1 n1 p2 n2 out", "Icomp 4", "offset hyst trdelay tfdelay out_default sampl_time", "0m 0.1u 10n 10n 0 1n"]
    let l:all_modules_hash["ams_isrc"] = ["p n", "Isrc 0", "dc di vcomp vclamp tchg tdis ttol gmin startEnabled", "1u 1m 200m 5.0 1u 1u 10n 1e-12 1"]
    let l:all_modules_hash["ams_isrc_en"] = ["p n en", "IsrcEn 0", "dc di vcomp vclamp tchg tdis ttol gmin startEnabled", "1u 1n 20 0m 5 1n 1n 1n 1e-12 1"]
    let l:all_modules_hash["ams_isrc_r"] = ["p n", "IsrcR 0", "dc di vcomp vclamp tchg tdis ttol gmin startEnabled", "1u 1m 200m 5.0 1u 1u 10n 1e-12 1"]
    let l:all_modules_hash["ams_isrc_supply"] = ["p n vdd vss", "IsrcSupply 0", "dc di vcomp vclamp tchg tdis ttol gmin startEnabled", "1u 1n 200m 5 1u 1u 10n 1e-12 1"]
    let l:all_modules_hash["ams_isrc_supply_en"] = ["p n vdd vss en", "IsrcSupplyEn 0", "dc di vcomp vclamp tchg tdis ttol gmin startEnabled", "1u 1n 200m 5 1n 1n 1n 1e-12 1"]
    let l:all_modules_hash["ams_latch"] = ["q qb rb sb", "LATCH 0", "", ""]
    let l:all_modules_hash["ams_ldo"] = ["vsupply vout en vss", "LDO 1", "drop LDO_bias LDO_out rout tchg tdis ttol gmin", "0.2 5u 4.0 1m 1u 1u 10n 1e-12"]
    let l:all_modules_hash["ams_ldo_var"] = ["vsupply vout en out_sel vss", "LDOVar 0", "drop LDO_bias LDO_out LDO_out2 rout tchg tdis ttol gmin", "0.2 5u 4.0 4.0 1m 1u 1u 10n 1e-12"]
    let l:all_modules_hash["ams_ldo_9238"] = ["vsupply vout en vss", "LDO9238 1", "drop LDO_out rout tchg tdis ttol gmin", "0.2 4.0 1m 1u 1u 10n 1e-12"]
    let l:all_modules_hash["ams_mux"] = ["VDD VSS IN SEL EN VOUT", "Mux 5", "numOfSELs tdis ron roff dropVoltage", "3 1n 10m 100G 0"]
    let l:all_modules_hash["ams_amux"] = ["VDD VSS IN SEL EN VOUT", "Amux 5", "numOfSELs tdis ron roff", "3 1n 10m 100G"]
    let l:all_modules_hash["ams_dmux"] = ["VDD VSS IN SEL EN VOUT", "Dmux 5", "numOfSELs tdis ron roff dropVoltage", "3 1n 10m 100G 0"]
    let l:all_modules_hash["ams_nmos"] = ["d g s", "Nmos 1", "gm vsat vth roff imax", "1e-3 100e-3 0.7 1e9 1.0"]
    let l:all_modules_hash["ams_opamp"] = ["p n vdd vss out en", "OpAmp 0", "dcgain gbw rout", "1e4 100e3 100"]
    let l:all_modules_hash["ams_openDrain"] = ["in out vss", "OpenDrain 0", "vth ron roff gmin sampl_time hyst tchg", "1.0 10 10e6 1e-12 1n 1m 100n"]
    let l:all_modules_hash["ams_pmos"] = ["d g s", "PMOS 1", "gm vsat roff imax", "1e-3 100e-3 1e9 1.0"]
    let l:all_modules_hash["ams_pmos_Si7655DN"] = ["d g s", "Pmos 1", "k vt gmin imax imin rd isd", "48e-6 1.0 1e-12 25e-6 -25e-6 25e-3 9.36e-13"]
    let l:all_modules_hash["ams_rctrans"] = ["ip in op on", "RCTrans 0", "tau rFilt rout", "100u 1k 0.01"]
    let l:all_modules_hash["ams_rctrans_1"] = ["ip in op on", "RCTrans1 0", "tau rFilt rout", "100u 1k 0.01"]
    let l:all_modules_hash["ams_switch"] = ["a b on", "SW 0 1", "tt ttol ron roff", "10n 1n 1m 1T"]
    let l:all_modules_hash["ams_switch_d"] = ["a b on vd", "SWd 0 1", "V_VD tt ttol ron roff", "0.7 10n 1n 1m 1T"]
    let l:all_modules_hash["ams_vcap"] = ["p n", "Vcap 0", "dc dcap tchg tdis gmin startEnabled capName", "1e-6 1e-9 1u 1u 1e-12 1 \"VCAP\""]
    let l:all_modules_hash["ams_vcap_set"] = ["p n", "VcapSet 0", "c ic dcap tdis startEnabled capName rout rinit gmin td tchg ttol", "1.0 0.0 1e-9 1u 1 \"VCAP\" 1m 1 1e-12 0 1u 10n"]
    let l:all_modules_hash["ams_vccs"] = ["vip vin iop ion", "Vccs 2", "gm vcomp voff tdis ttol gmin imax tau startEnabled", "1m 100m 0 1u 10n 1e-12 10u 100u 0"]
    let l:all_modules_hash["ams_vccs_en"] = ["vip vin iop ion en", "VccsEn 0", "gm vcomp voff tdis ttol gmin imax tau startEnabled", "1m 100m 0 1u 10n 1e-12 10u 100u 0"]
    let l:all_modules_hash["ams_vclamp"] = ["p n", "Vclamp 0", "rclamp vclamp gmin", "1m 100m 1e-12"]
    let l:all_modules_hash["ams_vcvs"] = ["vip vin vop von", "Vcvs 2", "initial_gain voff tdis ttol gmin vmax vmin tau ron roff startEnabled", "1 0 1u 10n 1e-12 100 0 100u 10 10M 1"]
    let l:all_modules_hash["ams_vcvs_en"] = ["vip vin vop von en", "VcvsEn 2", "initial_gain voff tdis ttol gmin vmax vmin tau ron roff startEnabled", "1 0 1u 10n 1e-12 100 0 100u 10 10M 1"]
    let l:all_modules_hash["ams_vres"] = ["p n", "Vres 0", "dc dr tchg tdis gmin startEnabled resName", "100e6 10 1u 1u 1e-12 1 \"resistor\""]
    let l:all_modules_hash["ams_vsrc"] = ["p n", "Vsrc 0", "dc dv rout ron roff tchg tdis ttol gmin startEnabled", "0 0.5 1m rout 1G 1u 1u 10n 1e-12 0"]
    let l:all_modules_hash["nvt_isrc"] = ["p n en", "isrc_ 0 1", "idc vmin tr tf ron gmin nstep", "0.0 0.2 100n 100n 10 1e-12 10"]
    let l:all_modules_hash["nvt_ldol"] = ["vin p n en", "ldol_ 1", "imax vdrop vldo_out vldo_disout rnil tr tf ron roff roff_dis nstep", "1 0.2 3.0 0.0 1e-9 100n 100n 1m 10e6 10e6 10"]
    let l:all_modules_hash["nvt_swth"] = ["p n en", "switch_ 0 1", "tr tf ron roff gmin nstep", "100n 100n 1m 10e6 1e-12 10"]
    let l:all_modules_hash["nvt_vcap"] = ["p n", "vcap_ 0", "cdc tr tf gmin nstep", "100e-6 100n 100n 1e-12 50"]
    let l:all_modules_hash["nvt_vdcl"] = ["p n en", "vdcl_ 0", "imax vdd rnil tr tf ron roff nstep", "1 0.0 1e-9 100n 100n 1m 10e6 10"]
    let l:all_modules_hash["nvt_vres"] = ["p n", "vres_ 0 1", "rdc tr tf gmin nstep", "1e6 100n 100n 1e-12 50"]
    let l:all_modules_hash["nvt_vsrc"] = ["p n en", "vsrc_ 0", "vdc tr tf ron roff nstep", "0.0 100n 100n 1m 10e6 10"]
    let l:all_modules_hash["nvt_comp"] = ["p n en out", "comp_ 3", "offset hyst dis_val hyst_dir", "0.0 0.0 0 0"]
    let l:all_modules_hash["nvt_vchk"] = ["p n vg", "vchk_ 2", "exp_val accuracy", "0.5 0.1*exp_val"]
    let l:all_modules_hash["nvt_ichk"] = ["p n ig", "ichk_ 2", "exp_val rval accuracy", "1e-6 200k 0.1*exp_val"]
    let l:all_modules_hash["nvt_osci"] = ["en out", "osc 1", "def_freq def_duty", "1e6 0.5"]
    let l:all_modules_hash["nvt_vbat"] = ["vbat vss", "vbat 0", "", ""]
    let l:all_modules_hash["divider_trim"] = ["vin en trim vout1 vout2", "divider_ 0", "rtop rbot rout rtrim_base off_value", "331.767e3 35.2502e3 165.883e3 2.07354e3 0"]
    let l:all_modules_hash["nvt_sv_comp_hyst_2n"] = ["p n1 n2 en out", "comp_2n_ 4", "offset dis_val", "0.0 0"]
    let l:all_modules_hash["nvt_sv_comp_hyst_2p"] = ["p1 p2 n en out", "comp_2p_ 4", "offset dis_val", "0.0 0"]
    let l:all_modules_hash["nvt_sv_mux"] = ["in sel en out", "mux 3", "NUM_BITS", "3"]
    let l:all_modules_hash["nvt_sv_src"] = ["out en", "src 0", "dc tr tf nstep", "0.0 100e-9 100e-9 10"]
    let l:all_modules_hash["nvt_rtxp"] = ["vrect vss en", "vrect_ 0", "Lp Cp Rp Ls Cs Rs kini vin_tx_ini tx_freq ron roff vrect_min vrect_max", "13u 247n 200m 4.5u 1200n 200m 0 20 130e3 20e-3 20e6 1e-3 30"]
    let l:all_modules_hash["nvt_amux"] = ["in out en sel", "amux_ 1", "NUM_BITS ron roff", "3 1m 10e6"]
    let l:all_modules_hash["nvt_amux_all"] = ["in out en sel", "amux_all_ 1", "NUM_IN ron roff", "5 1m 10e6"]
    let l:all_modules_hash["nvt_mull"] = ["in1 in2 out1 out2", "mull_ 2 3", "l1 l2 k", "7e-6 7e-6 0.0"]
    let l:all_modules_hash["ams_vsrc_en"] = ["p n en", "VsrcEn 0", "dc dv rout ron roff tchg tdis ttol gmin startEnabled", "0 0.5 1m rout 1G 1u 1u 10n 1e-12 0"]
    let l:all_modules_hash["ams_vsrc_new"] = ["p n", "VsrcNew 0", "dc dv rout tchg tdis ttol gmin startEnabled", "0 0.5 1m 1u 1u 10n 1e-12 0"]
    let l:all_modules_hash["I2CDrive"] = ["scl sda osda vhost vss", "I2CDrive", "R_SDA_UP R_SDA_DN R_SCL_UP R_SCL_DN C_SDA C_SCL", "2000 200 2000 200 1p 1p"]
    let l:all_modules_hash["BatteryModel"] = ["battery batgone vss", "Battery 0", "BATTERY_CAPACITANCE BATTERY_RINIT R_VBAT_VALUE BATTERY_ALIVE_THRESHOLD", "0.1 10m 100m 4"]
    let l:all_modules_hash["PwmTriStateModel"] = ["pwm triState", "PwmTriState", "PWM_FREQUENCY PWM_DUTY", "1e6 0.2"]
    let l:all_modules_hash["AdapterModel"] = ["adapter vss", "Adapter", "ADAPTER_CAPACITANCE ADAPTER_CAPACITANCE2 ADAPTER_RINIT ADAPTER_RINIT2 R_VADP_VALUE ADAPTER_ALIVE_THRESHOLD", "0.1 0.1 10m 10m 100m 4"]
    let l:all_modules_hash["SystemModel"] = ["system vss", "System 0", "SYSTEM_CAPACITANCE SYSTEM_CAPACITANCE2 SYSTEM_RINIT SYSTEM_RINIT2 R_VSYS_VALUE SYSTEM_ALIVE_THRESHOLD", "0.1 0.1 10m 10m 100m 4"]
    let l:all_modules_hash["VddModel"] = ["vdd vbat vsys adp vss", "Vdd 0", "VDD_VALUE", "5.0"]
    let l:all_modules_hash["ams_zener"] = ["p n", "Zener 0", "Vreverse Vforward r is m gmin", "6.5 0.65 0.1 1e-12 1 1e-12"]
    let l:all_modules_hash["chk_current_abs"] = ["plus minus en error", "ChkCurrentAbs 0", "minval maxval name rsense tstart tdelay tfilt sampl_time", "1u 3u \"NONAME\" 1k 10n 0n 10n 1n"]
    let l:all_modules_hash["chk_freq_abs"] = ["clk en error", "ChkFreqAbs 0", "minval maxval name tstart tdelay tfilt", "20e6 30e6 \"NONAME\" 10n 0n 10n"]
    let l:all_modules_hash["chk_tracking"] = ["node ref en error", "ChkTracking 0", "tol hyst", "50m 1u"]
    let l:all_modules_hash["chk_volt_abs"] = ["plus minus en error", "CHkVoltAbs 0", "minval maxval tstart tdelay tfilt sampl_time ", "100m 500m 10n 0n 10n 1n"]
    let l:all_modules_hash["lo_gate_drive_simple"] = ["en on VDDP VSSP LG", "LoGateDriveSimple 0", "", ""]
    let l:all_modules_hash["meas_ClkFreq"] = ["clk", "MeasClkfreq 0", "meas_cycles", "10"]
    let l:all_modules_hash["meas_counter"] = ["iEn oCounter oDone", "Meas_counter 0", "numOfBits MAXvALUE MIN_VALUE PERIOD", "12 2^(numOfBits)-1 0 1u"]
    let l:all_modules_hash["nmos30mOhm100nC"] = ["d g s", "Nmos 1", "", ""]
    let l:all_modules_hash["pmos4mOhm25nC"] = ["d g s", "Pmos 1", "", ""]
    let l:all_modules_hash["up_gate_drive_simple"] = ["en on BOOT PH FLTSUP UG", "UpGateDriveSimple 0", "", ""]
    let l:all_modules_hash["resistor"] = ["", "R 0 1", "r", "0"]
    let l:all_modules_hash["inductor"] = ["", "L 0 1", "l", "0"]
    let l:all_modules_hash["capacitor"] = ["", "C 0 1", "c", "1u"]
    let l:all_modules_hash["ams_iprobe"] = ["p n", "Iprobe 0 1", "", ""]
    let l:all_modules_hash["ams_chk_freq"] = ["clk en error", "ChkFreq 0", "minval maxval name tstart tdelay tfilt", "20e6 30e6 \"NONAME\" 10n 0n 10n"]
    let l:all_modules_hash["ams_chk_tracking"] = ["node ref en error", "ChkTracking 0", "tol hyst", "50m 1u"]
    let l:all_modules_hash["ams_chk_volt"] = ["plus minus en error", "ChkVolt 0", "minval maxval name tstart tdelay tfilt sampl_time", "100m 500m \"NONAME\" 10n 0n 10n 1u"]
    let l:all_modules_hash["ams_chk_current"] = ["plus minus en error", "ChkCurrent 0", "minval maxval rsense tstart tdelay tfilt sampl_time", "1u 3u 1k 10n 1u 10n 1u"]
    let l:all_modules_num_hash = {}
    let l:all_modules_num_hash["1"] = "ams_bbm"
    let l:all_modules_num_hash["2"] = "ams_capacitor"
    let l:all_modules_num_hash["3"] = "ams_changedet"
    let l:all_modules_num_hash["4"] = "ams_clock"
    let l:all_modules_num_hash["5"] = "ams_comp"
    let l:all_modules_num_hash["6"] = "ams_compEn"
    let l:all_modules_num_hash["7"] = "ams_compEn39"
    let l:all_modules_num_hash["8"] = "ams_compEn_supply"
    let l:all_modules_num_hash["9"] = "ams_compEn_wreal"
    let l:all_modules_num_hash["10"] = "ams_comp_3in"
    let l:all_modules_num_hash["11"] = "ams_comp_3in_2n"
    let l:all_modules_num_hash["12"] = "ams_comp_3in_2p"
    let l:all_modules_num_hash["13"] = "ams_comp_new"
    let l:all_modules_num_hash["14"] = "ams_comp_old"
    let l:all_modules_num_hash["15"] = "ams_comp_pwmlog"
    let l:all_modules_num_hash["16"] = "ams_comp_supply"
    let l:all_modules_num_hash["17"] = "ams_comp_vth"
    let l:all_modules_num_hash["18"] = "ams_crtrans"
    let l:all_modules_num_hash["19"] = "ams_crtrans_1"
    let l:all_modules_num_hash["20"] = "ams_dac"
    let l:all_modules_num_hash["21"] = "ams_debounce"
    let l:all_modules_num_hash["22"] = "ams_diode"
    let l:all_modules_num_hash["23"] = "ams_icomp"
    let l:all_modules_num_hash["24"] = "ams_isrc"
    let l:all_modules_num_hash["25"] = "ams_isrc_en"
    let l:all_modules_num_hash["26"] = "ams_isrc_r"
    let l:all_modules_num_hash["27"] = "ams_isrc_supply"
    let l:all_modules_num_hash["28"] = "ams_isrc_supply_en"
    let l:all_modules_num_hash["29"] = "ams_latch"
    let l:all_modules_num_hash["30"] = "ams_ldo"
    let l:all_modules_num_hash["31"] = "ams_ldo_9238"
    let l:all_modules_num_hash["32"] = "ams_mux"
    let l:all_modules_num_hash["33"] = "ams_nmos"
    let l:all_modules_num_hash["34"] = "ams_opamp"
    let l:all_modules_num_hash["35"] = "ams_openDrain"
    let l:all_modules_num_hash["36"] = "ams_pmos"
    let l:all_modules_num_hash["37"] = "ams_pmos_Si7655DN"
    let l:all_modules_num_hash["38"] = "ams_rctrans"
    let l:all_modules_num_hash["39"] = "ams_rctrans_1"
    let l:all_modules_num_hash["40"] = "ams_switch"
    let l:all_modules_num_hash["41"] = "ams_switch_d"
    let l:all_modules_num_hash["42"] = "ams_vcap"
    let l:all_modules_num_hash["43"] = "ams_vcap_set"
    let l:all_modules_num_hash["44"] = "ams_vccs"
    let l:all_modules_num_hash["45"] = "ams_vccs_en"
    let l:all_modules_num_hash["46"] = "ams_vclamp"
    let l:all_modules_num_hash["47"] = "ams_vcvs"
    let l:all_modules_num_hash["48"] = "ams_vcvs_en"
    let l:all_modules_num_hash["49"] = "ams_vres"
    let l:all_modules_num_hash["50"] = "ams_vsrc"
    let l:all_modules_num_hash["51"] = "ams_vsrc_en"
    let l:all_modules_num_hash["52"] = "ams_vsrc_new"
    let l:all_modules_num_hash["53"] = "ams_zener"
    let l:all_modules_num_hash["54"] = "chk_current_abs"
    let l:all_modules_num_hash["55"] = "chk_freq_abs"
    let l:all_modules_num_hash["56"] = "chk_tracking"
    let l:all_modules_num_hash["57"] = "chk_volt_abs"
    let l:all_modules_num_hash["58"] = "lo_gate_drive_simple"
    let l:all_modules_num_hash["59"] = "meas_ClkFreq"
    let l:all_modules_num_hash["60"] = "meas_counter"
    let l:all_modules_num_hash["61"] = "nmos30mOhm100nC"
    let l:all_modules_num_hash["62"] = "pmos4mOhm25nC"
    let l:all_modules_num_hash["63"] = "up_gate_drive_simple"
    let l:all_modules_num_hash["64"] = "ams_amux"
    let l:all_modules_num_hash["65"] = "ams_dmux"
    let l:all_modules_num_hash["66"] = "ams_chk_freq"
    let l:all_modules_num_hash["67"] = "ams_chk_tracking"
    let l:all_modules_num_hash["68"] = "ams_chk_volt"
    let l:all_modules_num_hash["69"] = "ams_chk_current"
    let l:all_modules_num_hash["70"] = "ams_comp_2p_hyst"
    let l:all_modules_num_hash["71"] = "ams_delays"
    let l:all_modules_def_num_hash = {}
    let l:all_modules_def_num_hash["ams_bbm"] = 1
    let l:all_modules_def_num_hash["ams_capacitor"] = 2
    let l:all_modules_def_num_hash["ams_changedet"] = 3
    let l:all_modules_def_num_hash["ams_clock"] = 4
    let l:all_modules_def_num_hash["ams_comp"] = 5
    let l:all_modules_def_num_hash["ams_compEn"] = 6
    let l:all_modules_def_num_hash["ams_compEn39"] = 7
    let l:all_modules_def_num_hash["ams_compEn_supply"] = 8
    let l:all_modules_def_num_hash["ams_compEn_wreal"] = 9
    let l:all_modules_def_num_hash["ams_comp_3in"] = 10
    let l:all_modules_def_num_hash["ams_comp_3in_2n"] = 11
    let l:all_modules_def_num_hash["ams_comp_3in_2p"] = 12
    let l:all_modules_def_num_hash["ams_comp_new"] = 13
    let l:all_modules_def_num_hash["ams_comp_old"] = 14
    let l:all_modules_def_num_hash["ams_comp_pwmlog"] = 15
    let l:all_modules_def_num_hash["ams_comp_supply"] = 16
    let l:all_modules_def_num_hash["ams_comp_vth"] = 17
    let l:all_modules_def_num_hash["ams_crtrans"] = 18
    let l:all_modules_def_num_hash["ams_crtrans_1"] = 19
    let l:all_modules_def_num_hash["ams_dac"] = 20
    let l:all_modules_def_num_hash["ams_debounce"] = 21
    let l:all_modules_def_num_hash["ams_diode"] = 22
    let l:all_modules_def_num_hash["ams_icomp"] = 23
    let l:all_modules_def_num_hash["ams_isrc"] = 24
    let l:all_modules_def_num_hash["ams_isrc_en"] = 25
    let l:all_modules_def_num_hash["ams_isrc_r"] = 26
    let l:all_modules_def_num_hash["ams_isrc_supply"] = 27
    let l:all_modules_def_num_hash["ams_isrc_supply_en"] = 28
    let l:all_modules_def_num_hash["ams_latch"] = 29
    let l:all_modules_def_num_hash["ams_ldo"] = 30
    let l:all_modules_def_num_hash["ams_ldo_9238"] = 31
    let l:all_modules_def_num_hash["ams_mux"] = 32
    let l:all_modules_def_num_hash["ams_nmos"] = 33
    let l:all_modules_def_num_hash["ams_opamp"] = 34
    let l:all_modules_def_num_hash["ams_openDrain"] = 35
    let l:all_modules_def_num_hash["ams_pmos"] = 36
    let l:all_modules_def_num_hash["ams_pmos_Si7655DN"] = 37
    let l:all_modules_def_num_hash["ams_rctrans"] = 38
    let l:all_modules_def_num_hash["ams_rctrans_1"] = 39
    let l:all_modules_def_num_hash["ams_switch"] = 40
    let l:all_modules_def_num_hash["ams_switch_d"] = 41
    let l:all_modules_def_num_hash["ams_vcap"] = 42
    let l:all_modules_def_num_hash["ams_vcap_set"] = 43
    let l:all_modules_def_num_hash["ams_vccs"] = 44
    let l:all_modules_def_num_hash["ams_vccs_en"] = 45
    let l:all_modules_def_num_hash["ams_vclamp"] = 46
    let l:all_modules_def_num_hash["ams_vcvs"] = 47
    let l:all_modules_def_num_hash["ams_vcvs_en"] = 48
    let l:all_modules_def_num_hash["ams_vres"] = 49
    let l:all_modules_def_num_hash["ams_vsrc"] = 50
    let l:all_modules_def_num_hash["ams_vsrc_en"] = 51
    let l:all_modules_def_num_hash["ams_vsrc_new"] = 52
    let l:all_modules_def_num_hash["ams_zener"] = 53
    let l:all_modules_def_num_hash["chk_current_abs"] = 54
    let l:all_modules_def_num_hash["chk_freq_abs"] = 55
    let l:all_modules_def_num_hash["chk_tracking"] = 56
    let l:all_modules_def_num_hash["chk_volt_abs"] = 57
    let l:all_modules_def_num_hash["lo_gate_drive_simple"] = 58
    let l:all_modules_def_num_hash["meas_ClkFreq"] = 59
    let l:all_modules_def_num_hash["meas_counter"] = 60
    let l:all_modules_def_num_hash["nmos30mOhm100nC"] = 61
    let l:all_modules_def_num_hash["pmos4mOhm25nC"] = 62
    let l:all_modules_def_num_hash["up_gate_drive_simple"] = 63
    let l:all_modules_def_num_hash["ams_amux"] = 64
    let l:all_modules_def_num_hash["ams_dmux"] = 65
    let l:all_modules_def_num_hash["ams_chk_freq"] = 66
    let l:all_modules_def_num_hash["ams_chk_tracking"] = 67
    let l:all_modules_def_num_hash["ams_chk_volt"] = 68
    let l:all_modules_def_num_hash["ams_chk_current"] = 69
    let l:all_modules_def_num_hash["ams_comp_2p_hyst"] = "70"
    let l:all_modules_def_num_hash["ams_delays"] = "71"
    return [l:all_modules_hash, l:all_modules_num_hash, l:all_modules_def_num_hash]
endfunction

:nnoremap <C-K> :call Execute_current_line()<CR>2j
:inoremap <C-K> <esc>:call Execute_current_line()<CR>2jo

function! MkExpr(fname)
  let l:cname = a:fname
  let l:cname = substitute(l:cname, '\.\/', '', 'g')
  if l:cname =~? '\$(\(.*\))'
    let l:cname = substitute(l:cname, '\$(\(.*\))', '${\1}', 'g')
  endif
  let l:cname = substitute(l:cname, '^(', '', 'g')
  let l:cname = substitute(l:cname, ')$', '', 'g')
  let l:cname = substitute(l:cname, '(.*', '', 'g')
  return l:cname
endfunction

set includeexpr=MkExpr(v:fname)
