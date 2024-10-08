; Copyright Oakwood Technologies BVBA 2020
!define MUI_WELCOMEFINISHPAGE_BITMAP "setup.bmp"

!define PRODUCT_NAME "[[ib.appname]]"
!define PRODUCT_VERSION "[[ib.version]]"
!define PY_VERSION "[[ib.py_version]]"
!define PY_MAJOR_VERSION "[[ib.py_major_version]]"
!define BITNESS "[[ib.py_bitness]]"
!define ARCH_TAG "[[arch_tag]]"
!define INSTALLER_NAME "[[ib.installer_name]]"
!define PRODUCT_ICON "[[icon]]"


; Marker file to tell the uninstaller that it's a user installation
!define USER_INSTALL_MARKER _user_install_marker
 
SetCompressor lzma

!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_INSTALLMODE_DEFAULT_CURRENTUSER
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR "[[ib.appname]]"
[% if ib.py_bitness == 64 %]
!define MULTIUSER_INSTALLMODE_FUNCTION correct_prog_files
[% endif %]
!include MultiUser.nsh

[% block modernui %]
; Modern UI installer stuff 
!include "MUI2.nsh"
!define MUI_ABORTWARNING
!define MUI_ICON "[[icon]]"
!define MUI_UNICON "[[icon]]"

; UI pages
[% block ui_pages %]
; !insertmacro MUI_PAGE_WELCOME
[% if license_file %]
!insertmacro MUI_PAGE_LICENSE [[license_file]]
[% endif %]
; !insertmacro MULTIUSER_PAGE_INSTALLMODE
; !insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_PAGE_FINISH
[% endblock ui_pages %]
!insertmacro MUI_LANGUAGE "English"
[% endblock modernui %]

Name "${PRODUCT_NAME}"
OutFile "${INSTALLER_NAME}"
ShowInstDetails show


Section -SETTINGS
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
SectionEnd

[% block sections %]

