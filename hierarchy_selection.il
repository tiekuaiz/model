convergence_func = "1. Convergence Analysis"
warning_func = "2. Warnings"
connect_rule_func = "3. Connect Rule Nodes"
assertion_func = "4. Assertion Analysis"
uvm_info_func = "5. UVM Information"
sigs_rev_dict = makeTable("Signals reverse dict")
path_dict = makeTable("Path to parsed path dictory")

func_list = list(convergence_func warning_func connect_rule_func assertion_func uvm_info_func)
all_dicts_table = makeTable("All dicts for the tables")

procedure(create_hierchary_filter_form()
    let((log_file_field libName cellName viewName filter_function_field run_button filter_type_field net_selection_field information_field fields_list xoffset yoffset xspace yspace)
        log_file_field = hiCreateFileSelectorField(
            ?name 'log_file_field
            ?mode 'existingFile
            ?prompt "Log File"
            ?callback "extract_log_info()"
        )
        libName = hiCreateStringField(
            ?name 'libName
            ?prompt "Library Name"
        )
        cellName = hiCreateStringField(
            ?name 'cellName
            ?prompt "Cell Name"
        )
        viewName = hiCreateStringField(
            ?name 'viewName
            ?prompt "View Name"
        )
        filter_function_field = hiCreateCyclicField(
            ?name       'filter_function_field
            ?prompt     "Select function"
            ?choices    func_list
            ?value      convergence_func
            ?defValue   convergence_func
            ?callback   "update_filter_type_field()"
        )
        ;PointField = hiCreatePointField(
        ;    ?name    'PointField
        ;    ?prompt    "Point"
        ;    ?value    124:255
        ;    ?defValue    124:255
        ;)
        ;ListField = hiCreateListField(
        ;    ?name    'ListField
        ;    ?prompt    "List"
        ;    ?value    list( 1 2 "three" "four" 4.999764 )
        ;    ?defValue    list( 1 2 "three" "four" 4.999764 )
        ;)
        ;MlTextField = hiCreateMLTextField(
        ;    ?name    'MlTextField
        ;    ?prompt    "ML Text"
        ;    ?value    "The quick brown fox jumped\nover the lazy yellow dog."
        ;    ?defValue    "The quick brown fox jumped\nover the lazy yellow dog."
        ;    ?enableWordWrap t
        ;)
        run_button = hiCreateButton(
            ?name 'run_button
            ?buttonText "Run"
            ;?callback "run_func()"
            ?callback "parse_log()"
        )
        filter_type_field = hiCreateListBoxField(
            ?name    'filter_type_field
            ?prompt    "Filter Type"
            ?choices    list()
            ;?value    list( 1 3 4 "football" )
            ;?value    list(1)
            ?callback "update_selection_field()"
            ;?changeCB "navigate_to_path()"
            ?numRows  3
            ?multipleSelect nil
            ?keepHistory nil
        )
        net_selection_field = hiCreateListBoxField(
            ?name    'net_selection_field
            ?prompt    "Select the net"
            ?choices    list(" ")
            ;?value    list( 1 3 4 "football" )
            ?CBOnReselect "navigate_to_path()"
            ?doubleClickCB "navigate_to_path()"
            ?callback "navigate_to_path()"
            ?value    list(1)
            ?numRows  3
            ?multipleSelect nil
            ?keepHistory t
        )
        information_field = hiCreateMLTextField(
            ?name    'information_field
            ?prompt    "Detailed information"
            ;?choices    list(" ")
            ;?value    list( 1 3 4 "football" )
            ;?CBOnReselect "navigate_to_path()"
            ;?doubleClickCB "navigate_to_path()"
            ?value    ""
            ;?numRows  3
            ;?multipleSelect nil
            ?enableWordWrap t
            ;?keepHistory t
        )
        fields_list = list()
        xoffset = 0
        yoffset = 0
        xspace = 300
        yspace = 50
        fields_list = append1(fields_list list(log_file_field 0:0 950:50 100))
        yoffset = yoffset + yspace
        foreach(field list(libName cellName viewName)
            fields_list = append1(fields_list list(field xoffset:yoffset 300:30 100))
            xoffset = xoffset + xspace
        )
        xoffset = 0
        yoffset = yoffset + yspace
        fields_list = append1(fields_list list(filter_function_field xoffset:yoffset 450:50 150))
        xoffset += 500
        fields_list = append1(fields_list list(run_button xoffset:yoffset 100:25))
        xoffset = 0
        yoffset = yoffset + yspace
        yspace = 300
        fields_list = append1(fields_list list(filter_type_field xoffset:yoffset 350:yspace 80))
        ;x, y , width, height, offset
        fields_list = append1(fields_list list(net_selection_field xoffset+350:yoffset 800:yspace 90))
        xoffset = 0
        yoffset = yoffset + yspace
        fields_list = append1(fields_list list(information_field xoffset:yoffset 1150:200 150))
        hiCreateAppForm(
            ?name 'filter_form
            ?formTitle "Filter to see the instance"
            ?fields fields_list
            ?minSize 1150:800
        )
        filter_form
    )
)

