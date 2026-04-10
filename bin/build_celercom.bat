@echo off
REM === CONFIG BEGIN ================================

REM Flat Assembler (www.flatassembler.net) installation path.
REM FASM is used to compile the native code to support virtual COM ports.
REM SET FASM_HOME=C:\Tools\fasmw17003

REM The JDK 9 or later installation path
SET JDK9=\Tools\jdk-16.0.2

REM The JDK 6 or later installation path (optional)
SET JDK6=\Tools\jdk1.8.0_202

REM === CONFIG END ==================================
TITLE Rebuilding CelerCOM...
PUSHD "%~dp0\.."
IF EXIST "%JDK9%\bin\javac.exe" GOTO JDK9FOUND
SET JDK9=%JDK_HOME%
IF EXIST "%JDK9%\bin\javac.exe" GOTO JDK9FOUND
SET JDK9=%JAVA_HOME%
IF EXIST "%JDK9%\bin\javac.exe" GOTO JDK9FOUND
FOR /f "tokens=2*" %%i IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Development Kit" /s 2^>nul ^| find "JavaHome"') DO SET JDK9=%%j
IF EXIST "%JDK9%\bin\javac.exe" GOTO JDK9FOUND
FOR /f "tokens=2*" %%i IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\JavaSoft\Java Development Kit" /s 2^>nul ^| find "JavaHome"') DO SET JDK9=%%j
IF EXIST "%JDK9%\bin\javac.exe" GOTO JDK9FOUND
ECHO If a JDK v9 or later is installed, set the JDK9 environment variable to point to where the JDK is located.
GOTO EXIT
:JDK9FOUND
IF EXIST "%JDK6%\bin\javac.exe" GOTO JDK6FOUND
SET JDK6=%JDK9%
:JDK6FOUND
IF EXIST "%JDK6%\jre\lib\rt.jar" GOTO RT6FOUND
ECHO %JDK6%\jre\lib\rt.jar not found
GOTO EXIT
:RT6FOUND
rd /s /q classes\celer\com >nul 2>nul
mkdir classes\celer 2>nul

IF EXIST "%FASM_HOME%\fasm.exe" GOTO FASMFOUND
ECHO FASM not found. To compile the native code for compatibility with virtual COM
ECHo ports download FASM from www.flatassembler.net and set FASM_HOME configuration
ECHO option to the current FASM location.
GOTO DOJAVA
:FASMFOUND
mkdir classes\celer\jni 2>nul
"%FASM_HOME%\fasm" src\jni\Windows\celer32.asm classes\celer\jni\celer32.dll
IF %ERRORLEVEL% NEQ 0 GOTO EXIT
"%FASM_HOME%\fasm" src\jni\Windows\celer64.asm classes\celer\jni\celer64.dll
IF %ERRORLEVEL% NEQ 0 GOTO EXIT
"%FASM_HOME%\fasm" src\jni\Linux\celer32.asm classes\celer\jni\celer32.o
IF %ERRORLEVEL% NEQ 0 GOTO EXIT
"%FASM_HOME%\fasm" src\jni\Linux\celer64.asm classes\celer\jni\celer64.o
IF %ERRORLEVEL% NEQ 0 GOTO EXIT
REM "%FASM_HOME%\fasmarm" src\jni\Windows\aarch32.asm classes\celer\jni\aarch32.dll
ECHO === Linux JNI drivers: ========================================================
ECHO Copy celer32.o and celer64.o from classes\celer\jni to Linux and link:
ECHO ld -m elf_i386 -shared -z noexecstack -o libceler32.so -soname libceler32.so celer32.o
ECHO ld -m elf_x86_64 -shared -z noexecstack -o libceler64.so -soname libceler64.so celer64.o
ECHO strip --strip-all libceler32.so
ECHO strip --strip-all libceler64.so
ECHO ===============================================================================
:DOJAVA

REM Get the CelerCOM version
SET LIB_VER=0.0.0
FOR /F "tokens=*" %%i IN (src\VERSION.txt) DO SET LIB_VER=%%i

REM Compile CelerCOM source code
"%JDK6%\bin\javac" -source 1.5 -target 1.5 -bootclasspath "%JDK6%\jre\lib\rt.jar" -d classes\celer -g:lines -classpath src src\com\celer\TTY.java
IF %ERRORLEVEL% NEQ 0 GOTO EXIT