Section "!${PRODUCT_NAME}" sec_app
  ; Kill running Python processes (such as Automagica)
  Execwait '"$SYSDIR\taskkill.exe" /F /IM python.exe /T'
  Execwait '"$SYSDIR\taskkill.exe" /F /IM pythonw.exe /T'
  Execwait '"$SYSDIR\taskkill.exe" /F /IM automagica.exe /T'

  SetRegView [[ib.py_bitness]]
  SectionIn RO
  File ${PRODUCT_ICON}
  SetOutPath "$INSTDIR\pkgs"
  File /r "pkgs\*.*"
  SetOutPath "$INSTDIR"

  ; Marker file for per-user install
  StrCmp $MultiUser.InstallMode CurrentUser 0 +3
    FileOpen $0 "$INSTDIR\${USER_INSTALL_MARKER}" w
    FileClose $0
    SetFileAttributes "$INSTDIR\${USER_INSTALL_MARKER}" HIDDEN

  [% block install_files %]
  ; Install files
  [% for destination, group in grouped_files %]
    SetOutPath "[[destination]]"
    [% for file in group %]
      File "[[ file ]]"
    [% endfor %]
  [% endfor %]
  
  ; Install directories
  [% for dir, destination in ib.install_dirs %]
    SetOutPath "[[ pjoin(destination, dir) ]]"
    File /r "[[dir]]\*.*"
  [% endfor %]
  [% endblock install_files %]
  
  ; [% block install_shortcuts %]
  ; ; Install shortcuts
  ; ; The output path becomes the working directory for shortcuts
  ; SetOutPath "%HOMEDRIVE%\%HOMEPATH%"
  ; [% if single_shortcut %]
  ;   [% for scname, sc in ib.shortcuts.items() %]
  ;   CreateShortCut "$SMPROGRAMS\[[scname]].lnk" "[[sc['target'] ]]" \
  ;     '[[ sc['parameters'] ]]' "$INSTDIR\[[ sc['icon'] ]]"
  ;   [% endfor %]
  ; [% else %]
  ;   [# Multiple shortcuts: create a directory for them #]
  ;   CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  ;   [% for scname, sc in ib.shortcuts.items() %]
  ;   CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\[[scname]].lnk" "[[sc['target'] ]]" \
  ;     '[[ sc['parameters'] ]]' "$INSTDIR\[[ sc['icon'] ]]"
  ;   [% endfor %]
  ; [% endif %]
  ; SetOutPath "$INSTDIR"
  
  ; [% endblock install_shortcuts %]
  
  ; ReadEnvStr $0 AUTOMAGICA_PORTAL_URL
  ; ${If} $0 == ""
  ;   StrCpy $0 "https://portal.automagica.com"
  ; ${EndIf}

  ; WriteINIStr "$DESKTOP\Automagica Portal.url" "InternetShortcut" "URL" $0
  
  ; This sets the working directory of the shortcuts to the User's home directory
  SetOutPath "$PROFILE"

  CreateShortCut "$SMPROGRAMS\Automagica Flow.lnk" "$INSTDIR\Python\pythonw.exe" "-m automagica.cli flow new" "$INSTDIR\${PRODUCT_ICON}" 0 SW_SHOWNORMAL "" "Automagica Flow"
  CreateShortCut "$DESKTOP\Automagica Flow.lnk" "$INSTDIR\Python\pythonw.exe" "-m automagica.cli flow new" "$INSTDIR\${PRODUCT_ICON}" 0 SW_SHOWNORMAL "" "Automagica Flow"

  CreateShortCut "$SMPROGRAMS\Automagica Lab.lnk" "$INSTDIR\Python\pythonw.exe" "-m automagica.cli lab new" "$INSTDIR\${PRODUCT_ICON}" 0 SW_SHOWNORMAL "" "Automagica Lab"
  CreateShortCut "$DESKTOP\Automagica Lab.lnk" "$INSTDIR\Python\pythonw.exe" "-m automagica.cli lab new" "$INSTDIR\${PRODUCT_ICON}" 0 SW_SHOWNORMAL "" "Automagica Lab"

  CreateShortCut "$SMPROGRAMS\Automagica Bot.lnk" "$INSTDIR\Python\pythonw.exe" "-m automagica.cli bot" "$INSTDIR\${PRODUCT_ICON}" 0 SW_SHOWNORMAL "" "Automagica Bot"
  CreateShortCut "$DESKTOP\Automagica Bot.lnk" "$INSTDIR\Python\pythonw.exe" "-m automagica.cli bot" "$INSTDIR\${PRODUCT_ICON}" 0 SW_SHOWNORMAL "" "Automagica Bot"

  ; Reset to previous value
  SetOutPath "$INSTDIR"

  [% block install_commands %]
  [% if has_commands %]
    DetailPrint "Setting up command-line launchers..."
    nsExec::ExecToLog '[[ python ]] -Es "$INSTDIR\_assemble_launchers.py" [[ python ]] "$INSTDIR\bin"'

    StrCmp $MultiUser.InstallMode CurrentUser 0 AddSysPathSystem
      ; Add to PATH for current user
      nsExec::ExecToLog '[[ python ]] -Es "$INSTDIR\_system_path.py" add_user "$INSTDIR\bin"'
      GoTo AddedSysPath
    AddSysPathSystem:
      ; Add to PATH for all users
      nsExec::ExecToLog '[[ python ]] -Es "$INSTDIR\_system_path.py" add "$INSTDIR\bin"'
    AddedSysPath:
  [% endif %]
  [% endblock install_commands %]
  
  ; Byte-compile Python files.
  DetailPrint "Byte-compiling Python modules..."
  nsExec::ExecToLog '[[ python ]] -m compileall -q "$INSTDIR\pkgs"'
  WriteUninstaller $INSTDIR\uninstall.exe

  ; Install Automagica
  DetailPrint "Installing Automagica dependencies..."
  SetOutPath "$INSTDIR"
  ; Below line is to have an auto-updated installer
  ; ExecWait "$\"$INSTDIR\Python\python.exe$\" -m pip install automagica -U"
  ExecWait "$\"$INSTDIR\Python\python.exe$\" -m pip uninstall pywin32 -y"
  ExecWait "$\"$INSTDIR\Python\python.exe$\" -m pip install pywin32==227"

  ExecWait "$\"$INSTDIR\Python\python.exe$\" -m wheel install-scripts $\"$INSTDIR\Automagica.whl$\""

  ; Connect to Automagica Portal
  DetailPrint "Configuring Automagica bot..."
  SetOutPath "$INSTDIR"
  ExecWait "$\"$INSTDIR\Python\python.exe$\" -m automagica.config $\"$EXEPATH$\""
  
  ; Launch the Automagica Bot
  Exec "$\"$INSTDIR\Python\pythonw.exe$\" -m automagica.cli bot"
  

  ; Add ourselves to Add/remove programs
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
                   "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
                   "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
                   "InstallLocation" "$INSTDIR"
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
                   "DisplayIcon" "$INSTDIR\${PRODUCT_ICON}"
  [% if ib.publisher is not none %]
    WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
                     "Publisher" "[[ib.publisher]]"
  [% endif %]
  WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
                   "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegDWORD SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
                   "NoModify" 1
  WriteRegDWORD SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" \
                   "NoRepair" 1

  ; Check if we need to reboot
  IfRebootFlag 0 noreboot
    MessageBox MB_YESNO "A reboot is required to finish the installation. Do you wish to reboot now?" \
                /SD IDNO IDNO noreboot
      Reboot
  noreboot:
SectionEnd

Section "Uninstall"
  SetRegView [[ib.py_bitness]]
  SetShellVarContext all
  IfFileExists "$INSTDIR\${USER_INSTALL_MARKER}" 0 +3
    SetShellVarContext current
    Delete "$INSTDIR\${USER_INSTALL_MARKER}"

  Delete "$SMSTARTUP\${PRODUCT_NAME}.lnk"
  Delete $INSTDIR\uninstall.exe
  Delete "$INSTDIR\${PRODUCT_ICON}"
  RMDir /r "$INSTDIR\pkgs"

  ; Delete shortcuts
  Delete "$SMPROGRAMS\Automagica Flow.lnk"
  Delete "$DESKTOP\Automagica Flow.lnk"

  Delete "$SMPROGRAMS\Automagica Lab.lnk"
  Delete "$DESKTOP\Automagica Lab.lnk"

  Delete "$SMPROGRAMS\Automagica Bot.lnk"
  Delete "$DESKTOP\Automagica Bot.lnk"

  ; Remove ourselves from %PATH%
  [% block uninstall_commands %]
  [% if has_commands %]
    nsExec::ExecToLog '[[ python ]] -Es "$INSTDIR\_system_path.py" remove "$INSTDIR\bin"'
  [% endif %]
  [% endblock uninstall_commands %]

  [% block uninstall_files %]
  ; Uninstall files
  [% for file, destination in ib.install_files %]
    Delete "[[pjoin(destination, file)]]"
  [% endfor %]
  ; Uninstall directories
  [% for dir, destination in ib.install_dirs %]
    RMDir /r "[[pjoin(destination, dir)]]"
  [% endfor %]
  [% endblock uninstall_files %]

  [% block uninstall_shortcuts %]
  ; Uninstall shortcuts
  [% if single_shortcut %]
    [% for scname in ib.shortcuts %]
      Delete "$SMPROGRAMS\[[scname]].lnk"
    [% endfor %]
  [% else %]
    RMDir /r "$SMPROGRAMS\${PRODUCT_NAME}"
  [% endif %]
  [% endblock uninstall_shortcuts %]
  RMDir $INSTDIR
  DeleteRegKey SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
SectionEnd

[% endblock sections %]

; Functions

Function .onMouseOverSection
    ; Find which section the mouse is over, and set the corresponding description.
    FindWindow $R0 "#32770" "" $HWNDPARENT
    GetDlgItem $R0 $R0 1043 ; description item (must be added to the UI)

    [% block mouseover_messages %]
    StrCmp $0 ${sec_app} "" +2
      SendMessage $R0 ${WM_SETTEXT} 0 "STR:${PRODUCT_NAME}"
    
    [% endblock mouseover_messages %]
FunctionEnd

Function .onInit
  !insertmacro MULTIUSER_INIT
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
FunctionEnd

[% if ib.py_bitness == 64 %]
Function correct_prog_files
  ; The multiuser machinery doesn't know about the different Program files
  ; folder for 64-bit applications. Override the install dir it set.
  StrCmp $MultiUser.InstallMode AllUsers 0 +2
    StrCpy $INSTDIR "$PROGRAMFILES64\${MULTIUSER_INSTALLMODE_INSTDIR}"
FunctionEnd
[% endif %]