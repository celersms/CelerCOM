@echo off
SETLOCAL
TITLE Generating CelerCOM javadoc...
PUSHD "%~dp0\.."
IF EXIST "%JDK%\bin\javadoc.exe" GOTO JDKFOUND
SET JDK=%JDK_HOME%
IF EXIST "%JDK%\bin\javadoc.exe" GOTO JDKFOUND
SET JDK=%JAVA_HOME%
IF EXIST "%JDK%\bin\javadoc.exe" GOTO JDKFOUND
FOR /f "tokens=2*" %%i IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Development Kit" /s 2^>nul ^| find "JavaHome"') DO SET JDK=%%j
IF EXIST "%JDK%\bin\javadoc.exe" GOTO JDKFOUND
FOR /f "tokens=2*" %%i IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\JavaSoft\Java Development Kit" /s 2^>nul ^| find "JavaHome"') DO SET JDK=%%j
IF NOT EXIST "%JDK%\bin\javadoc.exe" GOTO JDKNOTFOUND
:JDKFOUND
rd /s /q javadoc >nul 2>nul
mkdir javadoc 2>nul
"%JDK%\bin\javadoc" -nodeprecatedlist -nohelp -notree -noindex -nonavbar -public -classpath src -d javadoc src/com/celer/COM.java src/com/celer/COMInputStream.java src/com/celer/COMOutputStream.java
GOTO EXIT
:JDKNOTFOUND
ECHO JDK not found. If you have JDK installed set JDK_HOME to point to the JDK location.
:EXIT
pause
POPD
ENDLOCAL
@echo on