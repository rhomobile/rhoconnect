;======================================================
; Include
 
  !include "MUI.nsh"
  !include "EnvVarUpdate.nsh"
 
;======================================================
; Installer Information
 
  Name "RhoSync"
  OutFile "RhoSync_setup.exe"
  InstallDir C:\RhoSync
  BrandingText " "
;======================================================
; Modern Interface Configuration
 
  !define MUI_ICON "icon.ico" 
  !define MUI_UNICON "icon.ico"     
  !define MUI_HEADERIMAGE
  !define MUI_ABORTWARNING
  !define MUI_COMPONENTSPAGE_SMALLDESC
  !define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
  !define MUI_FINISHPAGE
  !define MUI_FINISHPAGE_TEXT "Thank you for installing RhoSync. \r\n\n\n"
 
 
;======================================================
; Pages
 
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  Page custom customerConfig
  !insertmacro MUI_PAGE_FINISH
 
;======================================================
; Languages
 
  !insertmacro MUI_LANGUAGE "English"
 
;======================================================
; Reserve Files
 
  ReserveFile "configUi.ini"
  !insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
 
 
;======================================================
; Variables
  var varApacheEmail
  var varApachePort
  var varDbPass
 
;======================================================
; Sections

# start default section
section
 
    # set the installation directory as the destination for the following actions
    setOutPath $INSTDIR
 
    # create the uninstaller
    writeUninstaller "$INSTDIR\uninstall.exe"
 
    # create a shortcut named "new shortcut" in the start menu programs directory
    # point the new shortcut at the program uninstaller
    createShortCut "$SMPROGRAMS\Uninstall RhoSync.lnk" "$INSTDIR\uninstall.exe"
sectionEnd
 
# uninstaller section start
section "uninstall"
 
    # first, delete the uninstaller
    delete "$INSTDIR\uninstall.exe"
 
    # second, remove the link from the start menu
    delete "$SMPROGRAMS\Uninstall RhoSync.lnk"
 
    ExecWait 'net stop apache2.2'
    ExecWait 'net stop redis'
    ExecWait 'net stop rhosync-1'
    ExecWait 'net stop rhosync-2'
    ExecWait 'net stop rhosync-3'
    ExecWait 'sc delete apache2.2'
    ExecWait 'sc delete redis'
    ExecWait 'sc delete rhosync-1'
    ExecWait 'sc delete rhosync-2'
    ExecWait 'sc delete rhosync-3'

    Push "PATH" 
    Push "R" 
    Push "HKLM" 
    Push "$INSTDIR\ruby\bin"
    Call un.EnvVarUpdate
    Pop $R0

    Push "PATH" 
    Push "R" 
    Push "HKLM" 
    Push "$INSTDIR\redis-2.4.10"
    Call un.EnvVarUpdate
    Pop $R0

    DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" REDIS_HOME

    RMDir /r /REBOOTOK $INSTDIR
 

# uninstaller section end
sectionEnd

 
Section "Apache" apache2Section
 
  SetOutPath $INSTDIR
 
  File /r "apache2"

  Push $INSTDIR
  Push "\"
  Call StrSlash
  Pop $R0
  

  Push SERVERROOT
  Push $R0/apache2
  Push all
  Push all
  Push $INSTDIR\apache2\conf\httpd.conf
  Call AdvReplaceInFile 
 
  Push DOCROOT
  Push $R0/apache2/htdocs
  Push all
  Push all
  Push $INSTDIR\apache2\conf\httpd.conf
  Call AdvReplaceInFile 

  Push CGIBIN
  Push $R0/apache2/cgi-bin
  Push all
  Push all
  Push $INSTDIR\apache2\conf\httpd.conf
  Call AdvReplaceInFile 
 

SectionEnd
 
Section "Ruby" rubySection
 
  SetOutPath $INSTDIR
 
  File /r "ruby"
 
  ;add to path here

  Push "PATH" 
  Push "P" 
  Push "HKLM" 
  Push "$INSTDIR\ruby\bin"
  Call EnvVarUpdate
  Pop $R0


SectionEnd

Section "Redis" redisSection
 
  SetOutPath $INSTDIR
 
  File /r "redis-2.4.10"
 
  ;add to path here

  Push "PATH" 
  Push "P" 
  Push "HKLM" 
  Push "$INSTDIR\redis-2.4.10"
  Call EnvVarUpdate
  Pop $R0

  Push "REDIS_HOME" 
  Push "P" 
  Push "HKLM" 
  Push "$INSTDIR\redis-2.4.10"
  Call EnvVarUpdate
  Pop $R0

  ExecWait '$INSTDIR\redis-2.4.10\redis-service.exe install' $0
  StrCmp $0 "0" continue wrong

  wrong:
    MessageBox MB_OK "Error installing service"
  
  continue:
  
  ExecWait 'net start redis'

SectionEnd

Section "rhosync" rhosyncSection
 
  SetOutPath $INSTDIR
 
  File /r "rhosync"
 
  ExecWait '$INSTDIR\rhosync\services\rhosync-service1.exe install' $0
  ExecWait '$INSTDIR\rhosync\services\rhosync-service2.exe install' $0
  ExecWait '$INSTDIR\rhosync\services\rhosync-service3.exe install' $0
 
  ExecWait 'net start rhosync-1'
  ExecWait 'net start rhosync-2'
  ExecWait 'net start rhosync-3'
SectionEnd


