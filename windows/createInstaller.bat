:: ===========================================================================
::  SPDX-FileCopyrightText: © 2018 The Spectrecoin developers
::  SPDX-License-Identifier: MIT/X11
::
::  @author   HLXEasy <helix@spectreproject.io>
::
::  Helper script to build Spectrecoin on Windows using VS2017 and QT.
:: ===========================================================================

IF "%NSIS_DIR%" == "" GOTO NONSIS
:YESNSIS

set CALL_DIR=%cd%

"%NSIS_DIR%\makensisw.exe" Spectrecoin.nsi

echo "Everything is OK"
GOTO END

:NONSIS
@ECHO The NSIS_DIR environment variable was NOT detected!

:END
cd %CALL_DIR%
