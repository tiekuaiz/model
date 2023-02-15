; generic .cdsinit for all projects
; project-specific user customizations follow
envSetVal("asimenv" "saveAsCellview" 'boolean t) ;save cellview instead of directory
;envSetVal("asimenv" "saveAsCellview" 'boolean t) ;save cellview instead of directory
envSetVal("asimenv" "schematicBased" 'boolean "nil")
;envSetVal("asimenv.startup" "hostMode" 'string "distributed")
;envSetVal("asimenv.startup" "simulator" 'string  "ams")  
;envSetVal("asimenv" "stateName" 'string  "ams_state1")
envSetVal("viva.graphFrame" "width" 'string "1800" )
envSetVal("viva.graphFrame" "height" 'string "1000" )
envSetVal("ui" "ciwCmdInputLines" 'int 10)
envSetVal("viva.rectGraph" "background" 'string "black")
envSetVal("ams.tranOpts"  "finalTimeOp"  'string  "no")
envSetVal("ams.outputs"  "elementInfo"  'boolean  "nil")
envSetVal("ams.outputs"  "modelParamInfo"  'boolean  "nil" )
envSetVal("ams.outputs"  "outputParamInfo"  'boolean  "nil")
envSetVal("textedit"  "useExternalEditor"  'boolean  t)
envSetVal("viva.digitalBusTrace" "radix" 'string "udecimal")
envSetVal("wavescan.trace" "lineStyle" 'string "solid")
envSetVal("wavescan.trace" "lineThickness" 'string "thick")
;envSetVal("ams.envOpts" "netlisterMode" 'string "OSS-based")
hiSetFont("label" ?name  "Open Sans" ?size 14)
hiSetFont("text" ?name  "Open Sans" ?size 14)
;envSetVal("ams.envOpts"  "rulesAndModulesFiles"  'string  "nil")
;envSetVal("ams.envOpts"  "rulesNames"  'string  "nil")
envSetVal("viva.table" "significantDigits" 'string "7")
envSetVal("ams.envOpts" "enableAMSDflex" 'toggle '(t))
sosShowCheckOutsOnExit = nil
ddsOpenLibManager()
displayMode("strip")
;editor="nedit"
schPlotOptions = '(nil
copy            1
outputfile      ""
plotter         "Encapsulated PostScript FILE Color"
papersize       "A"
offset          (0.0 0.0)
unit            "mm"
orientation     "automatic"
display         "display"
tmpdir          "/usr/tmp"
mail            t
)
;;hiSetBindKeys( "Schematics" list( list("<Key>d" "schHiDescendRead()")))
;;hiSetBindKeys( "Schematics" list( list("<Key>g" "schHiDescendEdit()")))
envSetVal("viva.digitalBusTrace" "radix" 'string "udecimal")
load("~/mykey.il")
drLoadDrf( "~/display.drf" nil )
envSetVal("ams.envOpts" "cleanSnapShot" 'toggle list(t))
editor="gvim"
hdlReadOnlyModeEditorCommand="gvim"
envSetVal("layoutXL" "cphLayoutSync"  'boolean t)
;envSetVal("asimenv.startup" "projectDir" 'string "/projects/simResults2/xzhang02")
envSetVal("schematic" "schWindowBBox" 'string "((-1000 0)(800 1000))")
load("~/myskill.il")
deRegUserTriggers("analogArtist-schematic" nil nil 'add_views)
deRegUserTriggers("analogArtist-schematic" nil nil 'show_my_menu)
envSetVal( "ams.compilerOpts"  "ncvlogArguments" 'string  "-NOWARN DLNCML" )
envSetVal( "ams.ncverilogOpts"  "additionalArg"  'string "-NOWARN DLNCML" )
envSetVal("cdsLibManager.main" "showCategoriesOn" 'boolean t)
envSetVal("cdsLibManager" "showCategoriesOn" 'boolean t)
envSetVal("schematic" "wireColor" 'string "cadetBlue")

load "./adv/env/path.il"
;#load calibre
;##################################################
;setSkillPath("/tools/mentor/calibre2018/aoi_cal_2018.2_33.24/shared/pkgs/icv.aoi/tools/queryskl")
;load("calibre.skl")
;END OF THE SITE CUSTOMIZATION FILE

;##################################################
;#load bindkeys and multipath
;##################################################
;load "./init.il"

;load( strcat(getShellEnvVar("CDSDM_PATH") "/init.il") )
drLoadDrf( "~/display.drf" nil )
envSetVal("graphic" "dotStyleMajorGrid" 'boolean t)
envSetVal("layout" "dotStyleMajorGrid" 'boolean t)
load("~/skill/netlistAndRunCB.il")
envSetVal("digitalSim.netlisterOpts" "termDirectionMismatch" 'string "error")
envSetVal("digitalSim.netlisterOpts" "termMismatch" 'string "error")
envSetVal( "ams.envOpts" "forceUnlOverOSS" 'boolean t)
envSetVal("asimenv" "createOceanScriptBeforeSimulation" 'boolean t)
vmsParseAllModules = t