procedure(clear_all_tables()
    let(()
        sigs_rev_dict = makeTable("Signals dict")
        path_dict = makeTable("Path to parsed path dictory")
        all_dicts_table = makeTable("All dicts for the tables")
        foreach(func func_list
            all_dicts_table[func] = makeTable(func)
        )
    )
)

procedure(assign_dicts(key_list dicts_list dicts_table)
    let((nn ii)
        nn = length(key_list)
        ii = 0
        while(ii < nn
            ii += 1
            dicts_table[nthelem(ii, key_list)] = nthelem(ii, dicts_list)
        )
    )
)
procedure(extract_log_info()
    let((log_file)
        log_file = filter_form~>log_file_field~>value
        clear_all_tables()
        blank_cell_values()
        blank_selections()
        if(isFile(log_file) then
            fill_cell_values()
            parse_log()
        else
            printf("%s is not a valid file.. please respecify.\n", log_file)
        )
    )
)

procedure(get_cell_info()
    let((log_file cell_lib cell_name cell_view in_h found line)
        log_file = filter_form~>log_file_field~>value
        cell_lib = ""
        cell_name = ""
        cell_view = ""
        if(isFile(log_file) then
            in_h = infile(log_file)
            found = 0
            while(gets(line in_h) && found == 0
                rexCompile("\n")
                line = rexReplace(line, "", 0)
                printf("%s\n", line)
                rexCompile("-top \\(.*\\)\\.\\(.*\\):\\(.*\\)")
                if(rexExecute(line) then
                    cell_lib = rexSubstitute("\\1")
                    cell_name = rexSubstitute("\\2")
                    cell_view = rexSubstitute("\\3")
                    found = 1
                )
            )
            close(in_h)
        else
            printf("%s is not a valid file.. please respecify.\n", log_file)
        )
        list(cell_lib cell_name cell_view)
    )
)

/*procedure(update_fields(@optional (sel 1))
    let((func_sel dict_sel keys_list filter_sel_list filter_key)
        func_sel = filter_form~>filter_function_field~>value
        dict_sel = all_dicts_table[func_sel]
        keys_list = sort(dict_sel~>? 'alphalessp)
        if(sel <= length(keys_list) && sel >= 1 then
            printf(nthelem(sel keys_list))
        else
            sel = 1
        )
        filter_sel_list = list(sel)
        filter_key = nthelem(sel keys_list)
        update_filter_type_field(filter_sel_list)
        update_selection_field(cadr(dict_sel[filter_key]))
    )
)*/