;======================================================
;Descriptions
 
  ;Language strings
  LangString DESC_InstallApache ${LANG_ENGLISH} "This installs the Apache 2.2 webserver"
  LangString DESC_InstallRuby ${LANG_ENGLISH} "This installs ruby 1.8.7 with preinstalled gems for rhosync"
  LangString DESC_InstallRedis ${LANG_ENGLISH} "This installs redis 1.2.6"
  
  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${apache2Section} $(DESC_InstallApache)
  !insertmacro MUI_DESCRIPTION_TEXT ${redisSection} $(DESC_InstallRedis)
  !insertmacro MUI_DESCRIPTION_TEXT ${rubySection} $(DESC_InstallRuby)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;======================================================
; Functions
 
Function .onInit
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "configUi.ini"
FunctionEnd 
;==============================================================
; Custom functions

LangString TEXT_IO_TITLE ${LANG_ENGLISH} "Configuration page"
LangString TEXT_IO_SUBTITLE ${LANG_ENGLISH} "This page will update application files based on your system configuration."


Function customerConfig
   !insertmacro MUI_HEADER_TEXT "$(TEXT_IO_TITLE)" "$(TEXT_IO_SUBTITLE)"
   !insertmacro MUI_INSTALLOPTIONS_DISPLAY "configUi.ini"
   !insertmacro MUI_INSTALLOPTIONS_READ $varApacheEmail "configUi.ini" "Field 3" "State"
   !insertmacro MUI_INSTALLOPTIONS_READ $varApachePort "configUi.ini" "Field 4" "State"

   Push SERVERADMIN
   Push $varApacheEmail
   Push all
   Push all
   Push $INSTDIR\apache2\conf\httpd.conf
   Call AdvReplaceInFile
 
   Push SERVERPORT
   Push $varApachePort
   Push all
   Push all
   Push $INSTDIR\apache2\conf\httpd.conf
   Call AdvReplaceInFile

   ExecWait '"$INSTDIR\apache2\bin\httpd.exe" -k install'
   ExecWait 'net start Apache2.2'

FunctionEnd

 
Function AdvReplaceInFile
Exch $0 ;file to replace in
Exch
Exch $1 ;number to replace after
Exch
Exch 2
Exch $2 ;replace and onwards
Exch 2
Exch 3
Exch $3 ;replace with
Exch 3
Exch 4
Exch $4 ;to replace
Exch 4
Push $5 ;minus count
Push $6 ;universal
Push $7 ;end string
Push $8 ;left string
Push $9 ;right string
Push $R0 ;file1
Push $R1 ;file2
Push $R2 ;read
Push $R3 ;universal
Push $R4 ;count (onwards)
Push $R5 ;count (after)
Push $R6 ;temp file name
 
  GetTempFileName $R6
  FileOpen $R1 $0 r ;file to search in
  FileOpen $R0 $R6 w ;temp file
   StrLen $R3 $4
   StrCpy $R4 -1
   StrCpy $R5 -1
 
loop_read:
 ClearErrors
 FileRead $R1 $R2 ;read line
 IfErrors exit
 
   StrCpy $5 0
   StrCpy $7 $R2
 
loop_filter:
   IntOp $5 $5 - 1
   StrCpy $6 $7 $R3 $5 ;search
   StrCmp $6 "" file_write2
   StrCmp $6 $4 0 loop_filter
 
StrCpy $8 $7 $5 ;left part
IntOp $6 $5 + $R3
IntCmp $6 0 is0 not0
is0:
StrCpy $9 ""
Goto done
not0:
StrCpy $9 $7 "" $6 ;right part
done:
StrCpy $7 $8$3$9 ;re-join
 
IntOp $R4 $R4 + 1
StrCmp $2 all file_write1
StrCmp $R4 $2 0 file_write2
IntOp $R4 $R4 - 1
 
IntOp $R5 $R5 + 1
StrCmp $1 all file_write1
StrCmp $R5 $1 0 file_write1
IntOp $R5 $R5 - 1
Goto file_write2
 
file_write1:
 FileWrite $R0 $7 ;write modified line
Goto loop_read
 
file_write2:
 FileWrite $R0 $R2 ;write unmodified line
Goto loop_read
 
exit:
  FileClose $R0
  FileClose $R1
 
   SetDetailsPrint none
  Delete $0
  Rename $R6 $0
  Delete $R6
   SetDetailsPrint both
 
Pop $R6
Pop $R5
Pop $R4
Pop $R3
Pop $R2
Pop $R1
Pop $R0
Pop $9   
Pop $8
Pop $7
Pop $6
Pop $5
Pop $0
Pop $1
Pop $2
Pop $3
Pop $4
FunctionEnd



; Push $filenamestring (e.g. 'c:\this\and\that\filename.htm')
; Push "\"
; Call StrSlash
; Pop $R0
; ;Now $R0 contains 'c:/this/and/that/filename.htm'
Function StrSlash
  Exch $R3 ; $R3 = needle ("\" or "/")
  Exch
  Exch $R1 ; $R1 = String to replacement in (haystack)
  Push $R2 ; Replaced haystack
  Push $R4 ; $R4 = not $R3 ("/" or "\")
  Push $R6
  Push $R7 ; Scratch reg
  StrCpy $R2 ""
  StrLen $R6 $R1
  StrCpy $R4 "\"
  StrCmp $R3 "/" loop
  StrCpy $R4 "/"  
loop:
  StrCpy $R7 $R1 1
  StrCpy $R1 $R1 $R6 1
  StrCmp $R7 $R3 found
  StrCpy $R2 "$R2$R7"
  StrCmp $R1 "" done loop
found:
  StrCpy $R2 "$R2$R4"
  StrCmp $R1 "" done loop
done:
  StrCpy $R3 $R2
  Pop $R7
  Pop $R6
  Pop $R4
  Pop $R2
  Pop $R1
  Exch $R3
FunctionEnd