REM Update the build number and generate the Manifest
SET BLD=0
FOR /F "tokens=*" %%i IN (src\CelerCOM.bld) DO SET BLD=%%i
SET /A BLD=BLD+1
(ECHO %BLD%) >src\CelerCOM.bld
ECHO New build number: %BLD%
(
ECHO Manifest-Version: 1.0
ECHO DeliveryID: CelerCOM_%LIB_VER%b%BLD%
ECHO Created-By: CelerSMS
ECHO Copyright: CelerSMS, 2018-2026
ECHO.
) >classes\Celer.MF

REM Create the jar
"%JDK6%\bin\jar" cmf classes\Celer.MF CelerCOM.jar -C classes\celer .

REM Create the bundle for Maven Central
SET MVN_BUNDLE=mvn\com\celersms\celercom\%LIB_VER%
rd /s /q mvn >nul 2>nul
mkdir %MVN_BUNDLE%
copy /Y /B CelerCOM.jar %MVN_BUNDLE%\celercom-%LIB_VER%.jar 2>nul
(
ECHO ^<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org"^>
ECHO  ^<modelVersion^>4.0.0^</modelVersion^>
ECHO  ^<groupId^>com.celersms^</groupId^>
ECHO  ^<artifactId^>celercom^</artifactId^>
ECHO  ^<version^>%LIB_VER%^</version^>
ECHO  ^<packaging^>jar^</packaging^>
ECHO  ^<name^>CelerCOM^</name^>
ECHO  ^<description^>Lightweight Java library to interact with external devices over COM ports, for example: USB, virtual COM. It can be used to interact with TTY and FIFO files as well.^</description^>
ECHO  ^<url^>https://www.celersms.com/CelerCOM.htm^</url^>
ECHO  ^<licenses^>
ECHO   ^<license^>
ECHO    ^<name^>MIT License^</name^>
ECHO    ^<url^>https://github.com/celersms/CelerCOM/blob/master/LICENSE^</url^>
ECHO   ^</license^>
ECHO  ^</licenses^>
ECHO  ^<developers^>
ECHO   ^<developer^>
ECHO    ^<name^>Victor Celer^</name^>
ECHO    ^<email^>admin@celersms.com^</email^>
ECHO    ^<organization^>CelerSMS^</organization^>
ECHO    ^<organizationUrl^>https://www.celersms.com^</organizationUrl^>
ECHO   ^</developer^>
ECHO  ^</developers^>
ECHO  ^<scm^>
ECHO   ^<connection^>scm:git:https://github.com/celersms/CelerCOM.git^</connection^>
ECHO   ^<developerConnection^>scm:git:https://github.com/celersms/CelerCOM.git^</developerConnection^>
ECHO   ^<url^>https://github.com/celersms/CelerCOM^</url^>
ECHO  ^</scm^>
ECHO ^</project^>
) >%MVN_BUNDLE%\celercom-%LIB_VER%.pom
"%JDK6%\bin\jar" cMf %MVN_BUNDLE%\celercom-%LIB_VER%-sources.jar -C src com -C src jni
"%JDK6%\bin\jar" cMf %MVN_BUNDLE%\celercom-%LIB_VER%-javadoc.jar javadoc

REM Sign the files and package the Maven bundle
ECHO.
SET /P GPG_PWD=Enter GPG passphrase: 
FOR %%F IN (celercom-%LIB_VER%.jar celercom-%LIB_VER%.pom celercom-%LIB_VER%-sources.jar celercom-%LIB_VER%-javadoc.jar) DO CALL :SGN %%F
"%JDK6%\bin\jar" cMf celercom-%LIB_VER%-bundle.zip -C mvn .

:EXIT
rd /s /q classes\celer\com mvn >nul
pause
POPD
@echo on
GOTO :EOF

:SGN
echo %GPG_PWD%|gpg --batch --pinentry-mode loopback --passphrase-fd 0 --yes --detach-sign --armor -o %MVN_BUNDLE%\%1.asc %MVN_BUNDLE%\%1
@certutil -hashfile %MVN_BUNDLE%\%1 MD5  | findstr /v ":" >%MVN_BUNDLE%\%1.md5
@certutil -hashfile %MVN_BUNDLE%\%1 SHA1 | findstr /v ":" >%MVN_BUNDLE%\%1.sha1
