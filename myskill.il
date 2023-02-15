procedure(CCSAlign(refObj targetObjList direction space)
    let((i  refInst refXPoint refYPoint xform newXform)
;cv=geGetWindowCellView()
        refInst=refObj
        i=1
        foreach(targetInst targetObjList
            case(direction
            ("top"
                refXPoint=xCoord(refInst~>xy)
                refYPoint=yCoord(refInst~>xy)+space*i
                i=++i
            ) ;top
            ("bottom"
                refYPoint=yCoord(refInst~>xy)-space*i
                refXPoint=xCoord(refInst~>xy)
                i=++i
            ) ;bottom
            ("right"
                refYPoint=yCoord(refInst~>xy)
                refXPoint=xCoord(refInst~>xy)+space*i
                i=++i
            ) ;right
            ("left"
                refXPoint=xCoord(refInst~>xy)-space*i
                refYPoint=yCoord(refInst~>xy)
                i=++i)
            ) ;left
        
        xform=list(refXPoint : refYPoint "R0")
        newXform=dbConcatTransform(
                    list(mapcar('minus targetInst->xy) "R0" 1) xform)
        schStretch(list(targetInst) newXform)
        ) ;foreach
    ) ;let
) ;procedure

procedure(CCSgetCurrentTime()
   prog((date date_id)
       date_id=ipcBeginProcess("date '+%F'")
       ipcWait(date_id)
       date=ipcReadProcess(date_id)
    return(car(parseString(date "\n")))
    )
)

procedure(setCDF_notworking()
    let((lib_name cell_name)
        if(css() then
            lib_name = css()~>libName
            cell_name = css()~>cellName
        else
            lib_name = dgcv()~>libName
            cell_name = dgcv()~>cellName
        )
        curForm = stringToSymbol("opForm")
        hiRegTimer("setCDF_form(lib_name cell_name)" 5)
        ;hiRegTimer("hiiSetCurrentForm(curForm)" 1)
        ;aedEditCDF()
    )
)

procedure(setCDF()
    let((lib_name cell_name)
        if(css() then
            lib_name = css()~>libName
            cell_name = css()~>cellName
        else
            lib_name = dgcv()~>libName
            cell_name = dgcv()~>cellName
        )
        curForm = stringToSymbol("opForm")
        setCDF_form(lib_name cell_name)
        ;hiRegTimer("hiiSetCurrentForm(curForm)" 1)
        ;aedEditCDF()
    )
)

procedure(setCDF_form(in_lib in_cell)
    let(()
        ;hiiSetCurrentForm('opForm)
        ;this_form = opForm
        opForm->addLibName->value = in_lib
        opForm->addCellName->value = in_cell
    )
)


procedure(XLCloseDataOpenData()
   let((curLib curCell curView curViewType curCellViewID)
   	curCellViewID = deGetCellView()
	curLib = dbGetq(curCellViewID libName)
	curCell = dbGetq(curCellViewID cellName)
	curView = dbGetq(curCellViewID viewName)
	case(curView
		("schematic" 
		curViewType = "schematic")
		("layout"
		curViewType = "maskLayout")
		("symbol"
		curViewType = "schematicSymbol")
		(t
		curViewType = curView))
		
	dbPurge(curCellViewID)
;	hiRaiseWindow(deOpenCellView(curLib curCell curView curViewType hiGetSessionWindow(hiGetCurrentWindow()) "r" ))
	newWinID =deOpenCellView(curLib curCell curView curViewType hiGetSessionWindow(hiGetCurrentWindow()) "r" )
;	_hiSetCurrentWinNum(deOpenCellView(curLib curCell curView curViewType hiGetSessionWindow(hiGetCurrentWindow()) "r" )->windowNum)
    )
)

procedure(abOpenConfiguredSchematic(confLib confCell confView mode)
  let((hdb libName cellName viewName fileSpec)
    ;--------------------------------------------------------------------
    ; Find the top view from the config
    ;--------------------------------------------------------------------
    hdb=hdbOpen(confLib confCell confView mode)
    libName=hdbGetTopLibName(hdb)
    cellName=hdbGetTopCellName(hdb)
    viewName=hdbGetTopViewName(hdb)
    hdbClose(hdb)
    ;--------------------------------------------------------------------
    ; Build the filespec for deOpen
    ;--------------------------------------------------------------------
    fileSpec=list(nil)
    fileSpec->libName=libName
    fileSpec->cellName=cellName
    fileSpec->viewName=viewName
    fileSpec->accessMode=mode
    fileSpec->configL=list(confLib confCell confView mode)
    deOpen(fileSpec)
  )
)

procedure(real_fix(number)
    let( (num_string fix_num)
        sprintf( num_string, "%f" number)
        fix_num = atoi(car(parseString(num_string)))
        fix_num
    )
)

unless(member("~xwzhang/scripts/" getSkillPath()) setSkillPath(cons("~xwzhang/scripts/" getSkillPath())))
unless(member("./scripts/" getSkillPath()) setSkillPath(cons("./scripts/" getSkillPath())))

procedure(XLDefaultSimulator()
   let((curLib curCell curView simulator_chose state_chose curCellViewID)
  	curCellViewID = deGetCellView()
	curLib = dbGetq(curCellViewID libName)
	curCell = dbGetq(curCellViewID cellName)
	curView = dbGetq(curCellViewID viewName)
	case(curView
		("schematic" 
		    simulator_chose = "spectre"
		    state_chose="spectre_state1")
		(t
		    simulator_chose = "ams"
		    state_chose="ams_state1")
        )
	envSetVal("asimenv.startup" "simulator" 'string  simulator_chose)  
	;envSetVal("asimenv" "stateName" 'string  state_chose)  
    )
)

procedure(setTID()
   let((simulator_chose state_chose)
        ;setTID_only()
        setSpectre_only()
        cHost()
    )
)

procedure(setSimulatorState(simulator_chose state_chose)
    let((curSess curForm)
                printf("Setting simulator to %s\n", simulator_chose)
	        envSetVal("asimenv.startup" "simulator" 'string  simulator_chose)  
		if(curSess=sevSession(hiGetCurrentWindow()) then
			curForm = stringToSymbol(strcat("sevSimulatorForm" getSessNum()))
			hiRegTimer("hiiSetCurrentForm(curForm)" 1)
			hiRegTimer(sprintf(nil "csimulator(%L)", simulator_chose),2)
			hiRegTimer("hiFormDone(hiGetCurrentForm())",5)
			sevChooseSimulator(curSess)
		)
	;envSetVal("asimenv" "stateName" 'string  state_chose)
        )
)

procedure(csimulator(simualtor_chose)
	let((simulatorM)
		hiGetCurrentForm()->simulator->value=simulator_chose
		printf("Changing to %s.\n" simulator_chose)
	)
)

procedure(setSpectre_only()
   let((simulator_chose state_chose)
        simulator_chose = "spectre"
        state_chose="spectre_state1"
        setSimulatorState(simulator_chose state_chose)
    )
)

procedure(setTID_only()
   let((simulator_chose state_chose)
        simulator_chose = "TIspiceD"
        state_chose="TIspiceD_state1"
        setSimulatorState(simulator_chose state_chose)
    )
)

procedure(setTI4()
   let((simulator_chose state_chose)
        simulator_chose = "TIspice4"
        state_chose="TIspice4_state1"
        setSimulatorState(simulator_chose state_chose)
        cHost()
    )
)

 procedure(setams()
   let((simulator_chose state_chose cv1)
        simulator_chose = "ams"
        cv1=deGetCellView()
        stateSuffix = cv1~>viewName
        rexCompile("schematic_")
        stateSuffix=rexReplace(stateSuffix,"",0)
        rexCompile("schematic")
        stateSuffix=rexReplace(stateSuffix,"",0)
        if(stateSuffix != "" state_chose=strcat("ams_state_" stateSuffix) state_chose="ams_state1")
        if(not(ddGetObj(cv1~>libName cv1~>cellName state_chose))  state_chose="ams_state1")
        printf("Loading state : %s\n",state_chose)
        setSimulatorState(simulator_chose state_chose)
        printRunmode()
  )
)

procedure(customizeOpen()
	hiRegTimer("setOpenForm(deOpenForm)" 1)
	schHiOpenCellView()
	hiiSetCurrentForm('deOpenForm)
)

procedure(setOpenForm(form)
	let((winName thisView)
		winName = hiGetWindowName(hiGetCurrentWindow())
		if(rexMatchp("config" winName)
			thisView = nthelem(13,parseString(hiGetWindowName(hiGetCurrentWindow())))
			thisView = hiGetCurrentWindow()->cellView->viewName
                )
			
		form->deLibName->value = if(css()~>libName css()~>libName hiGetCurrentWindow()->cellView->libName)
		form->deCellName->value = if(css()~>cellName css()~>cellName hiGetCurrentWindow()->cellView->cellName)
		form->deViewName->value = thisView
	)
)

procedure(customizeNew()
	hiRegTimer("setNewForm(deNewForm)" 1)
	schHiNewCellView()
	hiiSetCurrentForm('deNewForm)
)

procedure(setNewForm(form)
	let((winName thisView)
		winName = hiGetWindowName(hiGetCurrentWindow())
		if(rexMatchp("config" winName)
			thisView = nthelem(13,parseString(hiGetWindowName(hiGetCurrentWindow())))
			thisView = hiGetCurrentWindow()->cellView->viewName)
			
		form->deLibName->value = if(css() css()~>libName hiGetCurrentWindow()->cellView->libName)
		form->deCellName->value = if(css() css()~>cellName  hiGetCurrentWindow()->cellView->cellName)
		form->deViewName->value = "schematic"
		form->appName->value="Schematics XL"
	)
)

procedure(getMySimLib()
    let((user mylib lib)
        user = getShellEnvVar("USER")
        mylib = ""
        foreach(lib ddGetLibList()
            if(rexMatchp(user lib~>name) mylib = lib~>name)
        )
        if(mylib == "" mylib = dgcv()~>libName)
        mylib
    )
)

procedure(get_all_vams()
    let((vams_file_array )
        vams_file_array = list()
        foreach(lib ddGetLibList()
            foreach(cell lib~>cells
                foreach(view cell~>views
                    foreach(f view~>files~>readPath
                        if(is_verilog_file(f) then
                            printf("%s\n", f)
                            vams_file_array = append1(vams_file_array f)
                        )
                    )
                )
            )
        )
    )
)

procedure(is_verilog_file(in_file)
    let((v_ext_array str_array file_name file_name_array file_ext)
        if(isFile(in_file) then
            v_ext_array = list("v", "va", "vams", "sv")
            str_array = parseString(in_file, "/")
            file_name = last_elem(str_array)
            file_name_array = parseString(in_file, ".")
            file_ext = last_elem(file_name_array)
            if(member(file_ext v_ext_array) t nil)
        else
            printf("%s is not a valid file.", in_file)
            nil
        )
    )
)

procedure(last_elem(in_array)
    let((last_item)
        if(listp(in_array) then
            last_item = nthelem(length(in_array), in_array)
        else
            last_item = in_array
        )
        last_item
    )
)
;procedure(createSimView(@optional (cv dgcv())))
procedure(createSimView(@optional (cv dgcv()))
    let((cv1 cvLib cvCell cvView cvDB libName cellName viewName newCell Iinst allInPins)
        cv1 = if(css() css() cv)
        cvLib = cv1~>libName
        cvCell = cv1~>cellName
        cvView = "symbol"
        cvDB = dbOpenCellViewByType(cvLib cvCell cvView  "" "r")
        libName = getMySimLib()
        cellName = strcat("sim_" cv1->cellName)
        viewName = "schematic"
        if(ddGetObj(libName cellName viewName) then
            printf("%s-%s-%s exists! Opening...\n", libName, cellName, viewName)
            deOpenCellView(libName cellName viewName  "" nil "a")
        else
            newCell = deNewCellView(libName cellName viewName  viewName nil)~>cellView
            Iinst = schCreateInst(newCell cvDB strcat("I_" cvCell) 0:0 "R0")
            allInPins = addNetsNOCONN(Iinst newCell)
            addgnds(newCell allInPins)
            schCheck(newCell)
            dbCheck(newCell)
            dbSave(newCell)
        )
    )
)

procedure(customizeInsert()
	hiRegTimer("setInsertForm(schCreateInstForm)" 1)
	schHiCreateInst()
	hiiSetCurrentForm('schCreateInstForm)
)

procedure(setInsertForm(form)
    let((instLib instCell)
        instLib = form->libraryName->value
        instCell = form->cellName->value
        if(css() then
            if(css()~>libName instLib = css()~>libName)
            if(css()~>cellName instCell = css()~>cellName)
        )
        form->libraryName->value = instLib
        form->cellName->value = instCell
    )
)
;"schHiOpenCellView()" "hiRegTimer(\"sprintf(nil \"deOpenForm->deLibName->value =%L\" hiGetCurrentWindow()->cellView->libName)\" 1)")

procedure(customizeNewSimCellView()
	hiRegTimer("setNewSimForm(deNewForm)" 1)
	schHiNewCellView()
	hiiSetCurrentForm('deNewForm)
)

procedure(setNewSimForm(form)
	let((winName thisView)
		winName = hiGetWindowName(hiGetCurrentWindow())
		if(rexMatchp("config" winName)
			thisView = nthelem(13,parseString(hiGetWindowName(hiGetCurrentWindow())))
			thisView = hiGetCurrentWindow()->cellView->viewName)
			
		;form->deLibName->value = if(css() css()~>libName hiGetCurrentWindow()->cellView->libName)
		form->deLibName->value = getMySimLib()
		form->deCellName->value = strcat("sim_" if(css()  css()~>cellName hiGetCurrentWindow()->cellView->cellName))
		form->deViewName->value = "schematic"
		form->appName->value="Schematics XL"
	)
)

procedure(openForm()
	deOpen()
	deOpenForm->deLibName->value=hiGetCurrentWindow()->cellView->libName
)

procedure(setLibName()
    let((thisForm)
	if(deOpenForm then
            thisForm = deOpenForm
        )
	if(deNewForm then
            thisForm = deNewForm
        )
	thisForm->deLibName->value=deGetCellView~>libName
	thisForm->deCellName->value="sim"
	thisForm->deViewName->value="schematics"
	thisForm->appName->value="Schematics XL"
	thisForm->saveApp->value= t
    )
)


procedure(CCSlistRestOfID(windowID instList)
        (if instList
            (if (cdr instList)
                (append (list (list windowID ((caar instList)->cellView)))
                        (CCSlistRestOfID windowID (cdr instList)))
                (list (list windowID ((caar instList)->cellView))))
            (list (list windowID (windowID->cellView)))))

procedure( CCSlistWindowID(windowID)
        (let (instanceList)
             instanceList = geGetHierMemInst(windowID)
             (if instanceList
                 (append (CCSlistRestOfID windowID geGetHierMemInst(windowID))
                        (list (list windowID geGetEditCellView(windowID))))
                 (if windowID->topCellView  list(list(windowID
                 windowID->topCellView)) '()))))

 procedure( CCSlistIdByWindow()
        let((windowList resultList curList)
            resultList = '()
            windowList = hiGetWindowList()
            (foreach curWindow windowList
                curList = CCSlistWindowID(curWindow)
                (if curList
                        resultList = (append resultList curList  )))
            resultList))


/*******************************************************************************
*  DISCLAIMER: The following code is provided for Cadence customers to use at  *
*   their own risk. The code may require modification to satisfy the           *
*   requirements of any user. The code and any modifications to the code may   *
*   not be compatible with current or future versions of Cadence products.     *
*   THE CODE IS PROVIDED "AS IS" AND WITH NO WARRANTIES, INCLUDING WITHOUT     *
*   LIMITATION ANY EXPRESS WARRANTIES OR IMPLIED WARRANTIES OF MERCHANTABILITY *
*   OR FITNESS FOR A PARTICULAR USE.                                           *
*******************************************************************************/
procedure(ABsaveState(libName cellName viewName "ttt")
let((sevId)
    sevId=sevSession(hiGetCurrentWindow())
    ;--------------------------------------------------------------------
    ; Because sevSaveState is blocking, use hiRegTimer to schedule a function to fill in the
    ; form once the UI returns. Pass the lib/cell/view to the callback.
    ;--------------------------------------------------------------------
    hiRegTimer(sprintf(nil "ABsaveStateActions(%L %L %L)" libName cellName viewName) 0)
    sevSaveState(sevId)
  )
)
procedure(ABsaveStateActions(libName cellName viewName)
  let((sevId form)
    sevId=sevSession(hiGetCurrentWindow())
    form=sevId->saveForm
    ;--------------------------------------------------------------------
    ; This example is set up to save as a cellView
    ;--------------------------------------------------------------------
    form->optionCellView->value="Cellview"
    form->libName->value=libName
    form->cellName->value=cellName
    form->stateName->value=viewName
    ; if you want the "Select All" button pressed
    ; this is just what appears in the CDS.log
    _sevSelectComponentField(sevId 'save 'all)
    hiFormDone(form)
  )
)

;;;sevSession.il
(procedure (GetsevSession)
   session=asiGetCurrentSession()
   num=session->name
   newnum=evalstring(substring(get_string(num) 8 5))+1
   sprintf(sestring "%s%n" "sevSession" newnum)
)
 
 
procedure(CCSDesWinOpen()
let((Des_win)
Des_win=setof(window hiGetWindowList() deGetEditViewType(window)=="schematic" ||
deGetEditViewType(window)=="maskLayout" || deGetEditViewType(window)=="schematicSymbol"
|| deGetEditViewType(window)=="graphic" || deGetEditViewType(window)=="analogArtist-schematic")
 
foreach(win Des_win
printf("\n %L Cell %L from Library %L View %L is open" win win~>cellView~>cellName
win~>cellView~>libName win~>cellView~>viewName)
);foreach
 
);let
);procedure



procedure( CCSLoadScript(sess)
; create a function called CCSLoadScript
println("************************************************************************")
println("************************************************************************")
 
printf("The current PSF DIR is %L\n" asiGetPsfDir(sess))
 
(if (isDir (strcat (asiGetPsfDir sess) "/../netlist")) then
   myNetlistDir = (strcat (asiGetPsfDir sess) "/../netlist")
else
   myNetlistDir = (strcat (asiGetPsfDir sess) "/../../../netlist")
)
printf("My netList Dir for this run is %s\n" myNetlistDir)
;netlistPath= (strcat "/home/user/perl.prog " myNetlistDir )
;aa= ipcBeginProcess(netlistPath )
println("************************************************************************")
println("************************************************************************")
asiRunSimulation(sess)
) ; proc

procedure( changeStep()
asiChangeFlowchartStep(asiGetFlowchart(asiGetCurrentSession())
?name 'asiRunSimulation
?preFunc 'CCSLoadScript
)
)

procedure( Set_design(lib cell view)
 
  sevChooseDesign(sevSession(hiGetCurrentWindow()))
 
  session_num=substring(sevSession(hiGetCurrentWindow()) 11)
  des_form_num = concat("sevDesignForm" session_num)
  
  eval(des_form_num)->lib->value = lib
  eval(des_form_num)->cell->value = list(cell)
  eval(des_form_num)->view->value = view
  
  hiFormDone(eval(des_form_num))
  
)

procedure( CCSchangeInstParams( cv instprops @optional quiet force "dlgg")
  let( (instName propName prop value instId)
    ;; when cv is a database object and instprops is a non-empty list
    when( and(dbobjectp(cv) pairp(instprops))
      ;; for each instance-property-value triplet
      ;; if the instance and the property on that instance exist,
      ;; replace the value with the new given value, otherwise
      ;; print a message (unless in quiet mode)
      foreach( instprop instprops
	instName = car(instprop)
	propName = cadr(instprop)
	value    = caddr(instprop)
	if( and( instId = dbFindAnyInstByName(cv instName)
		 prop   = dbSearchPropByName(instId propName)) then
	  dbReplaceProp(instId propName prop~>valueType value)
	  unless(quiet
	     printf("Replaced property %s on instance %s, new value %L\n"
	      propName instName value)
	  )
	else
	  ;; if the force argument is non-nil then create the property
	  ;; otherwise, if the quiet mode was on print out a message
	  if(force then
	    dbCreateProp(instId propName
	      ;; if the value is 'nil' create a boolean property
	      ;; if the value is a symbol create a boolean property
	      ;; for all other values use the data type of the value
	      cond(
	        (!value 'boolean)
		(type(value)=='symbol 'boolean)
		(t type(value))
	      );; cond
	      value)
	    unless(quiet
	      printf("Created property %s on instance %s with value %L\n"
		propName instName value)
	    )
	  else
	    unless(quiet
	      printf(
		"Instance %s or property %s on the instance doesn't exist\n"
		instName propName
	      )
	    );; unless in quiet mode
	  );; if force mode is on
	);; if instance and property exist
      );; foreach
      t
    );; when a valid db object and non-empty list
  );; let
);; procedure CCSchangeInstParams


/**************************************************************************
*                                                                         *
*                          CCSbuildInstPropList(                          *
*                            [?cv d_cellView]                             *
*                         [?cellName t_cellName]                          *
*                        [?paramName t_paramName]                         *
*                           [?newValue g_value]                           *
*                                    )                                    *
*  Builds a list of lists where each sublist is composed of an instance   *
* name, a parameter name and a parameter value.  The keyword arguments to *
*  the function include the cellview db object, the name of the cell to   *
*  get the instances for and the parameter name and new value.  The ?cv   *
*       argument defaults to the current cellview if not supplied.        *
*                                                                         *
**************************************************************************/
procedure( CCSbuildInstPropList( @key (cv geGetEditCellView())
	      cellName paramName newValue "dttg")
  when( and(stringp(cellName) stringp(paramName) dbobjectp(cv))
    foreach(mapcar obj
      ;; the list of cell instances to iterate over
      setof(inst cv~>instances inst~>cellName == cellName)
      list(obj~>name paramName newValue)
    )
  )
);; procedure CCSbuildInstPropList
;-----------------------------------------------------------------

procedure(plotXL()
    let((rawWinName schPlotFileName printFile pdfFile)
        rawWinName = hiGetWindowName(hiGetCurrentWindow())
        schPlotFileName = sprintf(nil "%s_%s" nthelem(7 parseString(rawWinName)) nthelem(8 parseString(rawWinName)))
        printFile = strcat("/home/xwzhang/tests/" schPlotFileName ".eps" )
        sh(strcat("/bin/rm " printFile))
        pdfFile = strcat("/home/xwzhang/tests/" schPlotFileName ".pdf" )
        hiRegTimer("" 5)
        sh(strcat("/bin/rm " pdfFile))
        hiRegTimer("hiFormDone(schPlotOptionsForm)" 2)
        hiRegTimer("setPlotOptions(printFile)" 1)
        hiRegTimer("hiFormDone(schPlotSubmitForm)" 4)
        hiRegTimer("setPlotSubmitOptions()" 3)
        schHiPlot()
        while(not(isFile(printFile))
            printf("just wait..\n")
        )
        convEps2Pdf(printFile pdfFile)
        while(not(isFile(pdfFile))
            printf("just wait..\n")
        )
        transferFile(pdfFile)
        transferFile(printFile)
    )
)

procedure(setPlotOptions(printFile)
    let(()
        schiPlotOptionsBtnCB()
        hiiSetCurrentForm('schPlotOptionsForm)
        ;schPlotOptionsForm->plotPlotterCyclic->value = "hp2"
        schPlotOptionsForm->plotPlotterCyclic->value = "psfile"
        schPlotOptionsForm->plotPaperSizeCyclic->value = "A"
        ;hiRegTimer("schPlotOptionsForm->plotPaperSizeCyclic->value =\"A\"  " 3)
        schPlotOptionsForm->plotOrientationRadio->value = "automatic"
        schPlotOptionsForm->plotFitToggle->fit->value =  t
        schPlotOptionsForm->plotCenter->center->value =  t
        ;schPlotOptionsForm->plotOffsetX->value = 0.0
        ;schPlotOptionsForm->plotOffsetY->value = 0.0
        schPlotOptionsForm->plotToFileToggle->send->value =  t
        schPlotOptionsForm->plotMailLogToggle->mail->value =  nil
        ;hiRegTimer("schPlotOptionsForm->plotToFileStr->value = sprintf(printFile \"./%s.eps\" schPlotFileName) "  3)
        schPlotOptionsForm->plotToFileStr->value = printFile
        schPlotOptionsForm->plotMailLogNames->value = "xwzhang"
    )
)


procedure(setPlotSubmitOptions()
    let(()
        hiiSetCurrentForm('schPlotSubmitForm)
        schPlotSubmitForm->plotAreaRadio->value = "viewing area"
        schPlotSubmitForm->plotPlotSelection->header->value =  nil
        ;hiFormDone(schPlotSubmitForm)
    )
)

procedure(mailFile(emailTitle filePath)
    let((mailCmd)
        mailCmd = sprintf(nil "mailx -s %s -a %s xiwen.zhang@nuvoltatech.com", emailTitle, filePath)
        sh(mailCmd)
    )
)

procedure(convEps2Pdf(inEps outPdf)
    let(()
        sh(strcat("ps2pdf " inEps " " outPdf))
    )
)

procedure(transferFile(file)
    let((tcmd)
        if(isFile(file) then
            tcmd = strcat("expect /home/xwzhang/test.scp " file)
            printf("%s\n" tcmd)
            sh(tcmd)
            printf("%s is tranferred to others by xwzhang\n", file)
        )
    )
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procedure(plotXLL()
    let((rawWinName schPlotFileName printFile)
        rawWinName = hiGetWindowName(hiGetCurrentWindow())
        schPlotFileName = sprintf(nil "%s_%s" nthelem(7 parseString(rawWinName)) nthelem(8 parseString(rawWinName)))
        schHiPlot()
        sh("sleep 2")
        ;hiiSetCurrentForm('schPlotSubmitForm) 
        schPlotSubmitForm->plotAreaRadio->value = "viewing area"
        schPlotSubmitForm->plotPlotSelection->header->value =  nil
        hiRegTimer("schiPlotOptionsBtnCB()" 2)
        ;hiiSetCurrentForm('schPlotOptionsForm) 
        ;schPlotOptionsForm->plotPlotterCyclic->value = "Encapsulated Postscript FILE Color"
        schPlotOptionsForm->plotPlotterCyclic->value="Encapsulated PostScript FILE Color"
        schPlotOptionsForm->plotPaperSizeCyclic->value = "Unlimited"
        schPlotOptionsForm->plotOrientationRadio->value = "automatic"
        schPlotOptionsForm->plotFitToggle->fit->value =  t
        schPlotOptionsForm->plotCenter->center->value =  t
        schPlotOptionsForm->plotOffsetX->value = 0.0
        schPlotOptionsForm->plotOffsetY->value = 0.0
        schPlotOptionsForm->plotToFileToggle->send->value =  t
        schPlotOptionsForm->plotToFileStr->value = sprintf(printFile "~/tmp/%s.eps" schPlotFileName)
        schPlotOptionsForm->plotMailLogToggle->mail->value =  nil
        hiRegTimer("and(boundp('schPlotOptionsForm) hiiSetCurrentForm('schPlotOptionsForm) hiFormDone(schPlotOptionsForm))" 10)
        ;if(hiiSetCurrentForm('schPlotOptionsForm) hiFormDone(schPlotOptionsForm))
        ;hiiSetCurrentForm('schPlotOptionsForm) 
        ;hiFormDone(schPlotOptionsForm)
        sh( "sleep 2" )
        hiRegTimer("and(boundp('schPlotSubmitForm) hiiSetCurrentForm('schPlotSubmitForm) 
        hiFormDone(schPlotSubmitForm))" 15)

        ;hiFormDone(schPlotSubmitForm)
        ;if(hiiSetCurrentForm('schPlotSubmitForm) hiFormDone(schPlotSubmitForm))
        ;hiFormDone(hiGetCurrentForm())
        ;hiFormDone(hiGetCurrentForm())
        sh("sleep 2" )
        sh(sprintf(nil "mailx -s %s -a %s %s@ti.com" schPlotFileName printFile whoami()))
        printf("\n")
        printf("%s.eps is sent to %s@ti.com\n" schPlotFileName whoami())
        hiFormDone(schPlotSubmitForm)
    )
)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


procedure( CCSinstReplace()
  let((newRefLib targetLib oldCellName newCellName view updateForm)
        newRefLib = hiCreateStringField(
                ?name           'newRefLib
                ?prompt         "Name of new reference library"
                ?callback       ""
                ?editable       t
        )
 
    targetLib = hiCreateStringField(
                ?name           'targetLib
                ?prompt         "Name of target library"
                ?callback       ""
                ?editable       t
        )
 
    oldCellName = hiCreateStringField(
                ?name           'oldCellName
                ?prompt         "Name of cell to be replaced"
                ?callback       ""
                ?editable       t
        )
 
    newCellName = hiCreateStringField(
                ?name           'newCellName
                ?prompt         "Name of new cell"
                ?callback       ""
                ?editable       t
        )
    
    view = hiCreateRadioField(
                ?name           'view
                ?prompt         "Choose view"
                ?choices        list("schematic" "layout")
        )
 
    updateForm = hiCreateAppForm(
                ?name           'updateForm
                ?formTitle      "Instance Replacement Helper"
                ?callback       'CCSreplace(hiGetCurrentForm() )
                ?fields         list(newRefLib targetLib oldCellName newCellName view)
                ?help           ""
                ?unmapAfterCB   nil
        )
 
        hiDisplayForm( updateForm )
  );let
)
 
 
procedure(CCSreplace(theForm)
    let((cv libId cellList newRlib viewName libName oldCell newCell)
        ;extract parameters from the form
        newRlib = theForm->newRefLib->value
        viewName = theForm->view->value
        libName = theForm->targetLib->value
        oldCell = theForm->oldCellName->value
        newCell = theForm->newCellName->value
        libId = ddGetObj(libName)
        cellList = libId~>cells

        foreach(cell cellList
            foreach(view cell~>views        ;using views matching viewName variable.
                if(view~>name == viewName && (cv=dbOpenCellViewByType(libName  cell~>name view~>name "" "a")) then
                printf("\nReplacing instances in cellview %L of library %L\n" cv~>cellName cv~>libName)

                foreach( instId cv~>instances
                    if( instId~>cellName == oldCell then
                         leReplaceAnyInstMaster(instId newRlib newCell nil)
                    ) ;if
                ) ;foreach
                dbCheck(cv)
                dbSave(cv)
                dbClose(cv)
                ) ;if
            ) ;foreach
        );foreach
        ddReleaseObj(libId)
        printf("\nJob Done... :-)  \n")
    );let
);procedure

procedure( CCSlibReplace()
  let((newLibName oldLibName cellInLib cellUpdate view updateForm)
        newLibName = hiCreateStringField(
                ?name           'newLibName
                ?prompt         "Name of new library"
                ?callback       ""
                ?editable       t
                ?defValue	"TPS51623"
        )

    oldLibName = hiCreateStringField(
                ?name           'oldLibName
                ?prompt         "Name of old library"
                ?callback       ""
                ?editable       t
                ?defValue	"TPS51631"
       )
 
 
     cellInLib = hiCreateStringField(
                ?name           'cellInLib
                ?prompt         "Name of library of the cell needs to be changed"
                ?callback       ""
                ?editable       t
                ?defValue	"test"
        )
 
     cellUpdate = hiCreateStringField(
                ?name           'cellUpdate
                ?prompt         "Name of cell needs to be changed"
                ?callback       ""
                ?editable       t
 		?defValue	"testskill"
        )
 
    view = hiCreateRadioField(
                ?name           'view
                ?prompt         "Choose view"
                ?choices        list("schematic" "layout")
        )
 
    updateForm = hiCreateAppForm(
                ?name           'updateForm
                ?formTitle      "Instance Replacement Helper"
                ?callback       'libreplace(hiGetCurrentForm() )
                ?fields         list(newLibName cellUpdate cellInLib oldLibName view)
                ?help           ""
                ?unmapAfterCB   nil
        )
 
        hiDisplayForm( updateForm )
  );let
)


procedure(libreplace(theForm)
    let((newRlib viewName oLName libOfCell cellNeedChange instId cv)

        ;extract parameters from the form
        newRlib = theForm->newLibName->value
        viewName = theForm->view->value
        oLName = theForm->oldLibName->value
        ;printf("\n %L oldlibrary name" oLName)
        libOfCell = theForm->cellInLib->value
        cellNeedChange=theForm->cellUpdate->value
        cv=dbOpenCellViewByType(libOfCell cellNeedChange viewName "" "a")
        printf("\nReplacing instances in cellview %L in library %L to library %L\n" cellNeedChange libOfCell newRlib)
        foreach( instId cv~>instances
            if(instId~>libName == oLName printf("\nReplacing %L->%L" instId~>libName instId~>cellName))
            if(instId~>libName == oLName then
                leReplaceAnyInstMaster(instId newRlib instId~>cellName nil)
            ) ;if
        ) ;foreach

        dbCheck(cv)
        dbSave(cv)
        dbClose(cv)
      );let
      printf("\nJob Done... :-)  \n")
);procedure

;load("browserXL.il")
procedure(CCSOpenSchematic(strLib strCell strView waittime)
    let((cwin swin nwin waits2)
        when(boundp('hePromptForm)
            hiRegTimer("hiFormDone(hePromptForm)" waittime)
            hePromptForm->editTopCV->value = "yes"
            hePromptForm->editCfg->value = "no"
        )
        if(and(cwin = hiGetCurrentWindow() swin = hiGetSessionWindow(cwin) nwin = hiOpenWindow(?session swin)) then
            geOpen(?window nwin ?lib strLib ?cell strCell ?view strView ?viewType "" ?mode "a")
        else
            deOpenCellView(strLib strCell strView "" nil "a")
        )
    ;     deInstallApp(wid strcat(strLib "_" strCell "_" strView))
        waits2=2*waittime
        ;hiRegTimer("deInstallApp(getCurrentWindow() \"analogArtist-Schematic\")" waits2)
    );let
);procedure


/*********************************************************************
* DISCLAIMER: This code is provided for Cadence customers to use     *
* with Cadence tools at their own risk. The code may require         *
* modification to satisfy the requirements of any user. The code and *
* any modifications to the code may not be compatible with current or*
* future versions of Cadence products.                               *
* THE CODE IS PROVIDED "AS IS" AND WITH NO WARRANTIES, INCLUDING     *
* WITHOUT LIMITATION ANY EXPRESS OR IMPLIED WARRANTIES OF            *
* MERCHANTABILITY, FITNESS FOR A PARTICULAR USE OR NON-INFRINGEMENT. *
*********************************************************************/

procedure(CCSAlign(refObj targetObjList direction space)
let((i  refInst refXPoint refYPoint xform newXform)
;cv=geGetWindowCellView()
refInst=refObj
i=1
  foreach(targetInst targetObjList
    case(direction
      ("top"
         refXPoint=xCoord(refInst~>xy)
         refYPoint=yCoord(refInst~>xy)+space*i
         i=++i
       ) ;top
      ("bottom"
         refYPoint=yCoord(refInst~>xy)-space*i
         refXPoint=xCoord(refInst~>xy)
         i=++i
       ) ;bottom
      ("right"
         refYPoint=yCoord(refInst~>xy)
         refXPoint=xCoord(refInst~>xy)+space*i
         i=++i
       ) ;right
      ("left"
         refXPoint=xCoord(refInst~>xy)-space*i
         refYPoint=yCoord(refInst~>xy)
         i=++i)
       ) ;left
 
   xform=list(refXPoint : refYPoint "R0")
   newXform=dbConcatTransform(
            list(mapcar('minus targetInst->xy) "R0" 1) xform)
   schStretch(list(targetInst) newXform)
   ) ;foreach
) ;let
) ;procedure
 
/***************/


procedure(create_wire(cv1 instance1 offset wireDirection wireName matchTerm)
	let((termOfMyInst xa xb ya yb x1 y1 dir rotation mypin mywire mywirelabel lxloc lyloc instTermbBox)
             foreach(termOfMyInst instance1~>instTerms
;	       printf("%s	" termOfMyInst~>name)
               when(rexMatchp(matchTerm termOfMyInst~>name)
               instTermbBox = dbTransformBBox( car(termOfMyInst~>term~>pins~>fig~>bBox) instance1~>transform )
               xa = caar(instTermbBox)
               xb = caadr(instTermbBox)
               ya = cadar(instTermbBox)
               yb = cadadr(instTermbBox)
               x1 = (xa + xb)/2
               y1 = (ya + yb)/2
               dir = nil
               rotation = nil
               case(wireDirection
        	       ("left"
 ;       	       dir = ip
        	       xf = x1 - offset
        	       yf = y1
		       lxloc =xf   ;the label x loc
		       lyloc = yf+0.05 ;the label y loc
        	       rotation = "R0"
        	       )
        	       ("right"
 ;       	       dir = op
        	       xf = x1 + offset
        	       yf = y1
		       lxloc =x1   ;the label x loc
		       lyloc = y1+0.05 ;the label y loc
        	       rotation = "R0"
        	       )
        	       ("down"
;        	       dir = iop
        	       xf = x1
        	       yf = y1 - offset
		       lxloc =xf-0.05   ;the label x loc
		       lyloc = yf ;the label y loc
        	       rotation = "R90"
        	       )
       	       		("up"
 ;       	       dir = iop
        	       xf = x1
        	       yf = y1 + offset
		       lxloc =x1-0.05   ;the label x loc
		       lyloc = y1 ;the label y loc
        	       rotation = "R90"
        	       )
               );case terminal direction
;	       printf("wire locations: %f:%f %f:%f\n" xf yf x1 y1)
;              mypin = schCreatePin(cv1 dir pinName termOfMyInst~~>direction nil xf:yf rotation)
               mywire = schCreateWire(cv1 "draw" "full" list(xf:yf x1:y1 ) 0.0625 0.0625 0.0)
               if(wireName mywirelabel=schCreateWireLabel(cv1 car(mywire) lxloc:lyloc wireName "lowerLeft" rotation "stick" 0.0625 nil))
               );when term name is OUT
	       );foreach termOfMyInst	       
	);let
);procedure


procedure(showCos()
    let(()
        hiRegTimer("hiiSetCurrentForm('dssShowCoForm)" 2)
        hiRegTimer("setDssSCoForm(dssShowCoForm)" 3)
        dssShowCheckoutsMCB(t)
        hiRegTimer("hiFormDone(dssShowCoForm)" 4)
    )
)

procedure(viewVH()
	dssViewVerHistCB()
	hiiSetCurrentForm('dssViewVHForm)
	hiRegTimer("hiFormDone(dssViewVHForm)" 2)
)

procedure(setDssSCoForm(form)
	let(()
		form->libName->value= if(deGetCellView() list(deGetCellView()~>libName) list(nthelem(1 parseString(nthelem(2 parseString(pwd() "/")) "_"))))
		form->new->value= t
		form->user->value=whoami()
	)
)


procedure(CCSSchSnapToggle() 
	if(schGetEnv("schSnapSpacing")==0.0625 then 
		printf("Setting snapspacing from 0.0625 to 0.00625\n");
		schSetEnv("schSnapSpacing" 0.00625) 
	else 
		printf("Setting snapspacing from 0.00625 to 0.0625\n");
		schSetEnv("schSnapSpacing" 0.0625) 
	) 
)

procedure(curr_win_toggle()
    let((curr_x_snap curr_y_snap)
        curr_x_snap = window(hiGetCurrentWindow()->windowNum)->xSnapSpacing
        curr_y_snap = window(hiGetCurrentWindow()->windowNum)->ySnapSpacing
        if(curr_x_snap != 0.0625 then
            printf("Setting snapspacing 0.0625\n");
            window(hiGetCurrentWindow()->windowNum)->xSnapSpacing=0.0625
            window(hiGetCurrentWindow()->windowNum)->ySnapSpacing=0.0625
        else
            printf("Setting snapspacing 0.00625\n");
            window(hiGetCurrentWindow()->windowNum)->xSnapSpacing=0.00625
            window(hiGetCurrentWindow()->windowNum)->ySnapSpacing=0.00625
        )
    )
)

procedure(descend_toggle()
    let((descend_target)
        descend_target = envGetVal("schematic" "descendTarget" 'string)
        if(descend_target != "query user" then
            printf("Setting descend target to be query user\n");
            envSetVal("schematic" "descendTarget" 'string "query user")
        else
            printf("Setting descend target to be use viewNameList\n");
            envSetVal("schematic" "descendTarget" 'string "use viewNameList")
        )
    )
)


procedure(CCSTop()
let( ()
  enterPoint(?prompts list("Click on a schematic wire")
             ?doneProc "CCSPointDone"
            )
   t
  );let
);procedure
 
 ;;-----------------------Upto here-------------------------

procedure(CCSPointDone(w done points)
    let((myfig)
        if(done then
            ;printf("\nYou entered %L\n" car(points) )
            geSelectPoint(w car(points) )
            myfig = car(geGetSelSet() )
            if(myfig~>layerName == "wire" then
                CCSProc(myfig~>net~>name)
                geDeselectAllFig()
            else
                error("\nThe object you clicked on is not a wire. Please retry\n")
            );if
 
        else
            printf("\nPoint entry aborted\n")
        );if
    );let
);procedure
 
procedure( CCSProc(netName @optional ( cvId geGetEditCellView() ) "td")  
    let((mynet mySigList myInstName myInstMasterName  )
        unless(cvId~>objType == "cellView"
            error("Please pass a valid cellview Id to this procedure\n")
        )
        mynet = dbFindNetByName(cvId netName)
        mySigList = mynet~>signals
        if(mynet then
            printf("\nNet Name: %s" mynet~>name)
            foreach(sig mySigList
                foreach(mInstTrm sig~>memInstTerms
                    myInstName = car(mInstTrm)~>inst~>name 
                    myInstMasterName = car(mInstTrm)~>inst~>master~>cellName
                    printf("\nInstance Name: %-15s ;; Instance Master Cell Name: %-15s\n" myInstName, myInstMasterName)
                )
            )
            printf("\nDONE\n")
        else
            error("\nCannot find a net with name %s in the cellview" netName)
        );if
    );let
);procedure
;;-----------------------Upto here-------------------------
procedure(alignShapes(@optional (direction "left"))
	let((i newx1 newy1 x1 xmax xmin y1 ymax ymin inst tr)
		i = 0
		foreach(inst geGetSelectedSet()
			x1 = caar(inst~>bBox)
			x2 = caadr(inst~>bBox)
			y1 = cadar(inst~>bBox)
			y2 = cadadr(inst~>bBox)
			if(i==0 then
				xmax=x2
				xmin=x1
				ymax=y2
				ymin=y1
			else
				if(x2>xmax then
					xmax = x2
				)
				if(x1<xmin then 
					xmin = x1
				)
				if(y2>ymax then
					ymax = y2
				)
				if(y1<ymin then
					ymin = y1
				)
			);if
		)
		if(!direction direction="left")
		
		numOfItem = length(geGetSelectedSet())
		foreach(inst geGetSelectedSet()
			x1=car(inst~>xy)
			y1=cadr(inst~>xy)
			case(direction
				("left"
					newx1=xmin
					newy1=y1
				)
				("right"
					newx1=xmax
					newy1=y1
				)
				("top"
					newx1=x1
					newy1=ymax
				)
				("bottom"
					newx1=x1
					newy1=ymin
				)
				("vcenter"
					newx1=xmin/2.0+xmax/2.0
					newy1=y1
				)
				("hcenter"
					newx1=x1
					newy1=ymin/2.0+ymax/2.0
				)
				(t
					newx1=xmin
					newy1=y1
				)
			)
			tr = list( (newx1-x1):(newy1-y1) "R0" )
			schStretch( list(inst) tr )
			;inst~>xy=list(newx1,newy1)
			snapToGrid(list(inst))
		) ;foreach
	)
)

procedure(ggss()
	geGetSelectedSet()
)
procedure(dgcv()
	deGetCellView()
)

procedure(getCDF(inst)
        cdfGetInstCDF(inst)
)

procedure(GETCDF(inst)
        cdfGetInstCDF(inst)
)

procedure(addDiode(diode @optional (net1 nil)(net2 nil)(dir nil))
	let((cv1 dioTable lbc7lib diodeNames dioTable  diodeName  inst  instx1 insty1 instx2  insty2 wire1x1loc wire1y1loc wire1x2loc  wire1y2loc wire1 wire2x1loc wire2y1loc wire2x2loc wire2 wire2y2loc         )
		cv1=dgcv()
		dioTable=makeTable("Diodes table")
		lbc7lib="lbc7"
		diodeNames=list("DIO_GRNW_220" "DIO_NW7V" "DIO_NW3V" "DIODE_ISO_PW_NW")
		foreach(diodeName diodeNames
			dioTable[diodeName]=dbOpenCellViewByType(lbc7lib diodeName "symbol" "" "r")
		)
		
		unless(dir dir="left")
		case(dir
			("right"
				dioxloc=car(css()~>xy)+0.5
				dioyloc=cadr(css()~>xy)
			)
			("up"
				dioxloc=car(css()~>xy)
				dioyloc=cadr(css()~>xy)+1.5
			)
			("down"
				dioxloc=car(css()~>xy)
				dioyloc=cadr(css()~>xy)-1.5
			)
			(t
				dioxloc=car(css()~>xy)-0.5
				dioyloc=cadr(css()~>xy)
			)
		)
		if(diode=="ISO" diodeName="DIODE_ISO_PW_NW" diodeName=strcat("DIO_" diode))
		if(dioTable[diodeName] then
			inst=schCreateInst(cv1 dioTable[diodeName] nil list(dioxloc dioyloc) "R0")
			instx1=caar(inst~>bBox)
			insty1=cadar(inst~>bBox)
			instx2=caadr(inst~>bBox)
			insty2=car(cdadr(inst~>bBox))
			wire1x1loc=(instx1+instx2)/2.0-0.01875
			wire1y1loc=insty2-0.08125
			wire1x2loc=wire1x1loc
			wire1y2loc=wire1y1loc+0.25
			wire1=schCreateWire(cv1 "draw" "full" list(wire1x1loc:wire1y1loc wire1x2loc:wire1y2loc) 0.0625 0.0625 0.0)
			if(net1 schCreateWireLabel(cv1 car(wire1) wire1x1loc-0.03125:wire1y1loc net1 "lowerLeft" "R90" "stick" 0.0625 nil))
			wire2x1loc=wire1x1loc
			wire2y1loc=insty1+0.13125
			wire2x2loc=wire2x1loc
			wire2y2loc=wire2y1loc-0.2+0.00625
			wire2=schCreateWire(cv1 "draw" "full" list(wire2x1loc:wire2y1loc wire2x2loc:wire2y2loc) 0.0625 0.0625 0.0)
			if(net2 schCreateWireLabel(cv1 car(wire2) wire2x2loc-0.03125:wire2y2loc net2 "lowerLeft" "R90" "stick" 0.0625 nil))
			
		else
			printf("%s doesnot exist in the library %s\n" diode lbc7lib)
		)
		
	)
)

procedure(snapToGrid(@optional (instList ggss()))
    let((inst x1 y1 newx1 newy1 tr gridSpace tr)
        gridSpace = 0.0625
        foreach(inst instList
            if(inst~>xy then
                x1=car(inst~>xy)
                y1=cadr(inst~>xy)
                newx1=round_to_grid(x1 gridSpace)
                newy1=round_to_grid(y1 gridSpace)
                tr = list( (newx1-x1):(newy1-y1) "R0" )
                schStretch( list(inst) tr )
                ;inst~>xy = list(x1 y1)
            else
                start_point = car(inst~>points)
                end_point = cadr(inst~>points)
                new_start_point = list_round_to_grid(start_point gridSpace)
                new_end_point = list_round_to_grid(end_point gridSpace)
                inst~>points = list(new_start_point new_end_point)
            )
        )
    )
)

procedure(list_round_to_grid(in_list grid_space)
    let((out_num out_list)
        out_list = list()
        foreach(num in_list
            out_num = round_to_grid(num grid_space)
            out_list = append1(out_list, out_num)
        )
        out_list
    )
)

procedure(round_to_grid(in_num grid_space)
    let((out_num)
        out_num = floor(in_num/grid_space) * grid_space
    )
)

procedure(snapValueToGrid(inValue)
    let((gridSpace newValue)
        gridSpace = 0.0625
        newValue = floor(inValue/gridSpace)*gridSpace
    )
)

procedure(movePinLabels(@optional (instList ggss()))
	let((inst x1 y1 newx1 newy1 tr gridSpace tr)
		gridSpace = 0.0625
		foreach(inst instList
			x1=car(inst~>xy)
			y1=cadr(inst~>xy)
			newx1=floor(x1/gridSpace)*gridSpace
			newy1=floor(y1/gridSpace)*gridSpace
			newx1=newx1+0.25+0.0625
			newy1=newy1+0.0625
			tr = list( (newx1-x1):(newy1-y1) "R0" )
			schStretch( list(inst) tr )
			;inst~>xy = list(x1 y1)
		)
	)
)
procedure(printTCL()
	let((ofIO tclDir)
		tclDir=strcat(pwd() "/tcl")
		unless(isDir(tclDir)
			createDir(tclDir)
		)
		ofIO=outfile(strcat("tcl/" dgcv()~>cellName ".tcl") "w")
		fprintf(ofIO "probe -create %s -domain digital  -depth all\n" dgcv()~>cellName)
		close(ofIO)
	)
)

procedure(COCELL()
	hiRegTimer("setFORMCSS()" 2)
	dssCoCellMCB()
)
procedure(CICELL()
	hiRegTimer("setFORMCSS('dsscCiCellForm)" 10)
	dssCiCMCB()
)

procedure(setFORMCSS()
	hiiSetCurrentForm('dssCoCellForm)
	if(css() then
		hiGetCurrentForm()->cellName->value=css()~>cellName
		hiGetCurrentForm()->unify->value= t
	)
)

procedure(addLib(libname)
	let((ofile)
	;printf("DEFINE %s /home/%s/proj/%s_OA_DS_Latest/cds/%s"	libname whoami() libname libname)))
	
	ofile=outfile("cds.lib","a")
	printf("DEFINE %s /projects/jkleine/vis25e3_oa/%s"	libname libname)
	unless(memq(libname ddGetLibList()~>name) fprintf(ofile,"DEFINE %s /projects/jkleine/vis25e3_oa/%s\n",libname libname))
	close(ofile)
	)
)

procedure(print_tcl(@optional (cv dgcv()))
    let((probe_statement net net_path)
        probe_statement = "probe -create -emptyok -database ams_database"
        foreach(net cv~>nets
            unless(or(rexMatchp("," net~>name) rexMatchp("^<" net~>name) rexMatchp("!" net~>name))
                net_path = strcat(get_cell_hier(1) "." net~>name)
                rexCompile("<")
                net_path = rexReplace(net_path "[" 0)
                rexCompile(">")
                net_path = rexReplace(net_path "]" 0)
                printf("%s %s\n", probe_statement, net_path)
            )
        )
    )
)


procedure(addgnds(@optional (cv1 dgcv())(pinList nil))
    let((gndCell vpwlCell vdcCell i x1 x2 y1 y2 xmax ymax
        xmin ymin xref yref inst1 pinDir noConnCell wire1 wire2
        resCell offset inst instTermList i curLib xa xb ya yb xref1 xref2 yref1 yref2 
        ter x1 y1 dir rotation conCell xf yf lxloc lyloc conRot lRot mywire newTermName
        wire1x0 wire1y0 wire1width toHiCell toLoCell gndList infoList source_net_list source_cell pin_dc_value 
        xloc yloc allNets vsup vgnd fromIn idcCell ipwlCell inst_name)

        offset=1.0    ;line length
        curLib=cv1~>libName
        gndCell=dbOpenCellViewByType( "analogLib" "gnd" "symbol"  "" "r")
        ipwlCell = dbOpenCellViewByType( "analogLib" "ipwl" "symbol"  "" "r")
        idcCell = dbOpenCellViewByType( "analogLib" "idc" "symbol"  "" "r")
        vpwlCell = dbOpenCellViewByType( "analogLib" "vpwl" "symbol"  "" "r")
        vdcCell = dbOpenCellViewByType( "analogLib" "vdc" "symbol"  "" "r")
        ipCell = dbOpenCellViewByType( "basic" "ipin" "symbol" "" "r")
        noConnCell=dbOpenCellViewByType( "basic" "noConn" "symbol"  "" "r")
        ;toCell = dbOpenCellViewByType( "msl290_lbc7_iso_2pin" "TO020_7V" "symbol"  "" "r")
        toHiCell = dbOpenCellViewByType( "vis25e3_DigWithSup5V_10V_iso" "tiehi5V" "symbol"  "" "r")
        toLoCell = dbOpenCellViewByType( "vis25e3_DigWithSup5V_10V_iso" "tielo5V" "symbol"  "" "r")
        resCell = dbOpenCellViewByType( "analogLib" "res" "symbol"  "" "r")
        i = 0
        foreach(inst cv1~>instances
            x1 = caar(inst~>bBox)
            x2 = caadr(inst~>bBox)
            y1 = cadar(inst~>bBox)
            y2 = cadadr(inst~>bBox)
            if(i==0 then
                xmax=x2
                xmin=x1
                ymax=y2
                ymin=y1
            else
                if(x2>xmax xmax = x2)
                if(x1<xmin xmin = x1)
                if(y2>ymax ymax = y2)
                if(y1<ymin ymin = y1)
            );if
            i=i+1
        );foreach        
        foreach(inst cv1~>instances
            i=0
            if(inst~>libName==curLib then
                addNetsNOCONN(inst cv1)
            )
        )        ;only add wires if that's the current lib
        xref=ceiling(xmax+1)
        yref=ceiling(ymax/2+ymin/2)
        pinDir = "input"
        infoList = list()
        gndList = list()
        fromIn = 0
        if((pinList && listp(pinList)) then
            allNets = pinList
            fromIn = 1
        else
            allNets = find_nets_needs_input(cv1)
        )
        vsup = car(setof(x allNets rexMatchp("vdd$" lc(x)) || rexMatchp("vdd[a-z]" lc(x))))
        unless(vsup vsup =  "VDD")
        vgnd = car(setof(x allNets rexMatchp("vss" lc(x))))
        unless(vgnd vgnd =  "VSS")
        foreach(myNet allNets
            if(not(member(myNet cv1~>terminals~>name)) then
                printf("processing %s\n" myNet)
                cond(
                    (rexMatchp("vss" lc(myNet)) || rexMatchp("sub" lc(myNet))
                        gndList = append1(gndList myNet)
                    )
                    (rexMatchp("vin" lc(myNet))
                                                ;netnames celltype pin_name dcvalue delay tran_time
                        infoList = append1(infoList list(list(myNet vgnd) vpwlCell strcat("V_" myNet) myNet "5u" "20u"))
                    )
                    (rexMatchp("vdd" lc(myNet))
                                                ;netnames celltype pin_name dcvalue delay tran_time
                        infoList = append1(infoList list(list(myNet vgnd) vpwlCell strcat("V_" myNet) vsup "20u" "10u"))
                    )
                    (rexMatchp("vref" lc(myNet))
                                                ;netnames celltype pin_name dcvalue delay tran_time
                        infoList = append1(infoList list(list(myNet vgnd) vpwlCell strcat("V_" myNet) myNet "30u" "10u"))
                    )
                    (rexMatchp("^en" lc(myNet))
                                                ;netnames celltype pin_name dcvalue delay tran_time
                        infoList = append1(infoList list(list(myNet vgnd) vpwlCell strcat("V_" myNet) vsup "30u" "100n"))
                    )
                    ;(fromIn == 1
                    (t
                        if(pin_name_list = pinname_matches_to_number(myNet) then
                            pin_dc_value = convert_pinname_list_to_real_number(pin_name_list)
                            pin_type = car(pin_name_list)
                            if(rexMatchp("^v" pin_type) then
                                source_net_list = list(myNet vgnd)
                                source_cell = vpwlCell
                                inst_name = strcat("V_" myNet)
                            )
                            if(rexMatchp("^i" pin_type) || rexMatchp("^p" pin_type) then
                                source_net_list = list(vsup myNet)
                                source_cell = ipwlCell
                                inst_name = strcat("I_" myNet)
                            )
                            if(rexMatchp("^n" pin_type) then
                                source_net_list = list(myNet vgnd)
                                source_cell = ipwlCell
                                inst_name = strcat("I_" myNet)
                            )
                        else
                            source_net_list = list(myNet vgnd)
                            source_cell = vpwlCell
                            pin_dc_value = vsup
                            inst_name = strcat("V_" myNet)
                        )
                                                ;netnames celltype pin_name dcvalue delay tran_time
                        infoList = append1(infoList list(source_net_list source_cell inst_name pin_dc_value "30u" "100n"))
                    )
                )
            )
        )
        xloc = xref
        yloc = yref
        foreach(gnds gndList
            inst1=placeSet(cv1 ipCell gnds pinDir vdcCell xloc yloc)
            cdfGetInstCDF(inst1)~>vdc~>value = "0"
            xloc = xloc + 0.5
        )
        i = 0
        foreach(pwrs_list infoList
            i = i + 1
            inst1=place_cell_wires(cv1 nthelem(1 pwrs_list) nthelem(3 pwrs_list) nthelem(2 pwrs_list) xloc yloc)
            setPWLValues2(list(list("0" "0") list(nthelem(6 pwrs_list) nthelem(4 pwrs_list))) nthelem(4 pwrs_list) nthelem(5 pwrs_list) inst1)
            xloc = xloc + 0.5
        )
        ;tie cells
        xloc = xref - 0.25
        yloc = yref - 1.75
        tiCells = list(toHiCell toLoCell)
        tiNames = list("ONE" "ZERO")
        i = 0
        foreach(tiCell tiCells 
            i = i + 1
            placeTiCell(cv1 tiCell list(xloc yloc) nthelem(i tiNames) vsup vgnd)
            xloc = xloc + 1
        )
        ;wire2=schCreateWire(cv1 "draw" "full" list(xref:yref-1.5 xref+0.25:yref-1.5) 0.0625 0.0625 0.0)
        ;schCreateWireLabel(cv1 car(wire2) xref+0.0625:(yref-1.5+0.0625) "ZERO" "lowerLeft" "R0" "stick" 0.0625 nil)
        ;schCreateInst(cv1 noConnCell "" xref+0.25:yref-1.5 "R90") 
        ;resistor with noconnet
        xref1 = xref + 2
        yref1 = yref - 1.5
        schCreateInst(cv1 noConnCell "" xref1:yref1 "R270") 
        placeWire(cv1 list(xref1 yref1) 0.5)
        inst1=schCreateInst(cv1 resCell "" xref1+0.5:yref1 "R90") 
        cdfGetInstCDF(inst1)~>r~>value = "10m"
        placeWire(cv1 list(xref1+0.9 yref1) 0.5)
        schCreateInst(cv1 noConnCell "" xref1+1.4:yref1 "R90") 

        ;empty no connect with a wire
        xref2 = xref + 2
        yref2 = yref - 1.25
        placeWire(cv1 list(xref2 yref2) 1)
        schCreateInst(cv1 noConnCell "" xref2:yref2 "R270") 
        schCreateInst(cv1 noConnCell "" xref2+1:yref2 "R90") 
        schHiCheckAndSave()
        t
    )
)

procedure(find_nets_needs_input(@optional (cv1 dgcv()))
    let((out_nets net1 need_input inst_list term_dir_list term1 term_cell_name
        inst libName )
        out_nets = list()
        foreach(net1 cv1~>nets
            need_input = 1
            inst_list = list()
            term_dir_list = list()
            if(rexMatchp("^net" net1~>name) need_input = 0)
            foreach(term1 net1~>instTerms
                term_cell_name = term1~>inst~>cellName
                unless(term_cell_name == "noConn"
                    inst_list = append1(inst_list term1~>inst)
                    term_dir_list = append1(term_dir_list term1~>direction)
                )
                foreach(inst inst_list
                    if(inst~>libName == "analogLib" need_input = 0)
                )
                if(member("output" term_dir_list) need_input = 0)
            )
            if(need_input == 1 out_nets = append1(out_nets net1~>name))
        )
        out_nets
    )
)

procedure(pinname_matches_to_number(pin_name)
    let((match_list)
        rexCompile("_")
        out_pin = rexReplace(pin_name "" 0)
        rexCompile("^\\([vipn]+\\)\\([0-9]*\\)\\(p*\\)\\([0-9]*\\)\\([munp]*\\)")
        match_list = list()
        if(rexExecute(lc(out_pin)) then
           match_list = list(rexSubstitute("\\1") rexSubstitute("\\2") rexSubstitute("\\3") rexSubstitute("\\4") rexSubstitute("\\5"))
           if(nthelem(2 match_list) == "" && nthelem(4 match_list) == ""  nil match_list)
        else
            nil
        )
    )
)

procedure(convert_pinname_list_to_real_number(in_list)
    let((out_num first_number point second_number unit)
        if(listp(in_list) then
            first_number = nthelem(2 in_list)
            point = if(rexMatchp("p" nthelem(3 in_list)) "." "")
            second_number = nthelem(4 in_list)
            unit = nthelem(5 in_list)
            out_num = strcat(first_number point second_number unit)
            out_num
        else
            nil
        )
    )
)

procedure(addNetsNOCONN(@optional (inst css()) (cv1 dgcv()))
    let((instTermList i curLib xa xb ya yb xref1 xref2 yref1 yref2 instTermbBox inst1
        ter x1 y1 dir rotation conCell xf yf lxloc lyloc conRot lRot mywire newTermName instNameTable instName j input_pins sorted_term_list gnd_pin_list vdd_pin_list noConnCell selBox x ibox allInPins)
        noConnCell=dbOpenCellViewByType( "basic" "noConn" "symbol"  "" "r")
        instNameTable = makeTable("Instances Name Table")
        foreach(inst1 cv1~>instances
            instNameTable[inst1~>name]=1
        )
        instTermList = inst~>instTerms
        i=0
        allInPins = list("VDD" "VSS")
        if(listp(instTermList) then    
             ;foreach(ter instTermList
            ;;; need to get the origin for the instPins
                ;instTermbBox = dbTransformBBox(car(ter~>term~>pins~>fig~>bBox) inst~>transform )
                ;xa = caar(instTermbBox)
                ;xb = caadr(instTermbBox)
                ;ya = cadar(instTermbBox)
                ;yb = cadadr(instTermbBox)
                ;if(i==0 then
                    ;xref1=xa
                    ;xref2=xb
                    ;yref1=ya
                    ;yref2=yb
                ;else
                    ;if(xa<=xref1 xref1=xa)
                    ;if(xb>=xref2 xref2=xb)
                    ;if(ya<=yref1 yref1=ya)
                    ;if(yb>=yref2 yref2=yb)                    
                ;)
                ;i=i+1
            ;);foreach    finding the edge of each pin
            selBox = setof(x inst~>master~>shapes x~>lpp == '("instance" "drawing"))
            ibox = geTransformUserBBox(car(selBox)~>bBox inst~>transform)
            xref1 = leftEdge(ibox) + 0.05    ;incase the pin is offgrid
            xref2 = rightEdge(ibox) - 0.05    ;incase the pin is offgrid
            yref1 = bottomEdge(ibox) + 0.05    ;incase the pin is offgrid
            yref2 = topEdge(ibox) - 0.05    ;incase the pin is offgrid
            sorted_term_list = sortTermByName(instTermList)
            gnd_pin_list = list("VSS")
            vdd_pin_list = list("VDD")
            foreach(ter sorted_term_list
                if(rexMatchp("vdd" lc(ter~>name)) then
                    vdd_pin_list = append1(vdd_pin_list ter~>name)
                )
                if(rexMatchp("vss" lc(ter~>name)) || rexMatchp("sub" lc(ter~>name)) then
                    gnd_pin_list = append1(gnd_pin_list ter~>name)
                )
            )
            foreach(ter sorted_term_list
            ;; need to get the origin for the instPins
                instTermbBox = dbTransformBBox( car(ter~>term~>pins~>fig~>bBox) inst~>transform )
                xa = caar(instTermbBox)
                xb = caadr(instTermbBox)
                ya = cadar(instTermbBox)
                yb = cadadr(instTermbBox)
                x1 = (xa + xb)/2
                y1 = (ya + yb)/2
                dir = nil
                rotation = nil
                case(ter~>direction
                    ("input"
                        conCell = nil
                        allInPins = append1(allInPins ter~>name)
                    )
                    ("output"
                        conCell = noConnCell
        
                    )
                     ("inputOutput"
                        conCell = noConnCell
                        allInPins = append1(allInPins ter~>name)
                    )
                    (t
                        conCell = nil
                    )
                );case terminal directoins
                ;printf("\n%s: x=%f y=%f" ter~>name xCoord(ter~>xy) yCoord(ter~>xy))
                offset=1.0 ; linewidth
                cond(
                    (xa<xref1 ;left pins
                        xf = x1 - offset
                        yf = y1
                        lxloc =xf +0.05  ;the label x loc
                        lyloc = yf+0.05 ;the label y loc
                        conRot = "R270"
                        lRot = "R0"
                    )
                    (xb>xref2 ;right pins
                        xf= x1 + offset
                        yf = y1
                        lxloc = x1 + 0.05  ;the label x loc
                        lyloc = y1 + 0.05 ;the label y loc
                        lRot = "R0"
                        conRot = "R90"
                    )
                    (ya<yref1 ;bottom pins
                        xf= x1 
                        yf = y1 - offset
                        lxloc =xf-0.05   ;the label x loc
                        lyloc = yf +0.05 ;the label y loc
                        lRot = "R90"
                        conRot = "R0"
                    )
                    (yb>yref2 ;top pins
                        xf= x1 
                        yf = y1 + offset
                        lxloc =x1-0.05   ;the label x loc
                        lyloc = y1+0.05;the label y loc
                        lRot = "R90"
                        conRot = "R180"
                    )
                    (t ;all other conditions
                        xf= x1 + offset
                        yf = y1
                        lxloc =x1   ;the label x loc
                        lyloc = y1+0.05 ;the label y loc
                        lRot = "R0"
                        conRot = "R90"
                    ); 
                )
                unless(ter~>net~>figs
                    mywire = schCreateWire(cv1 "draw" "full" list(xf:yf x1:y1 ) 0.0625 0.0625 0.0)
                    newTermName = if(member(ter~>name gnd_pin_list) car(gnd_pin_list) if(member(ter~>name vdd_pin_list) car(vdd_pin_list) ter~>name))
                    schCreateWireLabel(cv1 car(mywire) lxloc:lyloc newTermName "lowerLeft" lRot "stick" 0.0625 nil)
                    instName=strcat("noConn_" newTermName)
                    j=1
                    while(instNameTable[instName]==1
                        instName=strcat("noConn" sprintf(nil "%d" j) "_" newTermName)
                        j=j+1
                    )
                    if(conCell schCreateInst(cv1 conCell instName xf:yf conRot))
                )
            );for each terminal
        )    ;listp
        schHiCheckAndSave()
        input_pins = list("VDD" "VSS")
        ;remove all the gnd/vss pins
        foreach(pin allInPins
            unless(member(pin gnd_pin_list) || member(pin vdd_pin_list)
                input_pins = append1(input_pins, pin)
            )
        )
        input_pins
    )
)

procedure(sortTermByName(termList) ;of term objects..
    let((sortedList termTable term)
        sortedList=list()
        if(listp(termList) then
            termTable=makeTable("Terminal list")
            foreach(term termList
                termTable[term~>name] = term
            )
            foreach(termName sort(termTable->? 'alphalessp)
                sortedList=append1(sortedList,termTable[termName])
            )
        )
        if(length(sortedList)==0 termList sortedList)
    )
)

procedure(place_cell_wires(cv1 pin_name_list inst_name srcCell xloc yloc)
	let((myinst)
	    myinst = schCreateInst(cv1 srcCell getNewName(inst_name cv1~>instances~>name) xloc:yloc "R0") 
	    ;schCreatePin(cv1 pinCell pinName pinDir nil xloc-0.0625:yloc+0.125 "R0")
	    ;schCreateInst(cv1 gndCell "" xloc:(yloc-0.5) "R0") 
            create_wire_with_label(cv1 car(pin_name_list) 0.25 list(xloc yloc) "R90")
            create_wire_with_label(cv1 cadr(pin_name_list) 0.25 list(xloc yloc - 0.625) "R90")
            myinst
	)
)

procedure(create_wire_with_label(cv1 wire_name wire_length wire_original wire_rotation @optional (wire_width 0.0))
    let((mywire1 x1 y1 x2 y2 lrot lx ly)
        case(wire_rotation
            ("R90"
                x1 = car(wire_original)
                y1 = cadr(wire_original)
                x2 = x1
                y2 = y1 + wire_length
                lrot = "R90"
                lx = x1
                ly = y1
            )
            ("R180"
                x1 = car(wire_original)
                y1 = cadr(wire_original)
                x2 = x1 - wire_length
                y2 = y1
                lrot = "R0"
                lx = x2
                ly = y1
            )
            ("R270"
                x1 = car(wire_original)
                y1 = cadr(wire_original)
                x2 = x1
                y2 = y1 - wire_length
                lrot = "R270"
                lx = x1
                ly = y2
            )
            (t
                x1 = car(wire_original)
                y1 = cadr(wire_original)
                x2 = x1 + wire_length
                y2 = y1
                lrot = "R0"
                lx = x1
                ly = y1
            )
        )
        mywire1 = schCreateWire(cv1 "draw" "full" list(x1:y1 x2:y2) 0.0625 0.0625 wire_width)
        schCreateWireLabel(cv1 car(mywire1) lx:ly wire_name "lowerLeft" lrot "stick" 0.0625 nil)
        mywire1
    )
)

procedure(placeSet(cv1 pinCell pinName pinDir srcCell xloc yloc)
	let((myinst gndCell)
    		gndCell=dbOpenCellViewByType( "analogLib" "gnd" "symbol"  "" "r")
		myinst = schCreateInst(cv1 srcCell getNewName(strcat("V_" pinName) cv1~>instances~>name) xloc:yloc "R0") 
		schCreatePin(cv1 pinCell pinName pinDir nil xloc-0.0625:yloc+0.125 "R0")
		schCreateInst(cv1 gndCell "" xloc:(yloc-0.5) "R0") 
	        schCreateWire(cv1 "draw" "full" list(xloc:(yloc-0.5+0.125) xloc:(yloc-0.5)) 0.0625 0.0625 0.0)
	        schCreateWire(cv1 "draw" "full" list(xloc:yloc xloc:yloc+0.125) 0.0625 0.0625 0.0)
	        schCreateWire(cv1 "draw" "full" list(xloc-0.125:yloc+0.125 xloc:yloc+0.125) 0.0625 0.0625 0.0)
		myinst
	)
)
procedure(setPWLValues2(valuesList vdcValue delayValue @optional (inst css()))
	let((listLen ipair valuePair strIpair tpair vpair tvalue vvalue param)
		if(listp(valuesList) listLen =length(valuesList) error("The input parameter list is not a List.\n"))
		if(cdfGetInstCDF(inst)~>vdc~>value then
		    cdfGetInstCDF(inst)~>vdc~>value = vdcValue
                    pair_surfix = "v"
                else
		    cdfGetInstCDF(inst)~>idc~>value = vdcValue
                    pair_surfix = "i"
                )
		cdfGetInstCDF(inst)~>tvpairs~>value = listLen
		cdfGetInstCDF(inst)~>delay~>value = delayValue
		cdfGetInstCDF(inst)~>td~>value = delayValue
		ipair =0
		foreach(valuePair valuesList
			ipair=ipair+1
			strIpair=sprintf(nil "%d" ipair)
			tpair=strcat("t" strIpair)
			vpair=strcat(pair_surfix strIpair)
			if(listp(valuePair) then
				tvalue=car(valuePair)
				vvalue=cadr(valuePair)
				foreach(param cdfGetInstCDF(inst)~>parameters 
					if(param~>name==tpair param~>value = tvalue)
					if(param~>name==vpair param~>value = vvalue)
				)

			else
				error("%d'th element is  not a value pair.\n" ipair)
			)
			
		)
	)
)

procedure(placeTiCell(cv1 tiCell origXYList wireName vsup vgnd)
	let((instx0 insty0 wire1x0 wire1y0 wire1width wireNameReal)
		instx0=car(origXYList)
		insty0=cadr(origXYList)
		schCreateInst(cv1 tiCell "" list(instx0 insty0) "R0") 
		wire1x0=instx0+0.25
		wire1y0=insty0+0.125
		wire1width=0.25	
                wireNameReal = getNewName(wireName cv1~>nets~>name)
	        placeWire(cv1 list(wire1x0 wire1y0) wire1width "H" wireNameReal)
	        placeWire(cv1 list(wire1x0-0.125-0.0625 wire1y0+0.125) wire1width "V" vsup)
	        placeWire(cv1 list(wire1x0-0.125-0.0625 wire1y0-0.125-wire1width) wire1width "V" vgnd)
		schCreateInst(cv1 noConnCell "" (wire1x0+wire1width):wire1y0 "R90") 
	)
)

procedure(getNewName(oldName nameList)
    let((newName i)
        newName = oldName
        i = 0
        while(member(newName nameList)
            i = i + 1
            newName = sprintf(nil "%s%0d" oldName i)
        )
        newName
    )
)

procedure(placeWire(cv1 origXYList @optional (wireLength 0.25) (wireDirection "H") (wireName nil))
	let((wire1x0 wire1y0 wire1x1 wire1y1 wireLabelx  wireLabely wireRotation wire1)
		wire1x0=car(origXYList)
		wire1y0=cadr(origXYList)
		case(wireDirection
			("V"
				wire1x1=wire1x0
				wire1y1=wire1y0+wireLength
				wireLabelx=wire1x0-0.0625
				wireLabely=wire1y0+0.0625
				wireRotation="R90"
			)
			(t
				wire1x1=wire1x0+wireLength
				wire1y1=wire1y0
				wireLabelx=wire1x0+0.0625
				wireLabely=wire1y0+0.0625
				wireRotation="R0"
			)
		
		)
		wire1=schCreateWire(cv1 "draw" "full" list(wire1x0:wire1y0 wire1x1:wire1y1) 0.0625 0.0625 0.0)
		if(wireName schCreateWireLabel(cv1 car(wire1) wireLabelx:wireLabely wireName "lowerLeft" wireRotation "stick" 0.0625 nil))
		wire1
	)
)

procedure(gotoPsfDir()
	let((psf_dir shcmd)
        psf_dir=asiGetPsfDir(asiGetCurrentSession())
        if(isDir(psf_dir) then
            shcmd=sprintf(nil "cd %s" psf_dir)
        else
            shcmd=sprintf(nil "cd %s" pwd())
        )
        shcmd=sprintf(nil "%s; konsole  -hold -e bash --rcfile ~/.bashrc &" shcmd)
        system(shcmd)
	)
)

procedure(psfDir()
	let((psfDir1)
		;psfDir1=asiGetPsfDir(asiGetCurrentSession())
		psfDir1=strcat(asiGetCurrentSession()->data->asiResultsDir "/psf")
        if(isDir(psfDir1) then
		    printf("psf dir is \n%s",psfDir1)
		    psfDir1
        else
            error("psf dir doesnot exitst yet..")
        )
	)
)

procedure(add_views(args)
    let((simMenu slider view_netlist view_netlist_log)
        ;simMenu = car(setof(menu hiGetBannerMenus(hiGetCurrentWindow()) rexMatchp("^sevSimulationMenu" menu )))
        simMenu = car(setof(menu hiGetBannerMenus(hiGetCurrentWindow()~>sevSession~>window) rexMatchp("^sevSimulationMenu" menu)))
        slider=eval(simMenu)->Netlist
        menu_list = gen_menu_items()
        view_netlist=car(menu_list)
        hiInsertMenuItem(slider->hiSubMenu view_netlist  length(slider->hiSubMenu->_menuItemList)) 
        slider=eval(simMenu)->OutputLog
        view_irun_log=caddr(menu_list)
        view_netlist_log=cadr(menu_list)
        hiInsertMenuItem(slider->hiSubMenu view_netlist_log  length(slider->hiSubMenu->_menuItemList)) 
        hiInsertMenuItem(slider->hiSubMenu view_irun_log  length(slider->hiSubMenu->_menuItemList)) 
    ) ;let
) ;procedure

procedure(show_my_menu(args)
    let((menu1)
        menu1 = create_my_menu()
        hiInsertBannerMenu(hiGetCurrentWindow()~>sevSession~>window menu1 length(hiGetBannerMenus(hiGetCurrentWindow()~>sevSession~>window)))
        hiInsertBannerMenu(hiGetCurrentWindow() menu1 length(hiGetBannerMenus(hiGetCurrentWindow())))
    )
)

procedure(create_my_menu()
    let((sess menu1)
        if(boundp('new_menu ) then
            menu1 = new_menu
        else
            sess = sevSession(hiGetCurrentWindow())
            menu1 = hiCreatePulldownMenu(
                'new_menu
                "MyMenu"
                gen_menu_items()
            ) ; hiCreatePulldownMenu
        ) ; if
    ) ; let
) ; procedure

procedure(gen_menu_items()
    let((view_netlist view_irun_log view_netlist_log goto_psf_term)
        view_netlist=hiCreateMenuItem( ; list of menu items
            ?name 'view_netlist
            ?itemText "Gvim Netlist"
            ?callback   "viewNetlist()"
        )
        view_irun_log=hiCreateMenuItem( ; list of menu items
            ?name 'view_irunlog
            ?itemText "Gvim Irun Log"
            ?callback   "viewIrun()"
        )
        view_netlist_log=hiCreateMenuItem( ; list of menu items
            ?name 'view_netlist_log
            ?itemText "Gvim Netlister Log"
            ?callback   "viewNetlistLog()"
        )
        view_all_logs=hiCreateMenuItem( ; list of menu items
            ?name 'view_all_logs
            ?itemText "Gvim All Logs"
            ?callback   "viewAllLogs()"
        )
        goto_psf_term=hiCreateMenuItem( ; list of menu items
            ?name 'goto_psf_term
            ?itemText "GoTo PSF Term"
            ?callback "gotoPsfDir()"
        )
        list_menus = list(view_netlist view_netlist_log view_irun_log view_all_logs goto_psf_term)
    )
)

procedure(displayErrBox(inMsg)
    displayBox(inMsg "error")
)

procedure(displayWarnBox(inMsg)
    displayBox(inMsg "warning")
)

procedure(displayBox(inMsg msgType)
    let((errMsgReturn )
        errMsgReturn = hiDisplayAppDBox(?name 'errMsgButton
                         ?dboxBanner msgType
                         ?dboxText inMsg
                         ?dialogType hicMessageDialog
                         ?buttonLayout 'Close
                        )
        if(msgType == "error" error(inMsg) warn(inMsg))
    )
)

procedure(view_file(in_files)
    let((view_cmd)
        file_str = "gvim "
        non_file_str = ""
        foreach(in_file in_files
            if(isFile(in_file) then
                file_str = strcat(file_str in_file " ")
            else
                non_file_str = strcat(non_file_str in_file " ")
            )
        )
        if(file_str != "gvim " then
            system(file_str)
        )
        if(non_file_str != "" then
            ;displayWarnBox(strcat(non_file_str " not viewablefile."))
            printf(strcat(non_file_str " not viewablefile."))
        )
    )
)

procedure(viewNetlist()
    let((psfdir netlist_file1 netlist_file2 viewLog)
        psfdir = asiGetCurrentSession()->data->netlistDir
        netlist_file1 = strcat(psfdir "/netlist/netlist.vams")
        netlist_file2 = strcat(psfdir "/input.scs")
        view_file(list(netlist_file1 netlist_file2))
    )
)
procedure(viewNetlistLog()
    let((psfdir netlistLog viewLog compileLog)
        ;psfdir = psfDir()
        psfdir = asiGetCurrentSession()->data->netlistDir
        netlistLog = strcat(psfdir "/netlister.log")
        compileLog = strcat(psfdir "/textDesignCompilation.log")
        view_file(list(netlistLog compileLog))
    )
)

procedure(viewIrun()
    let((psfdir irunLog xrunLog xrunLogs runLogs viewLog spectreLog)
        psfdir = psfDir()
        irunLog = strcat(psfdir "/irun.log")
        xrunLog = strcat(psfdir "/xrun.log")
        spectreLog = strcat(psfdir "/spectre.out")
        xrunlogs = list(irunLog xrunLog spectreLog)
        runlogs = list()
        foreach(runlog xrunlogs
            if(isFile(runlog) then
                runlogs = append1(runlogs runlog)
            )
        )
        if(length(runlogs) >= 1 view_file(runlogs))
    )
)
procedure(viewAllLogs()
        let((psfdir netlist_dir all_log_list)
            psfdir = psfDir()
            netlist_dir = asiGetCurrentSession()->data->netlistDir
            all_log_list = list(strcat(psfdir "/xrun.log") strcat(psfdir "/irun.log") strcat(netlist_dir "/netlist.vams") strcat(netlist_dir "/netlister.log"))
            view_file(all_log_list)
        )
)

;; find the design variables
; awk '/DESIGN_VARIABLES/,/END/{print FILENAME,$0}' */*/*/ams_direct.dat
;/sim/TPS51678_OA_DS/a0282847/Latest/sim/sim_START_STOP_VREF/ams/configAMS/netlist/ihnl


procedure(addCsha(prjName partNum @optional (userPN 1)) ;projName is the alias of the project, fish name, partNum is the part number
	let((projPN projName)
		if(userPN == 1 then
			projPN = upperCase(partNum)
		else
			projPN = upperCase(prjName)
		)
		projName = lowerCase(prjName)
	printf("a %s 'cd ~/proj/%s_OA_DS_Latest;icfb&'\n" projName projPN)
	printf("a %s_folder 'cd ~/proj/%s_OA_DS_Latest'\n" projName projPN)
	printf("a %s_pop 'cd ~/proj/%s_OA_DS_Latest;dssc populate -rec -unify'\n" projName projPN)
	printf("a %s_sim 'cd /home/%s_OA_DS/%s/Latest/sim'\n" projName projPN whoami())
	printf("a %s_sim 'cd /home/%s_OA_DS/%s/Latest/acs/%s'\n" projName projPN whoami() projPN)	
)
)

procedure(whoami()
    let((userName)
        userName = getShellEnvVar("USER")
    )
)

procedure(VIDVout(VID)
	let((vout)
		vout = 0.5+(VID-1)*0.01
		vout	
	)
)

procedure(addPropInst(inst prop1 net1)
    dbCreateProp(inst prop1 "netSet" net1)
)

procedure(removePropInst(inst prop1)
    if(dbGetPropByName(inst prop1) then
        dbDeletePropByName(inst prop1)
    )
)
procedure(addProp(prop1 net1 @optional (instList ggss()))
    let((inst)
        foreach(inst instList 
            removePropInst(inst prop1)
            addPropInst(inst prop1 net1)
        )
    )
)

procedure(addAVDD()
    addProp("VDD" "AVDD")
)
procedure(add_vdd()
    addProp("vdd" "LDO15d")
)

procedure(addAVSS()
    addProp("VSS" "AVSS")
)
procedure(addVSS()
    addProp("AVSS" "VSS")
)

procedure(addBoth( @optional (vdd_field "vdd")(vss_field "vss")(vdd "vdd")(vss "vss"))
    let((propType propName propType1 propName1 inst)
        foreach(inst ggss()
            removePropInst(inst vdd_field)
            addPropInst(inst vdd_field vdd)
            removePropInst(inst vss_field)
            addPropInst(inst vss_field vss)
        )
    )
)

procedure(delBoth()
    let((inst)
        foreach(inst ggss()
            removePropInst(inst "vdd")
            removePropInst(inst "vss")
            removePropInst(inst "VDD")
            removePropInst(inst "VSS")
            removePropInst(inst "powr")
            removePropInst(inst "grnd")
        )
    )
)

procedure(cHost()
	let((hostM curSess)
		if(curSess=sevSession(hiGetCurrentWindow()) then
			curForm = stringToSymbol(strcat("sevSimulatorForm" getSessNum()))
			hiRegTimer("hiiSetCurrentForm(curForm)" 2)
			hiRegTimer("chostsf()",4)
			hiRegTimer("hiFormDone(hiGetCurrentForm())",10)
			sevChooseSimulator(curSess)
		else
			hostM=envGetVal("asimenv.startup" "hostMode")
			if(hostM == "distributed" then 
				envSetVal("asimenv.startup" "hostMode" 'string "local") 
				printf("Changing from distributed to local.\n")
			else	
				envSetVal("asimenv.startup" "hostMode" 'string "distributed")
				printf("Changing from %s to distributed.\n" hostM)
			)
		)
	)
)

procedure(chostsf()
	let((hostM)
		hostM = hiGetCurrentForm()->hostMode->value
		if(hostM == "distributed" then 
			;hiRegTimer("hiGetCurrentForm()->hostMode->value=\"local\"" 5)
			hiGetCurrentForm()->hostMode->value="local"
			printf("Changing from distributed to local.\n")
		else
			hiGetCurrentForm()->hostMode->value="distributed"
			hiGetCurrentForm()->emailNotify->value= t
			;hiRegTimer("hiGetCurrentForm()->hostMode->value=\"distributed\"" 5)
			;hiRegTimer("hiGetCurrentForm()->emailNotify->value= t" 5)
			printf("Changing from %s to distributed.\n" hostM)
		)
	)
)

procedure(getSessNum()
	let((curSess sessStr sessNum)
		curSess = sevSession(hiGetCurrentWindow())
		sessStr = symbolToString(curSess)
		rexCompile("sevSession")
		sessNum = rexReplace(sessStr,"",0)
		sessNum
	)
)
procedure(getAMSNum()
	let((curSess sessStr sessNum)
		curSess = asiGetCurrentSession()~>name
		sessStr = symbolToString(curSess)
		rexCompile("ams")
		sessNum = rexReplace(sessStr,"",0)
		sessNum
	)
)

procedure(chost()
	cHost()
)

procedure(cMode()
	let((runMode curSess detForm)
		if(curSess=sevSession(hiGetCurrentWindow()) then
			hiRegTimer("cmodesf()",2)
			hiRegTimer("hiFormDone(hiGetCurrentForm())",10)
			sevSetRunOption(curSess)
		else
			runMode=envGetVal("ams.envOpts" "runOpts")
			mode1 = "Interactive (debugger)"
			mode2 = "Batch (normal)"
			if(runMode == mode1 then 
				newMode = mode2
				printf("run mode is changing from %s to %s\n" runMode newMode)
				envSetVal("ams.envOpts" "runOpts" 'string newMode)
				asiSetEnvOptionVal(asiGetCurrentSession() 'runOpts newMode)

			else	
				newMode = mode1
				printf("run mode is changing from %s to %s\n" runMode newMode)
				envSetVal("ams.envOpts" "runOpts" 'string newMode)
				asiSetEnvOptionVal(asiGetCurrentSession() 'runOpts newMode)
			)
		)
	)
)

procedure(cmodesf()
	let((hostM newHost oldHost)
		if(boundp(stringToSymbol(strcat("runOptsForm" getAMSNum())))
			detForm = stringToSymbol(strcat("runOptsForm" getAMSNum()))
			detForm = stringToSymbol("runOptsForm")
		)
		hiiSetCurrentForm(detForm)
		hostM = hiGetCurrentForm()->runOpts->value
		if(hostM == "Interactive (debugger)" then 
			oldHost = "Interactive (debugger)"
			newHost = "Batch (normal)"
			hiRegTimer("hiGetCurrentForm()->runOpts->value=\"Batch (normal)\"" 3)
			;hiRegTimer("newHost = hiGetCurrentForm()->runOpts->value" 4)
			;hiRegTimer("printf(\"Changing from %s to %s.\\n\", oldHost,newHost)" 5)
			printf("Changingg from %s to %s.\n",oldHost,newHost)
		else
			oldHost = "Batch (normal)"
			newHost = "Interactive (debugger)"
			hiRegTimer("hiGetCurrentForm()->runOpts->value=\"Interactive (debugger)\"" 3)
			;hiRegTimer("newHost = hiGetCurrentForm()->runOpts->value" 4)
			;hiRegTimer("printf(\"Changing from %s to %s.\\n\", oldHost,newHost)" 5)
			printf("Changing from %s to %s.\n", oldHost,newHost)
		)
	)
)
procedure(cmode()
	cMode()
)

procedure(printRunmode()
	let((curSess curForm hostM detForm)
		printf("\nDefault host mode is %L and run mode is %L.\n" envGetVal("asimenv.startup" "hostMode") envGetVal("ams.envOpts" "runOpts"))
		if(curSess=sevSession(hiGetCurrentWindow()) then
			hiRegTimer("printSimMode()",2)
			hiRegTimer("printHost()",3)
			hiRegTimer("sevChooseSimulator(curSess)",1)
			sevSetRunOption(curSess)
		)
		
	)
)
procedure(printHost()
	let((curForm hostM)
		curForm = stringToSymbol(strcat("sevSimulatorForm" getSessNum()))
		hiiSetCurrentForm(curForm)
		hostM = hiGetCurrentForm()->hostMode->value
		hiFormDone(hiGetCurrentForm())
		printf("Current host mode is %s\n",hostM)
	)
)

procedure(printSimMode()
	let((detForm hostM)
		if(boundp(stringToSymbol(strcat("runOptsForm" getAMSNum())))
			detForm = stringToSymbol(strcat("runOptsForm" getAMSNum()))
			detForm = stringToSymbol("runOptsForm")
		)
		hiiSetCurrentForm(detForm)
		hostM = hiGetCurrentForm()->runOpts->value
		hiFormDone(hiGetCurrentForm())
		printf("Current Simulation running mode is %s\n",hostM)
	)
)


procedure(getJobs(@optional (todayCond nil) (secondCond nil))
	let((jobList jobIndex jobDir1 psfDir psfItems jobDir2 i jobDirs curFolderName curFolder farmFile farmList farmIndex curFarmName jobDir3 jobDir5\
			jobDir4 configName thisCond farmSubList subFarmIndex newCond allJobs psfOldItems psfItem newItem)
		jobDir1 = strcat(asiGetPsfDir(asiGetCurrentSession()) "/../distributed")  ;default distributed job dir
		jobDirs=list(jobDir1)
		
		psfDir = asiGetPsfDir(asiGetCurrentSession())
		psfItems=parseString(psfDir,"/")
		configName = nthelem(length(psfItems)-1 psfItems)
		jobDir2=""
		jobDir5=""
		for(i 1 length(psfItems)-1
			curItem=nthelem(i psfItems)
			jobDir2=strcat(jobDir2 "/" curItem)
			newItem=curItem
			
			when(i==2 
				if(rexMatchp("_OA_DS$" curItem) then
					rexCompile("_OA_DS$")
					newItem=rexReplace(curItem,"",0)
				else
					newItem=strcat(curItem "_OA_DS")
				)
			)
			jobDir5=strcat(jobDir5 "/" newItem)
		)
		jobDirs = append1(jobDirs strcat(jobDir5 "/distributed"))
		if(jobDir2==jobDir5 then farmJobDirList=list(jobDir2) else farmJobDirList=list(jobDir2 jobDir5))
		foreach(jobDir2 farmJobDirList
			if(isDir(jobDir2) then
				farmList = getDirFiles(jobDir2)
				for(farmIndex 3 length(farmList)
					curFarmName=nthelem(farmIndex farmList)
					if(todayCond thisCond=rexMatchp(todayCond curFarmName) thisCond=t)
					if(and(rexMatchp(configName curFarmName) thisCond) then
						jobDir3=strcat(jobDir2 "/" curFarmName)
						jobDirs = append1(jobDirs jobDir3)
					)
					if(and(rexMatchp("farm" curFarmName) thisCond) then
						jobDir3=strcat(jobDir2 "/" curFarmName)
						farmSubList=getDirFiles(jobDir3)
						for(subFarmIndex 3 length(farmSubList)
							jobDir4=strcat(jobDir3 "/" nthelem(subFarmIndex farmSubList))
							if(secondCond newCond=rexMatchp(secondCond nthelem(subFarmIndex farmSubList)) newCond = t)
							if(newCond jobDirs = append1(jobDirs jobDir4))
						)
					)
				)
			)
		)
		
		printf("**********************************************************************************************\n")
		printf("----------------------------------------------------------------------------------------------------\n")
		printf("Job summary for local simulation job %s\n" configName)
		printf("Local job is at \n%s &\n" psfDir)
		if(isFile(strcat(psfDir "/psf.trn")) then
		   	printf("system(\"simvision %s &\")\n"  psfDir)
		   	printf("psf.trn\t")
		   	jobInfo=getFileInfo(strcat(psfDir "/psf.trn"))
		else
		   	printf("No waveform file psf.trn in %s.\n" psfDir)
		)
		
		printf("**********************************************************************************************\n")
		printf("Job summary for distributed simulation jobs %s\n" configName)
		
		foreach(jobDir jobDirs
		  if(isDir(jobDir) then
		    jobList = getDirFiles(jobDir)
		    for(jobIndex 3 length(jobList)
		   	curFolderName = nthelem(jobIndex jobList)
			curFolder=strcat(jobDir "/" curFolderName)
			if(todayCond thisCond=rexMatchp(todayCond curFolderName) thisCond=t)
			thisCond=and(rexMatchp("job" curFolderName) thisCond)
			if(and(isDir(curFolder) or(thisCond rexMatchp("Job" curFolderName))) then
			   job=strcat(curFolder "/psf")
			   printf("%s is at \n%s &\n" nthelem(jobIndex jobList) job)
			   if(isFile(strcat(job "/psf.trn")) then
			   	printf("system(\"simvision %s &\")\n"  job)
			   	printf("psf.trn\t")
		   	   	jobInfo=getFileInfo(strcat(job "/psf.trn"))
				allJobs=append1(allJobs strcat(job))
			   else
			   	printf("No waveform file psf.trn in %s.\n" nthelem(jobIndex jobList))
			   )
			printf("**********************************************************************************************\n")
			)
		    )
		 )
	      )
	      printf("----------------------------------------------------------------------------------------------------\n")
	      printf("Here is a list of all the jobs in this simulation bench:\n")
	      foreach(job allJobs printf("%s\n" job))
	      printf("**********************************************************************************************\n")
	      allJobs
	)
)

procedure(checkerLOG(psfFolder)
	let((logFile1 logFile2 logFile INFile oLogFile OFile line)
		if(isDir(psfFolder) then
			logFile2 = strcat(psfFolder "/ncsim.log")
			logFile1 = strcat(psfFolder "/simulation.log")

			oLogFile=strcat(psfFolder "/checkerOut.log")
			OFile=outfile(oLogFile,"w")
			foreach(logFile list(logFile1 logFile2)
				if(isFile(logFile) then
					printf("%s is a valid file.\n" logFile)
					fprintf(OFile "%s\n" logFile)
					INFile=infile(logFile)
					while(gets(line INFile)
						if(and(rexMatchp("^Checker",line) !rexMatchp("at 0.000us",line)) then 
							fprintf(OFile "%s",line)
							printf("%s",line)
						)
					)
					close(INFile)
				)
			)			
			close(OFile)
			printf("edit(\"%s\")" oLogFile)
			oLogFile
		)
	)
)

procedure(getFileInfo(file)
	let((ipc1 ipc2 fileSize fileDate fileInfoList fileInfoList1)
		if(isFile(file) then
			lsFile=strcat("ls -l " file)
			ipc1=ipcBeginProcess(lsFile)
			ipcWait(ipc1)
			ipc2=ipcReadProcess(ipc1)
			fileInfoList=parseString(ipc2," ")
			fileSize=cdfParseFloatString(nthelem(5 fileInfoList))
			;foreach(fileInfo fileInfoList printf("%s\n" fileInfo))
			fileDate=strcat(nthelem(6 fileInfoList) " " nthelem(7 fileInfoList)  " " nthelem(8 fileInfoList))
			fileInfoList1=list(fileSize fileDate)
			printf("Filesize: %1.3GG.\tDate: %s\n", fileSize/1e9,fileDate)
		else
			printf("%s is not a file.\n",file)
		)
		fileInfoList1	
	)
)


procedure(sortTableByValuesL(inTable)
	let((key key1 sortedKeyList origList elem formatString val)
		if(tablep(inTable) then
			foreach(key inTable origList=append1(origList key))
			while(origList 
				foreach(key origList
					elem=key
					foreach(key1 origList
						when(and(inTable[elem]>inTable[key1] key1 !=key)
							elem=key1
						)					
					)
				)
			origList=remove(elem origList)
			sortedKeyList=append1(sortedKeyList elem)
			)
			foreach(elem sortedKeyList 
				foreach(val list(elem inTable[elem])
					formatString=if(stringp(val) "%s" if(floatp(val) "%1.2e" "%d"))
					printf(strcat(formatString "\t") val)
				)
				printf("\n")
			)		
		)
		sortedKeyList
	)
)

procedure(sortTableByValuesG(inTable)
	let((key key1 sortedKeyList origList elem formatString val)
		if(tablep(inTable) then
			foreach(key inTable origList=append1(origList key))
			while(origList 
				foreach(key origList
					elem=key
					foreach(key1 origList
						when(and(inTable[elem]<inTable[key1] key1 !=key)
							elem=key1
						)					
					)
				)
			origList=remove(elem origList)
			sortedKeyList=append1(sortedKeyList elem)
			)
			foreach(elem sortedKeyList 
				foreach(val list(elem inTable[elem])
					formatString=if(stringp(val) "%s" if(floatp(val) "%1.2e" "%d"))
					printf(strcat(formatString "\t") val)
				)
				printf("\n")
			)		
		)
		sortedKeyList
	)
)

procedure(createPlot(waveList expList @optional (waveLabel "waveform")(waveformTitle "waveform")(xMarkersList list()))
	let((colorList lineStyleList waveformFile waveformFileO waveformFileName xMarker)
		awvCreatePlotWindow()
		displayMode("strip")
		i = 3
		foreach(wave waveList
			i = i + 1
			if(i==10 i=1)
			colorList=append1(colorList strcat("y" sprintf(nil "%d" i)))
			lineStyleList=append1(lineStyleList "Solid")
		)
		awvPlotWaveform(currentWindow() waveList
			?expr expList
			?color colorList
			?lineStyle lineStyleList)
		unless(waveformTitle
			waveformTitle=strcat("waveform" sprintf(nil "%d" random()))
		)
		rexCompile(" ")
		waveformTitle=rexReplace(waveformTitle "" 0)
		waveformFileName=waveformTitle
		waveformFileO=strcat("/home/a0282847/tmp/" waveformTitle ".png")
		i = 1
		waveformFile=waveformFileO
		while(isFile(waveformFile)
			waveformFileName=strcat(waveformTitle sprintf(nil "%d" i))
			waveformFile=strcat("/home/a0282847/tmp/" waveformFileName ".png")
			i = i+1
		)
		addTitle(waveformFileName)
		if(waveLabel then
			waveLabel=strcat(waveLabel "\n" waveformFileName "\n")
		else
			waveLabel=strcat(waveformFileName "\n")
		)
		awvPlaceWindowLabel(currentWindow() list(0.8 0.8) waveLabel nil ?color "y6")
		when(and(listp(xMarkersList) xMarkersList)
			foreach(xMarker xMarkersList if(or(floatp(xMarker) integerp(xMarker)) awvPlaceXMarker(awvGetCurrentWindow() xMarker)))
		)
		hardCopyOptions(?hcOutputFile waveformFile ?hcMakeExactCopy t)
		hardCopy()
		unless(isDir("./scripts")
			sh("mkdir ./scripts")
		)
		shCmd=sprintf(nil "cp %s ./scripts/" waveformFile)
		sh(shCmd)
		waveformFile
	)
)


procedure(extendWire(dir @optional (wirelen 1.0)(insts ggss()))
	let((instTermbBox inst xa xb ya yb xc yc)
		foreach(inst insts
			if(inst~>layerName=="wire" then
				instTermbBox=inst~>points
              	 		xa = caar(instTermbBox)
              			xb = caadr(instTermbBox)
               			ya = cadar(instTermbBox)
               			yb = cadadr(instTermbBox)
				if(or(xa>xb ya>yb) then
					xc=xa
					xa=xb
					xb=xc
					yc=ya
					ya=yb
					yb=yc
				)
			
				case(dir
					("left"
						xa=xb-wirelen
					)
					("right"
						xb=xa+wirelen
					)
					("up"
						yb=ya+wirelen
					)
					("down"
						ya=yb-wirelen
					)
					(t
						xa=xb-wirelen
					)
				)
				inst~>points=list(list(xa ya) list(xb yb))
			)
		)
	)
)

procedure(createSeqSch(benchRep)
	let((curLib seqView schView seqObj schObj seqCV schCV seqFile symObj benchName)
		curLib = "CASALL"
		seqView = "seq"
		schView = "schematic"
		symView = "symbol"
		srcCellName = "simxz_pmbus_PGOOD"
		benchName = strcat("simxz_pmbus_" benchRep)
		srcSym=dbOpenCellViewByType(curLib srcCellName "symbol" "" "r")
		unless((seqObj = ddGetObj(curLib,benchName,seqView)) 
			seqCV = deNewCellView(curLib,benchName,seqView,"text",nil)
		);unless
		if((schObj = ddGetObj(curLib,benchName,schView)) then
			printf("\n%s %s view exist\n" benchName schView)
			schCV = deOpenCellView(curLib,benchName,schView,schView,nil,"a")
		
		else 
			printf("\nview not exist, creating: %s %s\n" benchName schView)
			schCV = deNewCellView(curLib,benchName,schView,schView,nil) ;creating new cell view
		);if
		if((symObj = ddGetObj(curLib,benchName,symView)) then
			printf("\n%s %s view exist, not creating\n" benchName symView)
		
		else 
			printf("\nview not exist, creating: %s %s\n" benchName symView)
			dbCopyCellView(srcSym curLib benchName symView nil nil t)

		);if
		seqFile = strcat("/data/" curLib "_OA_DS/sync/users/" whoami() "/Latest/cds/" curLib "/" benchName "/seq/text.txt")
		edit(seqFile)
	)
)

procedure(copyConfig(dstName)
    let((srcSimCellName dstSimCellName srcName curLib views schView dstSchViewName srcView dstView view srcSimCellSch schCV cv1 instId benchName hierCV )
        srcSimCellName = "simxz_AMS_CASALL_TOP"
        dstSimCellName = srcSimCellName
        srcName = "SCH"
        curLib = "CASALL"
        views = list("config" "ams_state" "schematic")
        dstSchViewName = strcat("schematic_" dstName)
        schView = "schematic"
        foreach(view views
            srcView = strcat(view "_" srcName)
            dstView = strcat(view "_" dstName)
            printf("\nCopy %s %s view to %s %s\n" srcSimCellName srcView dstSimCellName dstView)
            if(view == "schematic" then
                srcSimCellSch=dbOpenCellViewByType(curLib srcSimCellName srcView "" "r")
                if(not(ddGetObj(curLib,dstSimCellName,dstView)) dbCopyCellView(srcSimCellSch curLib dstSimCellName dstView nil nil t))
            else
                CCScopyViewCV(curLib srcSimCellName srcView curLib dstSimCellName dstView)
                ;printf("%s is currentView\n" currentView)
            );if
        );foreach currentView
        schCV = deOpenCellView(curLib,dstSimCellName,dstSchViewName,schView,nil,"a")
        cv1=schCV~>cellView
        foreach(instId cv1~>instances
            when(instId~>name == "I89"
                benchName = strcat("simxz_pmbus_" dstName)
                leReplaceAnyInstMaster(instId curLib benchName nil)
            );when instId~>name = "I89"
        );foreach instId in cv1
        schCheck(cv1)
        dbCheck(cv1)
        dbSave(cv1)
        hiRegTimer("dbClose(cv1)" 1)
        hierCV = hdbOpen(curLib dstSimCellName strcat("config_" dstName) "a")
        hdbSetTopCellViewName(hierCV curLib dstSimCellName dstSchViewName)
        hdbSave(hierCV)
        hdbClose(hierCV)
        CCSOpenSchematic(curLib dstSimCellName strcat("config_" dstName) 2)
    )
)

procedure(lc(name)
	lowerCase(name)
)
procedure(uc(name)
	upperCase(name)
)

procedure(runauto()
	load("runauto.ocn")
)

procedure(runsim()
	asiRunSimulation(asiGetCurrentSession())
)

procedure(setCF()
	hiRegTimer("setCFNow()" 2)
	hiRegTimer("hiFormDone(hiGetCurrentForm())" 10)
	asiHiEditEnvVariables( asiGetAnalysis( asiGetCurrentSession() 'tran ) list( 'options ) nil )

);procedure to set the compression to NO and finalOP to NO

procedure(setCFNow()
	let((curForm)
			curForm = stringToSymbol(strcat("_asii_ams" getAMSNum() "_tran_options_form"))
			hiiSetCurrentForm(curForm)
			hiGetCurrentForm()->page->value=4
			hiGetCurrentForm()->page->page4->scroll4->tran_finalTimeOp->no->value =  t
			hiGetCurrentForm()->page->page4->scroll4->tran_compression->no->value =  t
	)
);procedure to set the compression to NO and finalOP to NO

procedure(saveState(@optional (postName nil))
	let((thisView thisCell simName thisViewList stateName)
		thisView=asiGetTopCellView(asiGetCurrentSession())~>viewName
		thisCell=asiGetTopCellView(asiGetCurrentSession())~>cellName
		simName=asiGetSimName(asiGetCurrentSession())
		if(rexMatchp("_" thisView) then
			thisViewList=parseString(thisView "_")
		else
			thisViewList=parseString(thisCell "_")
		
		)
		stateName=nthelem(length(thisViewList) thisViewList)
		stateName=strcat(simName "_state_" stateName)
		if(postName stateName=strcat(stateName postName))
		hiRegTimer("saveStateNow(stateName)" 2)
		;hiRegTimer("hiFormDone(hiGetCurrentForm())" 10)
		sevSaveState(sevSession(hiGetCurrentWindow()))
	)

);procedure to set the compression to NO and finalOP to NO

procedure(saveStateNow(stateName)
	let((curForm)
			curForm = stringToSymbol(strcat("sevSaveForm" getSessNum()))
			hiiSetCurrentForm(curForm)
			hiGetCurrentForm()->stateName->value=stateName
	)
);procedure to set the savestates

procedure(loadState(@optional (postName nil))
	let((thisView thisCell simName thisViewList stateName)
		thisView=asiGetTopCellView(asiGetCurrentSession())~>viewName
		thisCell=asiGetTopCellView(asiGetCurrentSession())~>cellName
		simName=asiGetSimName(asiGetCurrentSession())
		if(rexMatchp("_" thisView) then
			thisViewList=parseString(thisView "_")
		else
			thisViewList=parseString(thisCell "_")
		
		)
		stateName=nthelem(length(thisViewList) thisViewList)
		stateName=strcat(simName "_state_" stateName)
		if(postName stateName=strcat(stateName postName))
		hiRegTimer("loadStateNow(stateName)" 2)
		hiRegTimer("hiFormDone(hiGetCurrentForm())" 10)
		sevLoadState(sevSession(hiGetCurrentWindow()))
	)
);procedure to set the compression to NO and finalOP to NO

procedure(loadStateNow(stateName)
	let((curForm)
		curForm = stringToSymbol(strcat("sevLoadForm" getSessNum()))
		hiiSetCurrentForm(curForm)
		hiGetCurrentForm()->stateName->value=stateName
		printf("Loading state %s\n" stateName)
	)
);procedure to set the loadstates

procedure(setAPS()
	hiRegTimer("setAPSNow()" 2)
	_asiSetTurboOptions(sevSession(hiGetCurrentWindow()))
)
procedure(setAPSNow()
	let((curForm)
			curForm = stringToSymbol(strcat("_asii_ams" getAMSNum() "_amsTurboOpts_form"))
			hiiSetCurrentForm(curForm)
			hiGetCurrentForm()->uniMode->value= "APS"
			hiGetCurrentForm()->mtOption->value= "Auto"
			hiGetCurrentForm()->preserveOption->value= "All"
	)
	
)

procedure(toggleSnapSpacing()
	let((newSpacing)
		hiRegTimer("newSpacing = toggleSnapSpacingNow()" 1)
		hiRegTimer("schDisplayOptionsForm->snapSpacing->value = newSpacing" 5)
		hiRegTimer("hiFormDone(hiGetCurrentForm())" 15)
		schHiDisplayOptions()
	)
)

procedure(toggleSnapSpacingNow()
	let((curSpacing newValue)
		hiiSetCurrentForm('schDisplayOptionsForm)
		curSpacing = schDisplayOptionsForm->snapSpacing->value
		if(curSpacing != 0.0625 then
			newValue = 0.0625
		else
			newValue = 0.03125
		)
		printf("Current spacing is %f, setting snap spacing to %f\n" curSpacing newValue)
		newValue
	)
)

procedure(setAMS_SDF(spectTemp ncvlogOpts corner)
	let((modelPath modelWPath modelSPath fillerItem modelPaths simulators modelPathsList model0 model1 model2)
		rexCompile("scs")
		modelPath = "$TILIB/$ARTISAN_TIPROCESS/$ARTISAN_PDKVER/models/spec/model.paths.scs"	
		modelWPath=rexReplace(modelPath,"weak.scs",0)
		modelSPath=rexReplace(modelPath,"strong.scs",0)
		fillerItem=" #;"
		model0=modelWPath
		model1=strcat(fillerItem modelPath)
		model2=strcat(fillerItem modelSPath)
		modelPaths=strcat(model0 model1 model2)
                 if(corner == "weak"
                        modelPathsList = list(list(modelWPath) list("#" modelPath) list("#" modelSPath))
                        modelPath = modelWPath
                    else
                        if(corner == "strong"
                            modelPathsList = list(list(modelSPath) list("#" modelPath) list("#" modelWPath))
                            modelPath = modelSPath
                        else
                            modelPathsList = list(list(modelPath) list("#" modelSPath) list("#" modelWPath))
                        )
                )
		if(asiGetCurrentSession()  then
			printf("Setting temperature to be %s\n",spectTemp)
			asiSetTemperature(asiGetCurrentSession() spectTemp)
			printf("Setting modelfiles to be %s\n",modelPath)
			asiSetEnvOptionVal(asiGetCurrentSession() "modelFiles" modelPathsList)
		)
		printf("Please set compiler verilog Opts to be %L\n",ncvlogOpts)
		;envSetVal("ams.compilerOpts" "ncvlogArguments" 'string ncvlogOpts)
		envGetVal("ams.compilerOpts" "ncvlogArguments")
	)
)

procedure(setTIS(spectTemp corner)
	let((modelPath modelWPath modelSPath fillerItem modelPaths spectTemp simulators ncvlogOpts modelPathsList model0 model1 model2)
		modelPath = "$TILIB/$ARTISAN_TIPROCESS/$ARTISAN_PDKVER/models/tis/model.paths"	
		modelWPath=strcat(modelPath,".weak")
		modelSPath=strcat(modelPath,".strong")
		fillerItem="*"
                 if(corner == "weak"
                        modelPathsList = list(list(modelWPath) list(strcat(fillerItem modelPath)) list(strcat(fillerItem modelSPath)))
                        modelPath = modelWPath
                    else
                        if(corner == "strong"
                            modelPathsList = list(list(modelSPath) list(fillerItem modelPath) list(fillerItem modelWPath))
                            modelPath = modelSPath
                        else
                            modelPathsList = list(list(modelPath) list(fillerItem modelSPath) list(fillerItem modelWPath))
                        )
                )
		if(asiGetCurrentSession()  then
			printf("Setting temperature to be %s\n",spectTemp)
			asiSetTemperature(asiGetCurrentSession() spectTemp)
			printf("Setting modelfiles to be %s\n",modelPath)
			asiSetEnvOptionVal(asiGetCurrentSession() "modelFiles" modelPathsList)
		)
	)
)

procedure(setCorner(corner)
    let((simulat status1 state ncvlogOpts curForm thisCorner)
	simulat=asiGetSimName(asiGetCurrentSession())
        if(corner == "strong" then
		status1="Nothing set\n";
		state = "Strong"
		thisCorner="Minimum"
		ncvlogOpts = "-define STRONG -define TI_verilog"
                spectTemp = 125
        else
            if(corner == "weak" then
		status1="Nothing set\n";
		state = "Weak"
		thisCorner="Maximum"
		ncvlogOpts = "-define WEAK -define TI_verilog"
                spectTemp = -40
            else
		status1="Nothing set\n";
		state = "Nom"
		thisCorner="Typical"
		ncvlogOpts = "-define NOM -define TI_verilog"
                spectTemp = 27
            )
        )
	if(or(rexMatchp("ams" simulat) rexMatchp("spec" simulat)) then
            setAMS_SDF(spectTemp ncvlogOpts corner)
	    status1=strcat("Setting of simulator " simulat " is changed to " state ".\n")
	    curForm = stringToSymbol(strcat("_asii_ams" getAMSNum() "_AMSsimulator_form"))
	    hiRegTimer("setFormParam(curForm ncvlogOpts thisCorner)" 1)
	    sevSetEngineOptions(sevSession(hiGetCurrentWindow()) 'simOptions)
	)
	if(rexMatchp("TI" simulat)  then
            setTIS(spectTemp corner)
	    status1=strcat("Setting of simulator " simulat " is changed to " state ".\n")
	)
	printf("%s",status1)
	printf("*****************************************************************************\n")
    )
)

procedure(setFormParam(curForm ncvlogOpts thisCorner)
    hiiSetCurrentForm(curForm)
    curForm->page->page1->scroll1->ncvlogArguments->value=ncvlogOpts
    curForm->page->value=5
    curForm->page->page5->scroll5->delay_type->value=thisCorner
    curForm->page->value=1
    hiFormDone(curForm)
)

procedure(setStrong()
    setCorner("strong")
)

procedure(setWeak()
    setCorner("weak")
)

procedure(setNom()
    setCorner("nom")
)

procedure(setTCL()
	let((simulat status1 state ncvlogOpts curForm thisCorner tclFile)
		simulat=asiGetSimName(asiGetCurrentSession())
		tclFile =strcat(pwd() "/tcl/" dgcv()~>cellName ".tcl")
		printf("*****************************************************************************\n")
		if(rexMatchp("ams" simulat) then
			status1=strcat("Setting TCL file to be" tclFile ".\n")
			
			;hiRegTimer("hiGetCurrentForm()->page->page1->scroll1->ncvlogArguments->value=ncvlogOpts" 1)
			curForm = stringToSymbol(strcat("_asii_ams" getAMSNum() "_AMSsimulator_form"))
			hiRegTimer("hiiSetCurrentForm(curForm)" 1)
			hiRegTimer("hiGetCurrentForm()->page->value=7" 5)
			if(isFile(tclFile) then 
				hiRegTimer("hiGetCurrentForm()->page->page7->scroll7->input->value= tclFile" 7)
				printf("%s",status1)
			)
			hiRegTimer("hiFormDone(hiGetCurrentForm())" 30)
			sevSetEngineOptions(sevSession(hiGetCurrentWindow()) 'simOptions)
		)
		printf("*****************************************************************************\n")
		
	)
)

procedure(changeSymbolInstPrefix()
	let(()
		hiRegTimer("changeSymbolInstPrefixNow()" 1)
		hiRegTimer("hiFormDone(hiGetCurrentForm())" 15)
		schHiCellViewProperty()
	)
)

procedure(changeSymbolInstPrefixNow()
	let((cv1 prefixName)
		hiiSetCurrentForm('schCVPropForm)
        	cv1=deGetCellView()
		prefixName = strcat(cv1~>cellName "_")
		schCVPropForm->InfoSysUser->system->value =  t
		schCVPropForm->schInstPrefix->value=prefixName
	)
)

procedure(addAPin(@optional (dir "output") (loc "right"))
	let((cv1 iopin inst_temp ipin opin inst lineLoc instx1 insty1 instx2 insty2 conPin pinLoc defaultLoc setLoc noConnCell isPin)
		cv1 =dgcv()
		iopin = dbOpenCellViewByType( "basic" "iopin" "symbol" "" "r")
		ipin = dbOpenCellViewByType( "basic" "ipin" "symbol" "" "r")    
		opin = dbOpenCellViewByType( "basic" "opin" "symbol" "" "r")    
        noConnCell=dbOpenCellViewByType( "isilLib" "deadend" "symbol"  "" "r")
		foreach(inst ggss()
			if(or(inst~>objType=="line" inst~>objType=="path") then
				lineLoc=inst~>points
				instx1=caar(lineLoc)
				insty1=cadar(lineLoc)
				instx2=caadr(lineLoc)
				insty2=car(cdadr(lineLoc))
                if(insty1 > insty2 then
                    inst_temp = insty2
                    insty2 = insty1
                    insty1 = inst_temp
                )
                if(instx1 > instx2 then
                    inst_temp = instx2
                    instx2 = instx1
                    instx1 = inst_temp
                )
                isPin = 1
				case(dir
					("output"
						conPin=opin
					)
					("input"
						conPin=ipin
					)
					("noconn"
						conPin=noConnCell
                        isPin = 0
					)
					(t
						conPin=iopin
					)
				)
				if(instx1==instx2 then 
					defaultLoc="top"
					setLoc=if(loc loc defaultLoc)					
					case(setLoc
						("top"
							pinLoc=list(instx2 insty2)
							conRot="R90"
						)
						(t
							pinLoc=list(instx1 insty1)
							conRot="R270"
						)
					)
				)
				if(insty1==insty2 then
					case(dir
						("output"
							conPin=opin
							defaultLoc="right"
						)
                        ("noconn"
                            conPin=noConnCell
							defaultLoc="right"
                        )
						("input"
							conPin=ipin
							defaultLoc="left"
						)
						(t
							conPin=iopin
							defaultLoc="right"
						)
					)
					setLoc=if(loc loc defaultLoc)					
					case(setLoc
						("right"
							pinLoc=list(instx2 insty2)
							if(or(dir=="input" dir == "noconn") conRot="R180" conRot="R0")
						)
						(t
							pinLoc=list(instx1 insty1)
							if(dir=="output" conRot="R180" conRot="R0")						
						)
					)
				)
                if(isPin == 1 then
				    schCreatePin(cv1 conPin inst~>net~>name dir nil pinLoc conRot)
                else
                    schCreateInst(cv1 noConnCell strcat("noconn_" inst~>net~>name) pinLoc conRot)
                )
			)	
		)
	)
)


procedure(saveVerilog(mslList @optional (genVerilog t))		;mslList is a list(1 2 3) representing msl270 msl280 msl290
	let((outVerilogFile corner corners ofilesGenSDF libName cellSDFDir topCellName cellName cellHier fullCorner noifStr)
		libName=dgcv()~>libName
		cellName= dgcv()~>cellName
		cellHier=geGetInstHier(hiGetCurrentWindow())
		noifStr=""
		rexCompile("/")
		cellHier=rexReplace(cellHier,".",0)
		topCellName=geGetTopLevelCellView(hiGetCurrentWindow())~>cellName
		cellHier=strcat(topCellName cellHier)
		unless(ddGetObj(libName cellName  "Verilog")
			schViewToView(libName cellName libName cellName "schematic" "Verilog" "schSchemToPinList" "schPinListToVerilog")
		)
		corners=list("N" "W" "S")
		ofilesGenSDF=list()
		foreach(corner corners
			ofileGenSDF=strcat(pwd() "/cds/" libName "/" cellName "/Verilog/gen_sdf" corner ".txt")
			case(corner
				("N"
					genSDFTXTN(ofileGenSDF cellName mslList)
				)
				("W"
					genSDFTXTW(ofileGenSDF cellName mslList)
				)
				("S"
					genSDFTXTS(ofileGenSDF cellName mslList)
				)
			)
			ofilesGenSDF=append1(ofilesGenSDF ofileGenSDF)
		)
		
		outVerilogFile=strcat(pwd() "/cds/" libName "/" cellName "/Verilog/verilog.v")
		if(genVerilog then
			hiRegTimer("hiFormDone(dumpNetlistFormSimple)"	5)		
			hiRegTimer("setVERILOGForm(outVerilogFile)" 2)
			timspDumpNetlistAction()
		)
		cellSDFDir = strcat(pwd() "/cds/" libName "/" cellName "/Verilog")
		sh(sprintf(nil "cd %s" strcat(pwd() "/cds/" libName "/" cellName "/Verilog")))
		foreach(corner corners 
			case(corner
				("N"
					fullCorner="NOM"
				)
				("W"
					fullCorner="WEAK"
				)
				("S"
					fullCorner="STRONG"
				)
			)
			printf("`ifdef %s\n\tinitial begin\n\t\t$sdf_annotate (\"%s/%s_%s.sdf\",%s);\n\tend\n`endif\n\n" fullCorner cellSDFDir cellName corner cellHier)
 			noifStr=strcat(noifStr sprintf(nil "\t\t$sdf_annotate (\"%s/%s_%s.sdf\",%s);\n" cellSDFDir cellName corner cellHier))
 		)
 		printf("%s" noifStr)
		printf("cd %s\n" strcat(pwd() "/cds/" libName "/" cellName "/Verilog/"))
		foreach(corner corners printf("rm -rf ets* ; ets -nowin -init gen_sdf%s.txt;\n" corner))
		ofilesGenSDF
	)
)

procedure(setVERILOGForm(outVerilogFile)
		hiiSetCurrentForm('dumpNetlistFormSimple)
		dumpNetlistFormSimple->dumpNetlistPath->value=outVerilogFile
)

procedure(genSDFTXTN(OFILE cellName mslLibList)
	let((OPORT corner temp1 temp2 temp3 vol1 vol2 vol3 lib1 lib2 lib3 subLibs subLib libs temps vols tem vol lib)
		subLibs=list("CORE" "CORE_ARCHDECAP" "CTS")
		corner="N"
		lib1="msl290"
		lib2="msl280"
		lib3="msl270"
		temp1="25"
		temp2="25"
		temp3="27"
		vol1="7"
		vol2= "5"
		vol3="3"
		libs=list(lib1 lib2 lib3)
		temps=list(temp1 temp2 temp3)
		vols=list(vol1 vol2 vol3)
		OPORT=outfile(OFILE,"w")
		fprintf(OPORT "read_lib {")
		foreach(ii mslLibList
			lib=nthelem(4-ii libs)
			tem=nthelem(4-ii temps)
			vol=nthelem(4-ii vols)
			foreach(subLib subLibs
				fprintf(OPORT "\t/db/pdkoa/lbc7/current/diglib/%s/synopsys/src/%s_%s_%s_%s_%s.lib\n" lib upperCase(lib),corner,tem,vol,subLib)	
			)
		)

		fprintf(OPORT "}\n")		
		fprintf(OPORT "read_verilog ./verilog.v\n")
		fprintf(OPORT "set_top_module %s\n",cellName)
		fprintf(OPORT "write_sdf %s_%s.sdf\n",cellName,corner)		
		fprintf(OPORT "exit\n")
		close(OPORT)		
	)
)

procedure(genSDFTXTW(OFILE cellName mslLibList)
	let((OPORT corner temp1 temp2 temp3 vol1 vol2 vol3 lib1 lib2 lib3 subLibs subLib libs temps vols tem vol lib)
		subLibs=list("CORE" "CORE_ARCHDECAP" "CTS")
		corner="W"
		lib1="msl290"
		lib2="msl280"
		lib3="msl270"
		temp1="125"
		temp2="125"
		temp3="125"
		vol1="6.3"
		vol2= "4.5"
		vol3="3"
		libs=list(lib1 lib2 lib3)
		temps=list(temp1 temp2 temp3)
		vols=list(vol1 vol2 vol3)
		OPORT=outfile(OFILE,"w")
		fprintf(OPORT "read_lib {")
		foreach(ii mslLibList
			lib=nthelem(4-ii libs)
			tem=nthelem(4-ii temps)
			vol=nthelem(4-ii vols)
			foreach(subLib subLibs
				fprintf(OPORT "\t/db/pdkoa/lbc7/current/diglib/%s/synopsys/src/%s_%s_%s_%s_%s.lib\n" lib upperCase(lib),corner,tem,vol,subLib)	
			)
		)

		fprintf(OPORT "}\n")		
		fprintf(OPORT "read_verilog ./verilog.v\n")
		fprintf(OPORT "set_top_module %s\n",cellName)
		fprintf(OPORT "write_sdf %s_%s.sdf\n",cellName,corner)		
		fprintf(OPORT "exit\n")
		close(OPORT)		
	)
)

procedure(genSDFTXTS(OFILE cellName mslLibList)
	let((OPORT corner temp1 temp2 temp3 vol1 vol2 vol3 lib1 lib2 lib3 subLibs subLib libs temps vols tem vol lib)
		subLibs=list("CORE" "CORE_ARCHDECAP" "CTS")
		corner="S"
		lib1="msl290"
		lib2="msl280"
		lib3="msl270"
		temp1="-40"
		temp2="-40"
		temp3="-40"
		vol1="7.7"
		vol2= "5.5"
		vol3="3.6"
		libs=list(lib1 lib2 lib3)
		temps=list(temp1 temp2 temp3)
		vols=list(vol1 vol2 vol3)
		OPORT=outfile(OFILE,"w")
		fprintf(OPORT "read_lib {")
		foreach(ii mslLibList
			lib=nthelem(4-ii libs)
			tem=nthelem(4-ii temps)
			vol=nthelem(4-ii vols)
			foreach(subLib subLibs
				fprintf(OPORT "\t/db/pdkoa/lbc7/current/diglib/%s/synopsys/src/%s_%s_%s_%s_%s.lib\n" lib upperCase(lib),corner,tem,vol,subLib)	
			)
		)

		fprintf(OPORT "}\n")		
		fprintf(OPORT "read_verilog ./verilog.v\n")
		fprintf(OPORT "set_top_module %s\n",cellName)
		fprintf(OPORT "write_sdf %s_%s.sdf\n",cellName,corner)		
		fprintf(OPORT "exit\n")
		close(OPORT)		
	)
)

procedure(getLibs()
	let((cv1 libTable inst libName lib)
		cv1=dgcv()
		libTable=makeTable("Libraries table.")
		foreach(inst cv1~>instances
			libName=inst~>libName
			libTable[libName]=1
		)
		foreach(lib sort(libTable->? 'alphalessp) if(rexMatchp("msl" lib) printf("%s " lib)))
		printf("\n")
	)
)

procedure(copyConfigOnly(dstName @optional (srcName "CONTROL"))
    let((srcSimCellName dstSimCellName curLib views schView dstSchViewName srcView dstView view srcSimCellSch  schCV cv1 instId benchName hierCV )
        srcSimCellName = "simxz_AMS_CASALL_TOP"
        dstSimCellName = srcSimCellName
        curLib = "CASALL"
        if(not(srcName) srcName="CONTROL")
        views = list("config")
        dstSchViewName=strcat("schematic_" dstName)
        schView = "schematic"
        foreach(view views
            srcView = strcat(view "_" srcName)
            dstView = strcat(view "_" dstName)
            printf("\nCopy %s %s view to %s %s\n" srcSimCellName srcView dstSimCellName dstView)
            if(view=="schematic" then
                srcSimCellSch=dbOpenCellViewByType(curLib srcSimCellName srcView "" "r")
                if(not(ddGetObj(curLib,dstSimCellName,dstView)) dbCopyCellView(srcSimCellSch curLib dstSimCellName dstView nil nil t))
            else
                CCScopyViewCV(curLib srcSimCellName srcView curLib dstSimCellName dstView t)
                ;printf("%s is currentView\n" currentView)
            );if
        );foreach currentView

        hierCV = hdbOpen(curLib dstSimCellName strcat("config_" dstName) "a")
        hdbSetTopCellViewName(hierCV curLib dstSimCellName dstSchViewName)
        
        spec = list(list(curLib "host_tb" nil nil));  //specify cell for binding
        hostView= strcat("functional_xz_" lc(dstName))
        rule = list('hdbcBindingRule list(nil nil hostView));  //specify view for binding
 
        
        hdbSetObjBindRule(hierCV  spec  rule);  //Executing the bind rule

        spec = list(list(curLib "smb_mon" nil nil));  //specify cell for binding
        hostView= strcat("functional_xz")
        rule = list('hdbcBindingRule list(nil nil hostView));  //specify view for binding
 
        hdbSetObjBindRule(hierCV  spec  rule);  //Executing the bind rule

          hdbSave(hierCV)
          hdbClose(hierCV)
        ;CCSOpenSchematic(curLib dstSimCellName strcat("config_" dstName) 2)
	)
)


procedure(changeBinding(dstName)
	let((srcSimCellName dstSimCellName  curLib hierCV spec hostView rule )
		srcSimCellName = "simxz_AMS_CASALL_TOP"
		dstSimCellName = srcSimCellName
		curLib = "CASALL"
		
		hierCV = hdbOpen(curLib dstSimCellName strcat("config_" dstName) "a")
		spec = list(list(curLib "CASALL_digtop_wrapper" nil nil));  //specify cell for binding
		hostView= "functional"
		rule = list('hdbcBindingRule list(nil nil hostView));  //specify view for binding
		
		hdbSetObjBindRule(hierCV  spec  rule);  //Executing the bind rule
		
		spec = list(list(curLib "DIGITAL_CORE" "schematic" "I_digtop_wrapper"));  //specify cell for binding
		rule = list('hdbcBindingRule list(nil nil hostView));  //specify view for binding
		
		hdbSetObjBindRule(hierCV  spec  rule);  //Executing the bind rule
	  	hdbSave(hierCV)
	  	hdbClose(hierCV)
	)
)

procedure(OCT(dstName)
	let((curLib dstSimCellName)
		curLib="CASALL"
		dstSimCellName="simxz_AMS_CASALL_TOP"
		CCSOpenSchematic(curLib dstSimCellName strcat("config_" dstName) 2)
	)
)
;;--------From Here-----------
procedure(CCScopyViewCV(fromLib fromCell fromView toLib toCell toView @optional  (overWrite t) )
 
let( (srcSpecList srcSpec dstSpecList dstSpec)
 
      srcSpecList = gdmCreateSpecList()
      srcSpec = gdmCreateSpec(fromLib fromCell fromView nil "CDBA")
      gdmAddSpecToSpecList( srcSpec srcSpecList)
 
      dstSpecList = gdmCreateSpecList()
      dstSpec = gdmCreateSpec(toLib toCell toView nil "CDBA")
      gdmAddSpecToSpecList( dstSpec dstSpecList)
 
      ccpCopy(srcSpecList dstSpecList overWrite 'CCP_EXPAND_ALL )
 
      gdmResetSpecList(srcSpecList)
      gdmResetSpecList(dstSpecList)
  
   ) ;let
 
) ;procedure


procedure(abPurgeLib(libName)
  /* close all the cellViews from this library name */
  (foreach cellView (dbGetOpenCellViews)
	   (when (equal (dbGetq cellView libName) libName)
	   	printf("Closing %s-%s-%s\n",cellView~>libName cellView~>cellName cellView~>viewName)
		 (dbPurge cellView)))
  /* close any (?) tech files associated with the library */
  (foreach techFile (techGetOpenTechFiles)
	   (when (equal (dbGetq techFile libName) libName)
	   	printf("Closing %s-%s-%s\n",techFile>libName techFile>cellName techFile>viewName)
		 (techPurgeTechFile techFile)))
  /* close any property bags associated with the library */
  (foreach bag (dbGetOpenBags)
	   (when (equal (dbGetq (dbGetq (dbGetq bag ownerObj) lib) name)
			libName)
		 (dbPurgeBag bag)))
  t)

procedure(loadis()
	load("~xwzhang/bindkeys.local")
)

procedure(getObjName(inst)
    let(()
        val = ""
        if(inst~>name then
            val = inst~>name
        else
            if(inst~>theLabel then
                val = inst~>theLabel
            else
                foreach(fig inst~>net~>figs
                    if(val == "" && fig~>net~>name
                        val = fig~>net~>name
                    )
                )
            )
        )
        val
    )
)

procedure(printPath(@optional (use_top 0) (obj1 css()))
    let( (libName cellName cellHier noifStr topCellName instHier objName)
        libName=dgcv()~>libName
        cellName= dgcv()~>cellName
        cellHier = get_cell_hier(use_top)
        objName = getObjName(obj1)
        instHier = if(objName == "" cellHier strcat(cellHier "." objName))
        printf("path is\n %s\n" instHier)
        instHier
    )
) ;end procedure printPath

procedure(print_allnets(@optional (attach_top 0)(objs ggss()))
    let((objNameDict obj obj_type net_name net_names hc)
        objNameDict = makeTable("Obj name table")
        foreach(obj objs
            obj_type = obj~>objType
            ;printf("ObjType: %L\n", obj_type)
            if(obj_type == "line" || obj_type == "path" then
                net_name = obj~>net~>name
                if(net_name then
                    net_names = parseString(net_name ",")
                    foreach(net_name net_names
                        rexCompile("^<[0-9:*]+>")
                        net_name = rexReplace(net_name "" 0)
                        objNameDict[net_name] = 1
                    )
                )
            )
        )
        hc = get_cell_hier()
        foreach(net_name sort(objNameDict~>? 'alphalessp)
            printf("%s.%s\n", hc, net_name)
        )
    )
)

procedure(print_allcurrs(@optional (attach_top 0)(objs ggss())(pre ""))
    let((objNameDict obj obj_type net_name term terms term_name term_instname hc)
        objNameDict = makeTable("Obj name table")
        hc = get_cell_hier(attach_top)
        foreach(obj objs
            obj_type = obj~>objType
            ;printf("ObjType: %L\n", obj_type)
            if(obj_type == "line" || obj_type == "path" then
                net_name = obj~>net~>name
                if(net_name then
                    terms = obj~>net~>instTerms
                    foreach(term terms
                        term_name = term~>name
                        term_instname = term~>inst~>name
                        port = strcat(hc "." term_instname "." term_name)
                        printf("%s%s\n" pre port)
                    )
                )
            )
        )
    )
)

procedure(get_cell_info( @optional (inst css()))
    let((cellHier topCellName cell_name cell_parent)
        cellHier=geGetInstHier(hiGetCurrentWindow())
        rexCompile("/")
        if(cellHier == "/" then
            cellHier = ""
        else
            cellHier=rexReplace(cellHier,".",0)
        )
        topCellName=geGetTopLevelCellView(hiGetCurrentWindow())~>cellName
        cellHier=strcat(topCellName cellHier)
        if(inst~>name then
            cellHier = strcat(cellHier "." inst~>name)
        )
        cell_array = parseString(cellHier ".")
        if(length(cell_array) >= 1 then
            cell_name = nthelem(length(cell_array) cell_array)
            if(length(cell_array) > 1 then
                cell_parent = nthelem(length(cell_array) - 1 cell_array)
            else
                cell_name = "top"
                cell_parent = "top"
            )
        else
            cell_name = nil
            cell_parent = nil
        )
        list(cell_name cell_parent)
    )
)

procedure(gen_current_cell_def(@optional (cv dgcv())(is_qrc 0))
    let((curr_cell_info define_statement set_statement)
        curr_cell_info = get_cell_info(cv)
        define_statement = print_def_statement(curr_cell_info)
        set_statement = print_set_statement(curr_cell_info nil is_qrc)
        list(define_statement set_statement curr_cell_info)
    )
)

procedure(gen_cell_define_set( @optional (cell_set ggss()))
    let((all_cells cell cell_info cell_name o_cell_name cell_parent head_printed curr_cell_info define_statement set_statement)
        if(cell_set then
            all_cells = cell_set
        else
            all_cells = dgcv()~>instances
        )
        head_printed = 0
        curr_cell_info = get_cell_info(dgcv())
        define_statement = print_def_statement(curr_cell_info)
        set_statement = print_set_statement(curr_cell_info)
        probe_statement = ""
        foreach(cell all_cells
            if(cell~>objType == "inst" then
                cell_info = get_cell_info(cell)
                cell_name = car(cell_info)
                cell_parent = cadr(cell_info)
                if(cell_name && cell_parent then
                    if(head_printed == 0 then
                        define_statement = sprintf(nil "%s//%s blocks\n", define_statement cell_parent)
                        set_statement = sprintf(nil "%s#%s blocks\n", set_statement cell_parent)
                        head_printed = 1
                    )
                    o_cell_name = cell_name
                    if(cell_name = validate_cell_name(cell_name) then
                        define_statement = strcat(define_statement print_def_statement(list(cell_name cell_parent)))
                        set_statement = strcat(set_statement print_set_statement(list(cell_name cell_parent)))
                        probe_statement = sprintf(nil "%sprobe -create -emptyok -database ams_database -all -depth 1 ${%s}\n", probe_statement cell_name)
                    else
                        define_statement = strcat(define_statement print_def_statement(list(cell_name cell_parent) t))
                        set_statement = strcat(set_statement print_set_statement(list(cell_name cell_parent) t))
                    )
                )
            )
        )
        printf(define_statement)
        printf(set_statement)
        printf(probe_statement)
    )
)

procedure(print_set_statement(cell_info_array @optional (is_comment nil)(is_qrc 0))
    let((cell_o_name cell_name cell_par header set_statement set_sep)
        cell_name = car(cell_info_array)
        cell_par = cadr(cell_info_array)
        cell_o_name = if(length(cell_info_array) >= 3 nthelem(3 cell_info_array) cell_name)
        header = if(is_comment "#" "")
        if(is_qrc == 1 then
            set_sep = "\\|"
        else
            set_sep = "."
        )
        set_statement = sprintf(nil "%sset %s \"${%s}%s%s\"\n", header, cell_name, cell_par, set_sep, cell_o_name)
    )
)

procedure(print_def_statement(cell_info_array @optional (is_comment nil))
    let((cell_par cell_name cell_o_name num_spaces header spaces def_statement)
        cell_name = car(cell_info_array)
        cell_par = cadr(cell_info_array)
        cell_o_name = if(length(cell_info_array) >= 3 nthelem(3 cell_info_array) cell_name)
        num_spaces = 20
        header = ""
        if(is_comment then
            num_spaces = 18
            header = "//"
        )
        spaces = numSpace(num_spaces - strlen(cell_name))
        def_statement = sprintf(nil "`define %s%s`%s.%s\n", cell_name, spaces, cell_par, cell_o_name)
    )
)

procedure(validate_cell_name(in_str)
    let((out_str)
        out_str = nil
        rexCompile("<.*")
        out_str = rexReplace(in_str, "", 0)
        if(rexMatchp("^I[0-9][0-9]*$" out_str) || rexMatchp("^PIN[0-9][0-9]*$" out_str) then
            out_str = nil
        )
        out_str
    )
)

procedure(get_cell_hier(@optional (use_top 0)(attach_top 1))
    let((cellHier topCellName)
        cellHier=geGetInstHier(hiGetCurrentWindow())
        rexCompile("^/")
        cellHier = rexReplace(cellHier, "", 0)
        rexCompile("/")
        cellHier = rexReplace(cellHier, ".", 0)
        if(use_top == 1 then
            topCellName = "${top}"
        else
            topCellName = geGetTopLevelCellView(hiGetCurrentWindow())~>cellName
        )
        if(attach_top cellHier=strcat(topCellName if(cellHier == "" "" ".") cellHier))
        cellHier
    )
)


procedure(updatePinsFromSymbol(@optional (cv dgcv()))
    let((libName cellName thisTerminals symViewName symViewDB symTerminals
    termInfoListSch termInfoListSym termNamesSch termDirsTableSch
    termNamesSym termDirsTableSym termSchNSymList termSymNSchList )
        libName=cv~>libName
        cellName= cv~>cellName
        thisTerminals = cv~>terminals
        symViewName = "symbol"
        if(symViewDB = dbOpenCellViewByType(libName cellName symViewName "" "r") then
            symTerminals = symViewDB~>terminals
            termInfoListSch = genTermTables(thisTerminals)
            termInfoListSym = genTermTables(symTerminals)
            termNamesSch = car(termInfoListSch)
            termDirsTableSch = cadr(termInfoListSch)
            termNamesSym = car(termInfoListSym)
            termDirsTableSym = cadr(termInfoListSym)
            termSchNSymList = notIncludeList(termNamesSch termNamesSym)
            termSymNSchList = notIncludeList(termNamesSym termNamesSch)
            if(termSchNSymList removePins(termSchNSymList cv))
            if(termSymNSchList addPins(termSymNSchList termDirsTableSym cv))
            schCheck(cv)
            dbCheck(cv)
            dbSave(cv)
        else
            error("The specified %s view doesnot exist in %s-%s.\n", symViewName, libName, cellName)
        )
    )
)

procedure(fromVAMSToSymbol()
    let(()
        hiRegTimer("set_form_vams_to_symbol()" 1)
        schHiViewToView()
    )
)

procedure(set_form_vams_to_symbol()
    let(()
        hiiSetCurrentForm('schViewToViewForm)
        schViewToViewForm->fromViewName->value="verilogams"
        schViewToViewForm->toDataType->value="schematicSymbol"
    )
)

procedure(genTermTables(objArray)
    let((termDirTable termNames)
        termDirTable = makeTable("terminals")
        termNames = list()
        foreach(item objArray
            termDirTable[item~>name] = item~>direction
            termNames = append1(termNames item~>name)
        )
        list(termNames termDirTable)
    )
)

procedure(addPins(pinList dirTable @optional (cv dgcv()))
    let((termNameList CVBBoxList cvXmin cvXmax cvYmin cvYmax inxloc inyloc outxloc
        outyloc inoutDist gridSpace pinDist ipCell opCell iopCell pin pinCell
        xloc yloc ipNames iopNames opNames iopNameList addNote pind pName noConnCell
        isInput)
        termNameList = cv~>terminals~>name
        CVBBoxList = getCVBBox(cv)
        cvXmin = car(CVBBoxList)
        cvXmax = cadr(CVBBoxList)
        cvYmin = car(cddr(CVBBoxList))
        cvYmax = cadr(cddr(CVBBoxList))

        inxloc = cvXmin
        inyloc = cvYmax
        outxloc = cvXmax
        outyloc = cvYmax
        inoutDist = inxloc - outxloc
        if(inoutDist > -0.5 && inoutDis < 0.5 then
            inxloc = inxloc - 1         ; if the distance is too small, enlarge it
        )
        gridSpace = 0.0625
        pinDist = 3*gridSpace ; pindistance
        ipCell = dbOpenCellViewByType("basic" "ipin" "symbol" "" "r")
        opCell = dbOpenCellViewByType("basic" "opin" "symbol" "" "r")
        iopCell = dbOpenCellViewByType("basic" "iopin" "symbol" "" "r")
        ipNames = ""
        opNames = ""
        iopNames = ""
        foreach(pin pinList
            unless(member(pin termNameList)
                isInput = 0
                case(dirTable[pin]
                        ("input"
                            pinCell = ipCell
                            xloc = inxloc
                            yloc = inyloc
                            inyloc = inyloc - pinDist 
                            ipNames = strcat(ipNames " " pin "\n")
                            isInput = 1
                        )
                        ("output"
                            pinCell = opCell
                            xloc = outxloc
                            yloc = outyloc
                            outyloc = outyloc - pinDist 
                            opNames = strcat(opNames " " pin "\n")
                        )
                         ("inputOutput"
                            pinCell = iopCell
                            xloc = inxloc
                            yloc = inyloc
                            inyloc = inyloc - pinDist 
                            iopNames = strcat(iopNames " " pin "\n")
                        )
                        (t
                            pinCell = nil
                        )
                )
                if(pinCell then 
                    printf("Adding %s pin %s pin at location (%f:%f).\n", dirTable[pin], pin, xloc, yloc)
                    schCreatePin(cv pinCell pin dirTable[pin] nil xloc:yloc "R0")
                    if(isInput == 1 createWireNoconn(cv pin list(xloc yloc) 0.5 "H" "E"))
                )
            )
        )
        iopNameList = list(ipNames opNames iopNames)
        addNote = "Added "
        pind = 0
        foreach(pName iopNameList
            pind = pind + 1
            case(pind
                (1 pinDir = "input pin ")
                (2 pinDir = "output pin ")
                (3 pinDir = "inout pin ")
                (t pinDir = "")
            )
            if(pName != "" then addNote = strcat(addNote " " pinDir  pName "\n"))
        )
        schCreateNoteLabel(cv list(cvXmax outyloc)  addNote "lowerLeft" "R0" "fixed" 0.125 "normalLabel")
        schCheck(cv)
        dbCheck(cv)
        dbSave(cv)
    )
)

procedure(createWireNoconn(cv pinName baseLoc wireLen wireRot noconnLoc)
    let((startx starty noConnCell endx endy noconnX noconnY noconnRot noconnName
        mywire wireWidth labelRot)
        startx = car(baseLoc)
        starty = cadr(baseLoc)
        noConnCell=dbOpenCellViewByType( "basic" "noConn" "symbol"  "" "r")
        case(wireRot
            ("V" ;vertical wire
                endx = startx
                endy = starty + wireLen
                labelRot = "R90"
            )
            (t ;horizontal wire
                endx = startx + wireLen
                endy = starty
                labelRot = "R0"
            )
        )
        case(noconnLoc
            ("S" ;start of wire
                noconnX = startx
                noconnY = starty
                case(wireRot
                    ("V" ;vertical
                        noconnRot = "R0"
                    )
                    (t
                        noconnRot = "R270"
                    )
                )
            )
            (t ;end of wire
                noconnX = endx
                noconnY = endy
                case(wireRot
                    ("V"
                        noconnRot = "R180"
                    )
                    (t
                        noconnRot = "R90"
                    )
                )
            )
        )
        noconnName = strcat("noConn_" pinName)
        if(rexMatchp("<" pinName) wireWidth = 0.0625 wireWidth = 0.0)
        mywire = schCreateWire(cv "draw" "full" list(startx:starty endx:endy) 0.0625 0.0625 wireWidth)
        schCreateWireLabel(cv car(mywire) startx:(starty+0.0625) pinName "lowerLeft" labelRot "stick" 0.0625 nil)
        schCreateInst(cv noConnCell noconnName list(noconnX noconnY) noconnRot)
    )
)

procedure(getCVBBox(cv1)
    let((inst x1 x2 y1 y2 xmax xmin ymax ymin i cvBBox scvBBox)
        xmax = 1
        ymax = 1
        xmin = 0
        ymin = 0
        i = 0
        foreach(inst cv1~>instances
            x1 = caar(inst~>bBox)
            x2 = caadr(inst~>bBox)
            y1 = cadar(inst~>bBox)
            y2 = cadadr(inst~>bBox)
            if(i == 0 then
                xmax = x2 + 1
                xmin = x1 - 1
                ymax = y2 + 1
                ymin = y1 - 1
            else
                if(x2 > xmax-1 xmax = x2 + 1)
                if(x1 < xmin+1 xmin = x1 - 1)
                if(y2 > ymax-1 ymax = y2 + 1)
                if(y1 < ymin+1 ymin = y1 - 1)
            );if
        i=i+1
        );foreach        
        if(xmax < 1 xmax = 1)
        if(ymax < 1 ymax = 1)
        if(xmin > 0 xmin = 0)
        if(ymin > 0 ymin = 0)
        cvBBox = list(xmin xmax ymin ymax)
        scvBBox = list()
        foreach(tValue cvBBox
            newTValue = snapValueToGrid(tValue)
            scvBBox = append1(scvBBox newTValue)
        )
        scvBBox
    )
)

procedure(removePins(pinList @optional (cv dgcv()))
    let((inst)
        foreach(inst cv~>instances
            if(and(inst~>pin member(inst~>net~>name pinList)) then
                printf("removing pin %s.\n" inst~>net~>name)
                schDelete(inst)
                schCreateNoteLabel(cv inst~>xy sprintf(nil "Pin %s removed", pin) "lowerLeft" "R0" "fixed" 0.125 "normalLabel")
            )
        )
        schCheck(cv)
        dbCheck(cv)
        dbSave(cv)
    )
)

procedure(notIncludeList(list1 list2)
    let((list1n2 item)
        list1n2 = list()
        if(listp(list1) && listp(list2) then
            foreach(item list1
                unless(member(item list2)
                    list1n2 = append1(list1n2 item)
                )
            )
        else
            error("One of them is not list...\n")
        )
        list1n2
    )
)

procedure(syncLib(oldLib newLib @optional (cv dgcv()))
   let((inst inst2)
      foreach(inst cv~>instances
         if(inst~>libName==oldLib then
	     unless(ddGetObj(newLib inst~>cellName inst~>viewName)
	        printf("%s-%s-%s doesnot exist" newLib inst~>cellName inst~>viewName)
	        oldObjViews=ddGetObj(oldLib inst~>cellName)~>views
	        foreach(view oldObjViews CCScopyViewCV(oldLib inst~>cellName view newLib  inst~>cellName view t))
	     )
	     inst2=dbOpenCellViewByType(newLib inst~>cellName inst~>viewName "schematicSymbol" "r")
	     inst~>master=inst2
	 )
      )
      dbSave(cv)
   )
)


procedure(toggleNetHighlight()
   let((highOrNot)
      highOrNot=schViewMenu->NetHighlights->checked
      if(highOrNot
         schViewMenu->NetHighlights->checked=nil
         schViewMenu->NetHighlights->checked=t
      )

   )
)

procedure(numSpace(inNum)
   let((jj spaceStr spaceNum)
        spaceStr = ""
        spaceNum = if(inNum>1 inNum 1)
        for(jj 1 spaceNum
            spaceStr = strcat(spaceStr " ")
        )
        spaceStr
   )
)

procedure(setTest(test)
    setShellEnvVar("TEST" test)
    printf("Test is set to: %s" getShellEnvVar("TEST"))
)

procedure(getTest()
    printf("current test: %s" getShellEnvVar("TEST"))
    getShellEnvVar("TEST")
)

procedure(ClioCheckoutCells(lib_name cell_names view_names)
    let((specList cell_name view_name gdmSpec)
        specList = gdmCreateSpecList()
        foreach(cell_name cell_names
            foreach(view_name view_names
                gdmSpec = getCellSpec(lib_name cell_name view_name)
                if(gdmSpec && isCheckIn(gdmSpec) then
                    gdmAddSpecToSpecList(gdmSpec specList)
                else
                    if(!ddGetObj(lib_name cell_name view_name) then
                        printf("%s-%s-%s doesnot exist.\n", lib_name, cell_name, view_name)
                    else
                        printf("gdmspec state is %L.\n", getSpecState(gdmSpec))
                    )
                )
            )
        )
        if(specList != nil gdmco(specList) nil)
    )
)
procedure(getCellSpec(lib_name cell_name view_name)
    let((objId spec)
        objId = ddGetObj(lib_name cell_name view_name)
        spec = nil
        if(objId then
            spec = gdmCreateSpecFromDDID(objId)
        )
        spec
    )
)

procedure(getSpecState(in_spec)
    let(()
        if(in_spec car(reverse(parseString(caar(gdmstatus(spec 6))))) nil)
    )
)

procedure(isCheckCo(in_spec)
    let((spec_state)
        spec_state = getSpecState(in_spec)
        if(spec_state spec_state == "gdmStateNone" nil)
    )
)

procedure(isCheckIn(in_spec)
    let((spec_state)
        spec_state = getSpecState(in_spec)
        if(spec_state spec_state == "gdmStateCI" nil)
    )
)

procedure(ClioCheckoutCell(lib_name cell_name view_name)
    let(()
        ClioCheckoutCells(lib_name list(cell_name) list(view_name))
    )
)

procedure(checkout_text(file_name)
    let((lib_name cell_name view_name file_dir )
        rexCompile("//*")
        file_name = rexReplace(file_name, "/", 0)
        rexCompile("/*$")
        file_name = rexReplace(file_name, "", 0)
        file_dir = nil
        if(isFile(file_name) then
            file_dir = buildString(reverse(cdr(reverse(parseString(file_name "/")))) "/")
        else
            if(isDir(file_name) file_dir = file_name)
        )
        if(file_dir then
            rexCompile("^/*")
            file_dir = rexReplace(file_dir, "", 0)
            file_items = reverse(parseString(file_dir "/"))
            if(length(file_items) >= 3 then
                view_name = car(file_items)
                cell_name = cadr(file_items)
                lib_name = caddr(file_items)
                ClioCheckoutCell(lib_name cell_name view_name)
                printf("checking out %s \n", buildString(list(lib_name cell_name view_name) "-"))
            else
                printf("/%s is not a valid directory.\n", file_dir)
            )
        else
            printf("%s is not a valid directory.\n", file_dir)
        )
    )
)

procedure(ClioGdmco(lib @key (cv "verilogams") )
    let( (libId objId cell cells view views spec specList state)
        libId = ddGetObj(lib)
        specList = gdmCreateSpecList()
        cells = setof( x libId~>cells and(rexMatchp("^m4" x~>name) member( cv x~>views~>name)))~>name
        foreach( cell cells
            objId = ddGetObj( lib cell cv "*" )
            spec = gdmCreateSpecFromDDID(objId)
            ; if it is checked in, add to speclist
            state = car(reverse(parseString(caar(gdmstatus( spec 6 )))))
            when( state = "gdmStateCI"          
                gdmAddSpecToSpecList(spec specList)
                printf("checking out %s\n", objId~>cell~>name)
            )
        )
        when(specList != nil gdmco(specList))
        cells
    )
)

procedure(currentWinId(@optional (win hiGetCurrentWindow()))
    let((winID)
        winID = cadr(parseString(sprintf(nil "%L" win1), ":"))
        winID
    )
)

procedure(mapABWA(@optional (win hiGetCurrentWindow()))
    let((swin abwaList abwa dwin)
        swin = hiGetSessionWindow(win)
        abwaList = list("Annotation Browser" "Wire Assistant")
        foreach(abwa abwaList
            dwin = deFindAssistant(abwa swin)
            hiMapWindow(dwin)
        )
    )
)

procedure(print_all_nets(@optional (macro_name nil) (cv dgcv())(is_qrc 0)(no_term 1))
    let((net_table net net_name net_name_list name_no_lt define_nets probe_nets set_sep net_begin net_end)
        all_net_table = makeTable("net table")
        all_net_table = net_table_from_nets_names(cv~>nets~>name)
        all_term_table = makeTable("term table")
        all_term_table = net_table_from_nets_names(cv~>terminals~>name)
        foreach(net_name all_term_table->? printf("%s\n" net_name))
        cv_info = gen_current_cell_def(cv is_qrc)
        unless(macro_name
            macro_name = car(caddr(cv_info))
        )
        probe_nets = sprintf(nil "#%s level\n%s", macro_name, cadr(cv_info))
        define_nets = sprintf(nil "//%s level\n%s", macro_name, car(cv_info))
        foreach(net_name sort(all_net_table->? 'alphalessp)
            if(net_name != "" && !rexMatchp("^net[0-9]+" net_name) && !rexMatchp("^VSS[A,D][0-9]*$" net_name) && !rexMatchp("^VDD[A,D][0-9]*$" net_name) && !rexMatchp("!" net_name) then
                unless(no_term == 1 && member(net_name all_term_table->?)
                    net_begin = "\""
                    if(is_qrc == 1 then
                        net_end = " \""
                        set_sep = "\\|"
                    else
                        net_end = "\""
                        set_sep = "."
                    )
                    probe_nets = sprintf(nil "%sprobe -create -emptyok -database ams_database %s${%s}%s%s%s\n", probe_nets, net_begin, macro_name, set_sep, net_name, net_end)
                    define_nets = sprintf(nil "%s%s", define_nets, print_def_statement(list(net_name, macro_name)))
                )
            )
        )
        probe_nets = sprintf(nil "%s#end of %s level\n", probe_nets, macro_name)
        define_nets = sprintf(nil "%s//end of %s level\n", define_nets, macro_name)
        printf(probe_nets)
        printf(define_nets)
        list(probe_nets, define_nets)
    )
)

procedure(remove_square_brackets(in_str)
    let((sqr)
        sqr = pcreCompile("<.*?>")
        out_str = pcreReplace(sqr, in_str, "" 0)
    )
)

procedure(net_table_from_nets_names(in_name_list)
    let((net_table net net_name net_name_list name_no_lt)
        net_table = makeTable("net table")
        foreach(net_name in_name_list
            new_net_name = remove_square_brackets(net_name)
            if(rexMatchp(",", new_net_name) then
                net_name_list = parseString(new_net_name, ",")
            else
                net_name_list = list(new_net_name)
            )
            foreach(net_name1 net_name_list
                ;printf("I am here %s\n", net_name1)
                pin_info = extract_pin(net_name1)
                name_no_lt = car(pin_info)
                pin_range = cadr(pin_info)
                pin_range_list = extract_pin_range(pin_range)
                if(member(name_no_lt net_table) then
                    if(net_table[name_no_lt] && pin_range_list then
                        net_table[name_no_lt] = merge_pin_range(pin_range_list net_table[name_no_lt])
                    else
                        if(pin_range_list then
                            net_table[name_no_lt] = pin_range_list
                        else
                            if(net_table[name_no_lt]
                                printf("3967 pin_range_list for %s is invalid.\n", name_no_lt)
                            )
                        )
                    )
                else
                    net_table[name_no_lt] = pin_range_list
                )
            )
        )
    net_table
    )
)

procedure(merge_pin_range(in_array1 in_array2)
    let((new_array array_len pin_range)
        new_array = sort(append(in_array1 in_array2) 'lessp)
        array_len = length(new_array)
        pin_range = list(nthelem(array_len new_array) car(new_array))
    )
)

procedure(extract_pin_range(in_str)
    let((pin_range range_1 range_2 temp_range range_list)
        range_list = list()
        rexCompile("\\[\\(.*\\)\\]")
        if(rexExecute(in_str) then
            pin_range = rexSubstitute("\\1")
            if(pin_range != "" then
                rexCompile("\\(.*\\):\\(.*\\)")
                if(rexExecute(pin_range) then
                    range_1 = rexSubstitute("\\1")
                    range_2 = rexSubstitute("\\2")
                else
                    range_1 = pin_range
                    range_2 = pin_range
                )
                range_1 = evalstring(range_1)
                range_2 = evalstring(range_2)
                if(range_1 < range_2 then
                    temp_range = range_1
                    range_1 = range_2
                    range_2 = temp_range
                )
                range_list = list(range_1 range_2)
            )
        )
        range_list
    )
)

procedure(printNodes(@optional (dig_define nil)(inst css()))
    let((net_table net net_name net_name_list name_no_lt)
        net_table = makeTable("net table")
        foreach(term inst~>instTerms
            net_name = term~>name
            rexCompile("<.*")
            name_no_lt = rexReplace(net_name, "", 0)
            net_table[name_no_lt] = 1
        )
        foreach(net_name sort(net_table->? 'alphalessp)
            if(dig_define then
                printf("`define %s%s%s.%s\n", net_name, numSpace(20 - strlen(net_name)), dig_define, net_name)
            else
                printf("%s\n", net_name)
            )
        )
        t
    )
)


procedure(updateLibCells(newLib oldLibList)
    let((schView changeTable cell cellName cv inst instLib)
        schView = "schematic"
        changeTable = makeTable("needs change table")
        foreach(cell ddGetObj(newLib)~>cells
            cellName = cell~>name
            if(ddGetObj(newLib cellName schView) then
                cv = dbOpenCellViewByType(newLib cellName schView schView "r") 
                instList = findInstInOldLib(oldLibList)
                dbClose(cv)
            )
        )
        changeTable
    )
)

procedure(findInstInOldLib(oldLibList @optional (cv dgcv()))
    let((instList instLib inst)
        instList = list()
        foreach(inst cv~>instances
        ;if(and(inst~>libName==origLib ddGetObj(newLib inst~>cellName)) then
            instLib = inst~>libName
            if(member(instLib, oldLibList) then
                instList = append1(instList inst->name)
                printf("%s(%s) on %s in %s needs to be modified\n",inst~>name,inst~>cellName,cv~>cellName,cv~>libName)
            )
        )
        instList
    )
)
procedure(copyAllVerilogAmsViews(oldLib newLib @optional (viewName "verilogams"))
    let((tableNeedToCopy cell cellName newCell)
        tableNeedToCopy = makeTable("need to copy table")
        foreach(cell ddGetObj(oldLib)~>cells
            cellName = cell~>name
            newCell = cellName
            ;printf("%s\n" cellName)
            if(and(ddGetObj(oldLib cellName viewName) ddGetObj(newLib newCell) !ddGetObj(newLib newCell viewName)) then
            ;if(ddGetObj(oldLib cellName viewName) then
                tableNeedToCopy[cellName]=1
              )
        )
        foreach(cellName sort(tableNeedToCopy->? 'alphalessp) printf("%s\n" cellName))
        cnt = 0
        foreach(cellName sort(tableNeedToCopy->? 'alphalessp)
            newCell = cellName
            ;if(cnt <= 1  then
                printf("Coping cell %s from %s to %s.\n", cellName, oldLib, newLib)
                CCScopyViewCV(oldLib cellName viewName newLib newCell viewName)
                printf("Finish Coping cell %s from %s to %s.\n", cellName, oldLib, newLib)
            ;)
            cnt = cnt + 1
        )
    )
)

procedure(replace_inst_by_cellname(old_inst_cellNames new_inst @optional (cv dgcv()))
    let((inst)
        foreach(inst cv~>instances
            if(member(inst~>cellName old_inst_cellNames) then
                inst~>master = new_inst
            )
        )
        dbCheck(cv)
        dbSave(cv)
        dbClose(cv)
    )
)

procedure(replace_all_views(lib_name cell_name top_cells new_top_cell_obj)
    let((curr_cell view cv)
        curr_cell = ddGetObj(lib_name cell_name)
        foreach(view curr_cell~>views
            if(rexMatchp("^schematic" view~>name) then
                cv = dbOpenCellViewByType(lib_name cell_name view~>name "" "a")
                if(and(cv new_top_cell_obj) then
                    printf("replacing %s....\n", view~>name)
                    replace_inst_by_cellname(top_cells new_top_cell_obj cv)
                )
            )
        )
    )
)

procedure(display_lib_inst_cell_name(lib_name cell_name inst_name)
    let((curr_cell view cv)
        curr_cell = ddGetObj(lib_name cell_name)
        foreach(view curr_cell~>views
            if(rexMatchp("^schematic" view~>name) then
                cv = dbOpenCellViewByType(lib_name cell_name view~>name "" "r")
                if(cv then
                    display_inst_cellname(inst_name cv)
                )
            )
        )
        t
    )
)

procedure(display_inst_cellname(inst_name @optional (cv dgcv()))
    let((inst)
        foreach(inst cv~>instances
            if(inst~>name == inst_name then
                printf("%s - %s - %s - %s.\n", cv~>cellName, cv~>viewName, inst_name, inst~>cellName)
            )
        )
        t
    )
)

procedure(cv_obj()
    let(()
        ddGetObj(dgcv()~>libName dgcv()~>cellName dgcv()~>viewName)
    )
)

;get the resistor definition in multiple segments, good for each pin will have a output pin named
procedure(get_res_def()
    let((inst term minus_pin plus_pin res_value res_name all_res_def all_pins res_def)
        all_res_def = ""
        all_pins = list()
        foreach(inst ggss()
            res_value = get_res_value(inst)
            if(res_value > 0 then
                foreach(term inst~>instTerms
                    if(term~>name == "MINUS" minus_pin = term~>net~>name)
                    if(term~>name == "PLUS" plus_pin = term~>net~>name)
                )
                res_value = print_number_unit(res_value)
                res_name = sprintf(nil "R_%s__%s", upperCase(plus_pin), upperCase(minus_pin))
                res_def = sprintf(nil "    resistor #(.r(%s)) %s(%s, %s);", res_value, res_name, plus_pin, minus_pin)
                if(not(member(minus_pin all_pins)) all_pins = append1(all_pins minus_pin))
                if(not(member(plus_pin all_pins)) all_pins = append1(all_pins plus_pin))
                ;printf("%s\n", res_def)
                all_res_def = sprintf(nil "%s%s\n", all_res_def, res_def)
            )
        )
        all_res_def = sprintf(nil "    electrical %s;\n%s", buildString(all_pins, ", "), all_res_def)
        printf("%s\n", all_res_def)
    )
)

;get the resistor definition in one segment, good for multiple resistor combined to form one big resistor
procedure(get_multi_res_def()
    let((total_res_value inst res_value term minus_pin plus_pin head_tail_list res_name res_pin_def res_def hash_pin_map)
        total_res_value = 0
        hash_pin_map = makeTable("pin map")
        foreach(inst ggss()
            res_value = get_res_value(inst)
            if(res_value > 0 then
                foreach(term inst~>instTerms
                    if(term~>name == "MINUS" minus_pin = term~>net~>name)
                    if(term~>name == "PLUS" plus_pin = term~>net~>name)
                )
                if(not(member(minus_pin hash_pin_map->?)) then
                    hash_pin_map[minus_pin] = list(plus_pin)
                else
                    if(not(member(plus_pin hash_pin_map[minus_pin]))
                        hash_pin_map[minus_pin] = append1(hash_pin_map[minus_pin] plus_pin)
                    )
                )
                if(not(member(plus_pin hash_pin_map->?)) then
                    hash_pin_map[plus_pin] = list(minus_pin)
                else
                    if(not(member(minus_pin hash_pin_map[plus_pin]))
                        hash_pin_map[plus_pin] = append1(hash_pin_map[plus_pin] minus_pin)
                    )
                )
                total_res_value = total_res_value + get_res_value(inst)
            )
        )
        head_tail_list = get_head_tail(hash_pin_map)
        res_value = print_number_unit(total_res_value)
        res_name = sprintf(nil "R_%s", upperCase(buildString(head_tail_list, "__")))
        res_pin_def = buildString(head_tail_list, ", ")
        res_def = sprintf(nil "    electrical %s;\n    resistor #(.r(%s)) %s(%s);\n", res_pin_def, res_value, res_name, res_pin_def)
        printf(res_def)
        res_def
    )
)

procedure(get_head_tail(in_table)
    let((out_list m_pin p_pins)
        out_list = list()
        foreach(m_pin in_table~>?
            p_pins = in_table[m_pin]
            if(length(p_pins) == 1 out_list = append1(out_list m_pin))
        )
        out_list
    )
)

procedure(get_res_sums()
    let((total_res_value)
        total_res_value = 0
        foreach(inst ggss()
            total_res_value = total_res_value + get_res_value(inst)
        )
        printf("%s", print_number_unit(total_res_value))
        print_number_unit(total_res_value)
    )
)

procedure(printCurrentProbe(@optional (net css()))
    let((currProbe term path simOut nodeName)
        currProbe = "probe -create -flow "
        simOut = ""
        foreach(term net~>net~>allInstTerms
            path = sprintf(nil "${x}.%s", term~>inst~>name)
            nodeName = term~>name
            pin_info = extract_pin(nodeName)
            name_no_lt = car(pin_info)
            pin_range = cadr(pin_info)
            pin_range_list = extract_pin_range(pin_range)
            if(length(pin_range_list) == 0 then
                printf("%s%s.%s\n", currProbe, path, nodeName)
                simOut = sprintf(nil "%s%s", simOut, getSimvisionProbe(nodeName, path))
            else
                pin_start = car(pin_range_list)
                pin_end = cadr(pin_range_list)
                while(pin_start >= pin_end
                    node = sprintf(nil "%s[%d]", name_no_lt, pin_start)
                    printf("%s%s.%s\n", currProbe, path, node)
                    simOut = sprintf(nil "%s%s", simOut, getSimvisionProbe(node, path))
                    pin_start = pin_start - 1
                )
            )
        )
        printf(simOut)
        simOut
    )
)

procedure(getSimvisionProbe(inNode path)
    let((nodeInfo outStr)
        nodeInfo = flattenNode(inNode)
        outStr = "set id [waveform add -signals [subst  {\n"
        outStr = sprintf(nil "%s    {[format \"%s.%s_\\$flow%s \"]}\n", outStr, path, car(nodeInfo), cadr(nodeInfo))
        outStr = sprintf(nil "%s    } ]]\n", outStr)
        outStr = sprintf(nil "%swaveform format $id -trace analogLinear\n", outStr)
        outStr = sprintf(nil "%swaveform axis range $id -for A -min -5e-06 -max 5e-05 -scale linear\n", outStr)
        outStr

    )
)

procedure(get_res_value(@optional (inst css()))
    let((inst_cdf is_res res_value mul_res_value param)
        inst_cdf = getCDF(inst)
        is_res = 0
        res_value = 0
        mul_res_value = 1
        if(member("res" inst_cdf~>parameters~>name) then
            is_res = 1
            foreach(param inst_cdf~>parameters
                if(param~>name == "res" then
                    res_value = evalstring(param~>value)
                )
                if(param~>name == "m" mul_res_value = evalstring(param~>value))
            )
            res_value = res_value * mul_res_value
        )
        res_value
    )
)

procedure(flattenNode(inStr)
    let((pinName pinRange)
        rexCompile("\\(.*\\)\\(\\[.*\\]\\)")
        if(rexExecute(inStr) then
            pinName = rexSubstitute("\\1")
            pinRange = rexSubstitute("\\2")
        else
            pinName = inStr
            pinRange = ""
        )
        list(pinName pinRange)
    )
)

procedure(print_number_unit(in_num)
    let((units_list units_conv_list ii out_str unit_found out_unit out_conv comp_num formated_number)
        units_list = parseString("T G M K 0 m u n p f")
        units_conv_list = parseString("1e12 1e9 1e6 1e3 0.5 1e-3 1e-6 1e-9 1e-12 1e-15")
        ii = 0
        ;printf("i am here -1")
        if(numberp(in_num) then
            ;printf("i am here 0")
            if(in_num > 1e15 || in_num <= 1e-15 then
                ;printf("i am here 1")
                out_str = sprintf(nil "%1.2e", in_num)
            else
                ;printf("i am here 2")
                unit_found = 0
                foreach(unit units_list
                    ii = ii + 1
                    comp_num = evalstring(nthelem(ii units_conv_list))
                    if(in_num >= comp_num  && unit_found == 0 then
                        out_unit = unit
                        out_conv = comp_num
                        unit_found = 1
                    )
                )
                ;printf("i am here 3")
                if(out_conv == 0.5 then
                    formated_number = removing_ending_zero(sprintf(nil "%1.4f", in_num * 1.0))
                    out_unit = ""
                else
                    formated_number = removing_ending_zero(sprintf(nil "%1.4f", in_num * 1.0/out_conv))
                )
                out_str = sprintf(nil "%s%s", formated_number, out_unit)
            )
        else
            out_str = in_num
        )
        out_str
    )
)

procedure(removing_ending_zero(in_str)
    let((out_str)
        if(rexMatchp("\\.", in_str) then
            rexCompile("00*$")
            if(rexExecute(in_str) then
                out_str = rexReplace(in_str, "", 0)
            else
                out_str = in_str
            )
            rexCompile("\\.$")
            if(rexExecute(out_str) then
                out_str = rexReplace(out_str, "", 0)
            )
        else
            out_str = in_str
        )
        out_str
    )
)
procedure(CCSaddVerilogPropertyOnSymbol( libName cellName addViewList )
    let( ( bagId viewId cellList viewName)
        foreach( viewName addViewList
            if( (viewId = ddGetObj( libName cellName viewName )) then
                if( (bagId=dbOpenBag( viewId "a"))   then
                    dbCreateProp( bagId "modelName" "string" cellName)
                    dbSaveBag( bagId)
                    dbCloseBag( bagId "a")
                  );if
              );if
        );foreach
   ); let
) ;procedure
procedure( CCSaddVerilogPropertyToLib( libName addViewList) 
    let( ( viewId cellId viewName)
         if( (libId = ddGetObj( libName nil nil))  then 
             foreach( cellId libId~>cells
                   foreach( viewName addViewList 
                     if(ddGetObj(libName cellId~>name viewName)  then
                        unless(cv=dbOpenCellViewByType(libName cellId~>name viewName nil "a") 
                               error("\n It is not a graphical view\n")
                        );unless
                       if(cv then
                            dbReplaceProp(cv "modelName" 'string cellId~>name) 
                            dbSave(cv)
                            dbClose(cv)
                       ) ;if cv
                    ) ;if view exist
                 ) ;foreach view
            ) ; foreach cell
         ) ;if libId
    ) ;let
) ;procedure CCSaddVerilogPropertyToLib


procedure(print_netlists(@optional (insts ggss()))
    let((inst)
        foreach(inst insts
            printf("    %s\n\n", print_netlist(inst))
        )
    )
)
procedure(print_netlist(@optional (inst css()))
    let((inst_name inst_cellname netlist pin_net_list term pin_net)
        inst_name = inst~>name
        inst_cellname = inst~>cellName
        netlist = sprintf(nil "%s %s(", inst_cellname, inst_name)
        pin_net_list = list()
        foreach(term inst~>instTerms
            pin_net = sprintf(nil ".%s(%s)", rem_lg(term~>name), rep_lg_sq(term~>net~>name))
            pin_net_list = append1(pin_net_list pin_net)
        )
        netlist = sprintf(nil "%s%s);", netlist, buildString(pin_net_list, ", "))
    )
)

procedure(rep_lg_sq(pin_name)
    let((out_name)
        out_name = pin_name
        rexCompile("<")
        out_name = rexReplace(out_name, "[", 0)
        rexCompile(">")
        out_name = rexReplace(out_name, "]", 0)
    )
)
procedure(rem_lg(pin_name)
    let((out_name)
        out_name = pin_name
        rexCompile("<.*>")
        out_name = rexReplace(out_name, "", 0)
    )
)

procedure(CCSToggleDimming()
 if(hiGetCurrentWindow()~>dimmingOn
   then
   hiGetCurrentWindow()~>dimmingOn = nil
   else hiGetCurrentWindow()~>dimmingOn = t
  );if
);procedure

procedure(CCSToggleDimmingWithInstContent()
 hiGetCurrentWindow()~>dimmingOn = t
 if(hiGetCurrentWindow()~>selDisplayInstContent
   then
   hiGetCurrentWindow()~>selDisplayInstContent = nil
   else
   hiGetCurrentWindow()~>selDisplayInstContent = t
  );if
 hiRedraw()
);procedure
procedure(set_mypref()
    drLoadDrf( "~/display.drf" nil )
    hiGetCurrentWindow()->dotStyleMajorGrid=t
    CCSToggleDimming()
    CCSToggleDimmingWithInstContent()
)

procedure(change_name(@optional (insts ggss()))
    let((inst cellname name seq_num new_name)
        foreach(inst insts
            cellname = inst~>cellName
            name = inst~>name
            if(name && rexMatchp("<.*>", name) then
                rexCompile("\\(<.*>\\)")
                rexExecute(name)
                inst_range = rexSubstitute("\\1")
                name = rexReplace(name, "", 0)
            else
                inst_range = ""
            )
            if(name && rexMatchp("^I[0-9]+$", name) then
                rexCompile("^I\\([0-9]+\\)")
                rexExecute(name)
                seq_num = rexSubstitute("\\1")
                if(cellname == "cds_thru" then
                    new_name = strcat("I" lc(cellname) "_" car(inst~>terminals~>net~>name) "_" seq_num inst_range)
                else
                    new_name = strcat("I" lc(cellname) "_" seq_num inst_range)
                )
                printf("New name is %s.", new_name)
                inst~>name = new_name
            )
        )
        schHiCheckAndSave()
    )
)
load("~xwzhang/skill/cp_cells.il")
load("~xwzhang/skill/createTB.il")
