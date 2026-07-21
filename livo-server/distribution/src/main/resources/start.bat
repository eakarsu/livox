@echo off

if "%AEON_HOME%"=="" (
	echo AEON_HOME must point to the absolute Livo runtime directory.
	exit /b 1
)

rem Remote JMX is intentionally disabled by default. Operators who need it
rem must add authenticated, TLS-enabled settings through deployment tooling.
java %JAVA_OPTS% -Duser.language=en -Duser.country=US -Dfelix.fileinstall.dir="%AEON_HOME%\conf\services" -Dfelix.cm.dir="%AEON_HOME%\conf\services" -Dlivo.home="%AEON_HOME%" -jar bin/felix.jar