procedure(parse_log()
    let((log_file in_h cnt time_stamp temp_time curr_time line)
        log_file = filter_form~>log_file_field~>value
        blank_selections()
        clear_all_tables()
        if(isFile(log_file) then
            in_h = infile(log_file)
            cnt = 0
            time_stamp = "0.0 ns"
            while(gets(line in_h) && cnt < 50000
                rexCompile("\n")
                line = rexReplace(line, "", 0)
                rexCompile("^ *")
                line = rexReplace(line, "", 0)
                temp_time = parse_time(line)
                if(temp_time time_stamp = temp_time)
                curr_time = ""
                if(!rexMatchp("tran: time", line) then
                    curr_time = sprintf(nil "tran: time = %s ", time_stamp)
                )
                line = sprintf(nil "%d: %s %s", cnt, curr_time, line)
                parse_convergence(line)
                parse_warning(line)
                cnt += 1
                if(mod(cnt, 5000) == 0 then
                    printf("Processing %dth occurance..\n", cnt)
                )
                ;if(!sig)
                ;if(sig then
                    ;if(mod(cnt, 100) == 0 then
                        ;printf("Processing %dth occurance..\n", cnt)
                    ;)
                ;)
            )
            printf("Finished processing.\n")
            close(in_h)
            ;print_all_dict()
            process_all_dict()
            filter_form~>filter_function_field~>value = convergence_func
            update_filter_type_field()
        else
            printf("%s is not a valid file.. please respecify.\n", log_file)
        )
        ;filter_choices = gen_sort_by_freq_list(limiting_sigs_dict)
        ;update_filter_type_field(list())
        ;update_selection_field(filter_choices)
        ;sig_cnt_dict
    )
)

procedure(print_all_dict()
    let((k curr_dict subk curr_sub_dict)
        foreach(k all_dicts_table~>?
            curr_dict = all_dicts_table[k]
            foreach(subk curr_dict~>?
                curr_sub_dict = curr_dict[subk]
                printf("%s\n%s\n%s\n", k, subk, buildString(curr_sub_dict~>?, "\n    "))
            )
        )
    )
)
procedure(process_all_dict()
    let((k curr_dict all_dict subk net net_info in_dict f_list curr_keys out_item)
        foreach(k all_dicts_table~>?
            curr_dict = all_dicts_table[k]
            ;printf("%s\n%s\n", k, buildString(curr_dict~>?, "\n"))
            ;printf("%s\n", k)
            if(!member("all" curr_dict~>?) then
                ;curr_dict["all"] = makeTable("all table")
                all_dict = makeTable("all table")
                foreach(subk curr_dict~>?
                    foreach(net curr_dict[subk]~>?
                        if(!member(net all_dict~>?) all_dict[net] = list())
                        foreach(net_info curr_dict[subk][net]
                            if(!member(net_info all_dict[net]) then
                                all_dict[net] = append1(all_dict[net] net_info)
                            )
                        )
                    )
                )
                curr_dict["all"] = all_dict
            )

            curr_keys = curr_dict~>?
            foreach(subk curr_keys
                in_dict = curr_dict[subk]
                ;printf("%s\n%s\n", subk, buildString(in_dict~>? "\n"))
                ;it has list inforation and the list
                f_list = gen_sort_by_freq_list(in_dict)
                curr_dict[subk] = list(in_dict)
                foreach(out_item f_list
                    curr_dict[subk] = append1(curr_dict[subk] out_item)
                )
            )
        )
    )
)

procedure(append_kdict(in_dict k add_item)
    let(()
        if(member(k in_dict~>?) then
            in_dict[k] = append1(in_dict[k] add_item)
        else
            in_dict[k] = list(add_item)
        )
    )
)

procedure(append_subkdict(in_dict k subk add_item)
    let((sub_dict)
        sub_dict = makeTable("Sub dict")
        if(member(k in_dict~>?) sub_dict = in_dict[k])
        append_kdict(sub_dict subk add_item)
        in_dict[k] = sub_dict
    )
)

procedure(increase_subkcnt(in_dict k subk)
    let((sub_dict)
        sub_dict = makeTable("Sub dict")
        if(member(k in_dict~>?) sub_dict = in_dict[k])
        in_dict[k] = sub_dict
        increase_kcnt(sub_dict subk)
    )
)

procedure(increase_kcnt(in_dict k)
    let(()
        if(!member(k in_dict~>?) then
            in_dict[sig] = 1
        else
            in_dict[sig] = in_dict[sig] + 1
        )
    )
)

procedure(top_net_expr()
    let(()
        strcat("\\(" filter_form~>cellName~>value "\\.[^ ]+\\)")
    )
)

procedure(parse_time(line)
    let((time_expr out_time)
        time_expr = "tran: time = \\([^ ]+\\) *\\([^ ]+\\)"
        out_time = nil
        rexCompile(time_expr)
        if(rexExecute(line) then
            out_time = strcat(rexSubstitute("\\1") " " rexSubstitute("\\2"))
        )
        out_time
    )
)

procedure(parse_convergence(line)
    let((convergence_list expr_list sel_dict sig_list)
        convergence_list = list("limiting signal" "[a-zA-Z]* *breakpoint *[a-zA-Z]" "Worst Newton *[^ ]+", "convergence failure at solution", ", residue")
        expr_list = list()
        foreach(conv convergence_list
            expr_list = append1(expr_list strcat("\\(" conv "\\): *" top_net_expr()))
        )
        sel_dict = all_dicts_table[convergence_func]
        sig_list = parse_line_update_dict(line expr_list sel_dict)
    )
)

procedure(parse_warning(line)
    let((curr_expr expr_list sel_dict sig_list)
        curr_expr = strcat("WARNING (\\([A-Z]+-[0-9]+\\)):.*"  top_net_expr())
        expr_list = list(curr_expr)
        sel_dict = all_dicts_table[warning_func]
        sig_list = parse_line_update_dict(line expr_list sel_dict)
        ;if(length(sig_list) > 0 then
            ;printf("%s\n", line)
            ;printf("%s\n", buildString(sig_list, "\n"))
        ;)
    )
)

procedure(parse_line_only(line expr)
    let((sig_type sig_list)
        rexCompile(expr)
        sig_list = list()
        if(rexExecute(line) then
            ;warning_type = strcat(rexSubstitute("\\1") "_" rexSubstitute("\\3"))
            sig_type = rexSubstitute("\\1")
            sig_name = rexSubstitute("\\2")
            rexCompile(":.*$")
            sig_name = rexReplace(sig_name, "", 0)
            rexCompile("[:']*$")
            sig_name = rexReplace(sig_name, "", 0)
            rexCompile(" *$")
            sig_name = rexReplace(sig_name, "", 0)
            rexCompile("^,* *")
            sig_type = rexReplace(sig_type, "", 0)
            sig_list = append1(sig_list sig_type)
            sig_list = append1(sig_list sig_name)
        )
        sig_list
    )
)

procedure(parse_line_update_dict(line expr_list sel_dict)
    let((sig_list expr curr_list type sig)
        sig_list = list()
        foreach(expr expr_list
            curr_list = parse_line_only(line expr)
            if(length(curr_list) >= 2 then
                type = car(curr_list)
                sig = cadr(curr_list)
                sig_list = append1(sig_list sig)
                append_subkdict(sel_dict type sig line)
                append_subkdict(sel_dict "all" sig line)
                ;printf("%s\n", buildString(sel_dict[type]~>?, "\n"))
            )
        )
        sig_list
    )
)
procedure(gen_sort_by_freq_list(in_dict)
    let((out_list f_dict k k_list sig newk sig_list)
        out_list = list()
        out_dict = makeTable("with detailed information of the node")
        f_dict = sort_by_length(in_dict)
        foreach(k sort(f_dict~>? 'greaterp)
            k_list = sort(f_dict[k] 'alphalessp)
            foreach(sig k_list
                newk = sprintf(nil "%s(%d)", sig, k)
                ;sig_list = conv_path(sig)
                ;sig_list = append1(sig_list sig)
                sigs_rev_dict[newk] = sig
                out_list = append1(out_list newk)
                out_dict[newk] = buildString(gen_width_limited_text(in_dict[sig]) "\n")
            )
        )
        list(out_list out_dict)
    )
)

procedure(gen_width_limited_text(in_list @optional (lim 80))
    let((out_list in_str in_items curr_str ii item)
        out_list = list()
        foreach(in_str in_list
            in_items = parseString(in_str " ")
            curr_str = ""
            ii = 0
            foreach(item in_items
                if(length(item) > 0 then
                    if(ii == 0 then
                        curr_str = sprintf(nil "%s%s", curr_str, item)
                    else
                        curr_str = sprintf(nil "%s %s", curr_str, item)
                    )
                    if(length(curr_str) >= lim then
                        out_list = append1(out_list curr_str)
                        curr_str = "    "
                    )
                    ii = ii + 1
                )
            )
            if(!rexMatchp("^ *$", curr_str) then
                out_list = append1(out_list curr_str)
            )
        )
        out_list
    )
)
procedure(sort_by_length(in_dict)
    let((f_dict k cnt)
        f_dict = makeTable("Sort by freq dict")
        foreach(k in_dict~>?
            cnt = length(in_dict[k])
            append_kdict(f_dict cnt k)
        )
        f_dict
    )
)

procedure(sort_by_freq(in_dict)
    let((f_dict k cnt)
        f_dict = makeTable("Sort by freq dict")
        foreach(k in_dict~>?
            cnt = in_dict[k]
            append_kdict(f_dict cnt k)
        )
        f_dict
    )
)

procedure(update_filter_type_field()
    let((func_sel dict_sel keys_list sel filter_sel_list sk_list key filter_key)
        func_sel = filter_form~>filter_function_field~>value
        dict_sel = all_dicts_table[func_sel]
        sk_list = sort(dict_sel~>? 'alphalessp)
        keys_list = list("all")
        foreach(key sk_list
            if(key != "all" keys_list = append1(keys_list key))
        )
        ;if(sel <= length(keys_list) && sel >= 1 then
            ;printf(nthelem(sel keys_list))
        ;else
            ;sel = 1
        ;)
        sel = 1
        filter_sel_list = list(sel)
        filter_key = nthelem(sel keys_list)
        filter_form~>filter_type_field~>choices = keys_list
        filter_form~>filter_type_field~>value = filter_sel_list
        update_selection_field()
    )
)

procedure(update_selection_field()
    let((func_sel dict_sel filter_sel keys_list filter_key)
        filter_form~>net_selection_field~>choices = cadr(get_curr_dict())
        filter_form~>net_selection_field~>value = nil
        filter_form~>information_field~>value = ""
    )
)

procedure(get_curr_dict()
    let((func_sel dict_sel filter_sel)
        func_sel = filter_form~>filter_function_field~>value
        dict_sel = all_dicts_table[func_sel]
        filter_sel = car(filter_form~>filter_type_field~>value)
        dict_sel[filter_sel]
    )
)

procedure(fill_cell_values()
    let((cell_info)
        cell_info = get_cell_info()
        filter_form~>libName~>value = nthelem(1 cell_info)
        filter_form~>cellName~>value = nthelem(2 cell_info)
        filter_form~>viewName~>value = nthelem(3 cell_info)
    )
)

procedure(blank_selections()
    let(()
        filter_form~>filter_type_field~>choices = list("")
        filter_form~>net_selection_field~>choices = list("")
        filter_form~>information_field~>value = ""
    )
)
procedure(blank_cell_values()
    let((cell_info)
        filter_form~>libName~>value = ""
        filter_form~>cellName~>value = ""
        filter_form~>viewName~>value = ""
    )
)

procedure(check_cv()
    let((top_cv lib_name cell_name view_name)
        top_cv = geGetTopLevelCellView()
        lib_name = filter_form~>libName~>value
        cell_name = filter_form~>cellName~>value
        view_name = filter_form~>viewName~>value
        ;printf("lib_name = %s.\n", lib_name)
        if(!top_cv || !(top_cv~>libName == lib_name && top_cv~>cellName == cell_name && top_cv~>viewName == view_name) then
            deOpenCellView(lib_name cell_name view_name "" list() "r")
        )
        if(deGetCellView() != geGetTopLevelCellView() schHiReturnToTop())
    )
)

procedure(navigate_to_path()
    let((curr_sel path_list path_spec net orig_sig fspec)
        ;if(deGetCellView()~>cellName != cell_name schHiReturnToTop())
        check_cv()
        curr_sel = car(filter_form~>net_selection_field~>value)
        if(curr_sel && member(curr_sel sigs_rev_dict~>?) then
            orig_sig = sigs_rev_dict[curr_sel]
            ;path_spec = car(path_list)
            ;net = cadr(path_list)
            ;orig_sig = caddr(path_list)
            printf("%s\n", orig_sig)
            filter_form~>information_field~>value = caddr(get_curr_dict())[curr_sel]
            descend_to_path(orig_sig)
            ;printf("%s\n", path_spec)
            ;fspec = list(nil 'hierarchy path_spec)
            ;dePush(fspec hiGetCurrentWindow() "read")
            ;schHiSelectByProperty( "select" "instName" "==" inst)
            ;if(net != "" CCShilightNets(deGetCellView() net))
        else
            printf("Cannot find %L..", curr_sel)
        )
    )
)

procedure(descend_to_path(in_str)
    let((path_items ii path_correct push_to_inst last_inst curr_cv inst_dict item_name inst inst_view inst_obj path_spec fspec path_info term full_path net_name inst_path)
        net_name = nil
        if(member(in_str path_dict~>?) then
            path_info = path_dict[in_str]
            path_spec = car(path_info)
            fspec = list(nil 'hierarchy path_spec)
            dePush(fspec hiGetCurrentWindow() "read")
            net_name = cadr(path_info)
            sel_net(net_name)
            inst_path = caddr(path_info)
            last_inst = car(reverse(path_info))
        else
            path_items = parseString(in_str ".")
            ii = 0
            path_correct = t
            push_to_inst = t
            last_inst = nil
            full_path = ""
            inst_path = ""
            foreach(item path_items
                ii += 1
                curr_cv = hiGetCurrentWindow()~>cellView
                if(path_correct then
                    if(ii == 1 then
                        ;inst_path = sprintf(nil "%s/%s", inst_path, item)
                        if(item != curr_cv~>cellName then
                            printf("Top bench doesnot match with path.\n")
                            path_correct = nil
                        )
                    else
                        inst_dict = get_inst_dict(curr_cv)
                        item_name = remove_square(item)
                        if(push_to_inst then
                            if(member(item_name inst_dict~>?) then
                                inst = inst_dict[item_name]
                                inst_view = "schematic"
                                inst_obj = ddGetObj(inst~>libName inst~>cellName inst_view)
                                inst_path = sprintf(nil "%s/%s",inst_path, item)
                                if(inst_obj then
                                    ;obj successfully pushed into
                                    path_spec = sprintf(nil "/%s(%s)", item, inst_view)
                                    full_path = sprintf(nil "%s%s", full_path, path_spec)
                                    fspec = list(nil 'hierarchy path_spec)
                                    dePush(fspec hiGetCurrentWindow() "read")
                                else
                                    push_to_inst = nil
                                )
                                last_inst = inst
                            else
                                push_to_inst = nil
                                path_correct = nil
                                net_name = sel_net(item_name)
                            )
                        else
                            path_correct = nil
                            if(last_inst && member(item_name last_inst~>terminals~>name) then
                                foreach(term last_inst~>terminals
                                    if(term~>name == item_name then
                                        net_name = sel_net(term~>net~>name)
                                    )
                                )
                            else
                                net_name = sel_net(item_name)
                            )
                        )
                    )
                )
            )
            path_dict[in_str] = list(full_path net_name inst_path last_inst)
        )
        curr_cv = hiGetCurrentWindow()~>cellView
        hiGetCurrentWindow()~>dimmingOn = t
        printf("%s\n", inst_path)
        geAddInstProbe(hiGetCurrentWindow() list("y1" "drawing") inst_path)
        if(!net_name && last_inst zoom_to_inst(last_inst))
        ;inst_name = last_inst~>name
        ;if(last_inst && member(inst_name curr_cv~>instances~>name)
            ;schHiSelectByProperty("select" "instName" "==" inst_name)
        ;)
    )
)

procedure(zoom_to_inst(@optional (inst css()))
    let((obj_type bbox ext bot_left top_right x1 y1 x2 y2)
        if(inst then
            obj_type = inst~>objType
            bbox = inst~>bBox
            ext = 1
            if(obj_type == "line" ext = 3)
            bot_left = car(bbox)
            top_right = cadr(bbox)
            x1 = car(bot_left) - ext
            y1 = cadr(bot_left) - ext
            x2 = car(top_right) + ext
            y2 = cadr(top_right) + ext
            hiZoomIn(hiGetCurrentWindow() list(list(x1 y1) list(x2 y2)))
        )
    )
)
procedure(sel_net(in_name)
    let((item_comps net_name out_name)
        out_name = nil
        if(in_name then
            if(net = dbFindNetByName(deGetCellView() in_name) then
                highlight_net(in_name deGetCellView())
                out_name = in_name
                zoom_to_inst(car(net~>figs))
            else
                item_comps = parseString(in_name "__")
                net_name = car(item_comps)
                if(net = dbFindNetByName(deGetCellView() net_name) then
                    highlight_net(net_name deGetCellView())
                    zoom_to_inst(car(net~>figs))
                    out_name = net_name
                )
            )
        )
        out_name
    )
)

procedure(highlight_net(net_name @optional (cv deGetCellView()))
    let((net fig)
        CCShilightNets(deGetCellView() net_name)
        net = dbFindNetByName(cv net_name)
        fig = net~>figs
        if(fig then
            geSelectFig(car(fig))
            geEnterAddNetProbe()
        )
        fig
    )
)

procedure(remove_square(in_str)
    let((out_str)
        out_str = in_str
        rexCompile("<.*>")
        out_str = rexReplace(out_str, "", 0)
    )
)

procedure(get_inst_dict(@optional (cv deGetCellView()))
    let((inst_dict inst inst_name inst_name_nosq)
        inst_dict = makeTable("Instance table")
        foreach(inst cv~>instances
            inst_name = inst~>name
            inst_name_nosq = remove_square(inst_name)
            inst_dict[inst_name] = inst
            inst_dict[inst_name_nosq] = inst
        )
        inst_dict
    )
)

procedure(processed_instance_names(in_list)
    let((out_list name)
        out_list = list()
        foreach(name in_list
            out_list = append1(out_list, remove_square(name))
        )
        out_list
    )
)

procedure(conv_path(in_str)
    let((path path_items pn ii path_array net elem path_spec)
        ;if(member(in_str sig_to_path_net_dict~>?) then
            ;sig_to_path_net_dict[in_str]
        ;else
            ;rexCompile("(.*)")
            ;path = rexReplace(in_str "" 0)
            path = in_str
            path_items = parseString(path ".")
            pn = length(path_items)
            ii = 0
            path_array = list()
            net = ""
            foreach(elem path_items
                if(ii > 0 && ii < pn - 1
                    ;need to navigate based on config
                    path_array = append1(path_array sprintf(nil "/%s(schematic)", elem))
                )
                if(ii == pn - 1 net = elem)
                ii = ii + 1
            )
            path_spec = buildString(path_array, "")
            ;printf("%s %s\n", path_spec, net)
            ;sig_to_path_net_dict[in_str] = list(path_spec net)
        ;)
    )
)

procedure(run_filter()
    ;unless(boundp('filter_form)
    create_hierchary_filter_form()
    ;)
    hiDisplayForm(filter_form)
)

/* CCShilightNets.il

Group		Custom IC, Cadence Design Systems
Language	SKILL
Revision No.	1.2
Date Created	Jun 10, 2003 
Last Modified	
Tested in	IC50
Lint score	100 (best is 100)
Description:

A set of functions to hilight wires on a named net in a schematic.
There is a procedural interface function CCShilightNets() that can
be used, as well as a function that is intended for use with a
bindkey (CCShiHilightNets).  A filter function CCSwireFilter() is
defined for use with CCShiHilightNets to prevent objects other than
paths or lines from being selected.  A seperate function is supplied
to remove hilights: CCSunhilightNets()

Usage:

  CCShilightNets( d_cv t_netName ) => t/nil

  ;; sets the bindkey for the "t" key to be CCShiHilightNets()
  ;; then press 't' over a wire in the schematic window to hilight
  ;; all wires on the net in this schematic
  hiSetBindKey("Schematics" "<Key>t" "CCShiHilightNets()")

  ;; selects all wires for the net "myNetName" if found
  CCShilightNets(geGetEditCellView() "myNetName")

  ;; graphically select and hilight nets:
  CCShiHilightNets()

  ;; remove all hilights
  CCSunhilightNets()
  ;; OR
  CCShilightNets(geGetEditCellView() "")

***************************************************

SCCS Info: @(#) CCShilightNets.il 05/19/05.23:57:11 1.2

********************************************************************
* DISCLAIMER: The following code is provided for Cadence customers *
* to use at their own risk. The code may require modification to   *
* satisfy the requirements of any user. The code and any           *
* modifications to the code may not be compatible with current or  *
* future versions of Cadence products.                             *
* THE CODE IS PROVIDED "AS IS" AND WITH NO WARRANTIES, INCLUDING   *
* WITHOUT LIMITATION ANY EXPRESS WARRANTIES OR IMPLIED WARRANTIES  *
* OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.              *
********************************************************************

*/

/********************************************************************
*                                                                   *
*                 CCShilightNets( d_cv t_netName )                  *
*                                                                   *
*  A function to hilight wires in a schematic based on the netName  *
*    supplied. The hilighting is done via a hilight set which is    *
*  automatically cleared of any previous highlights before adding   *
* new objects to the hilight set. The hilight set is stored on the  *
*  property list slot of the function so new global variables are   *
* used. A blank string can be supplied to the function to clear the *
* hilight set for the cellview. Returns 't' if hilights were added, *
*                     otherwise returns 'nil'.                      *
*                                                                   *
********************************************************************/
procedure(CCShilightNets(cv netName "dt")
let( (netObj hlSet)
  ;; when cv is a valid cellview object
  when(cv~>objType == "cellView"
    ;; if the highlight set already exists then delete it
    when(hlSet = CCShilightNets.hlSet
      when(geIsValidHilightSet(hlSet)
	geDeleteHilightSet(hlSet)
      )
    )
    ;; create the hilight set and store it on the property list slot
    ;; of the function, then enable it
    CCShilightNets.hlSet = geCreateHilightSet(cv list("annotate" "drawing") nil)
    CCShilightNets.hlSet->enable = t
    ;; when net name is not a blank string
    unless(blankstrp(netName)
      ;; when the net object can be found in the cellview
      when(netObj = dbFindNetByName(cv netName)
	;; add a higlight for each figure belonging to the net
	foreach(fig netObj~>figs
	  geAddHilightFig(CCShilightNets.hlSet fig t)
	)
	;; return 't'
        t
      ); when net object
    ); when net name not blank
  ); when cellview
); let
); procedure CCShilightNets


/************************************************************************
*                                                                       *
*                          CCShiHilightNets()                           *
*                                                                       *
*  A function that is intended to be called by a bindkey. The function  *
* uses the current cellview and window and uses the current location of *
*  the pointer/mouse to find the name of net that is at that position.  *
*  The function CCShilightNets() is then called with the cellview and   *
*        netname arguments to select all wires on the named net.        *
*                                                                       *
************************************************************************/
procedure(CCShiHilightNets()
let( (point obj
     (win hiGetCurrentWindow())
     (cv geGetEditCellView())
     )
  ;; when the window and cellview are valid
  when(and(windowp(win) dbobjectp(cv))
    ;; get the current point and get the object at that point
    ;; filtering out anything that is not a "wire" object
    when(point = hiGetCommandPoint(win)
      when(obj = gePointQuery(win point "CCSwireFilter")
	CCShilightNets(cv obj~>net~>name)
      ); when obj
    ); when point
  ); when window and cellview valid
); let
); procedure CCShiHilightNets


/******************************************************************
*                                                                 *
*                      CCSwireFilter(d_fig)                       *
*                                                                 *
* A procedure used by CCShiHilightNets to filter out objects that *
*        are neither narrow or wide wires in a schematic.         *
*                                                                 *
******************************************************************/
procedure(CCSwireFilter(fig)
  case( fig~>objType 
    (("line" "path") t)
    (t nil)
  ); case
); procedure CCSwireFilter


/***************************************************************
*                                                              *
*                      CCSunhilightNets()                      *
*                                                              *
* A function to unhilight nets hilighted by the CCShilightNets *
*   function. This is achieved by removing the hilight set.    *
*                                                              *
***************************************************************/
procedure(CCSunhilightNets()
let( (hlSet)
  ;; if the highlight set exists then delete it
  when(hlSet = CCShilightNets.hlSet
    ;; when hlSet is a valid hilight set
    when(geIsValidHilightSet(hlSet)
      geDeleteHilightSet(hlSet)
    ); when
    CCShilightNets.hlSet = nil
  ); when hlSet
); let
); procedure CCSunhilightNets

