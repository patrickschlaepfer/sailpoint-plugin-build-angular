:: setup.bat
:: Creates a skeleton for SailPoint Plugin
::
@echo off
 
set ROOT_PROJECT_NAME=scaffolding_root
set PLUGIN_NAME=PluginName
set PLUGIN_DISPLAY_NAME=Plugin Display Name
set PLUGIN_VERSION=1.0.0-SNAPSHOT
set SOURCECOMPATIBILITY=1.8
set TARGETCOMPATIBILITY=1.8
set VERSION=1.0
 
REM remove all gradle files
rd .gradle /S /Q
rd gradle /S /Q
del build.gradle /Q
del gradlew.bat /Q
del settings.gradle /Q
del gradle.properties /Q
 
rd restapi /S /Q
rd plugin /S /Q
 
@echo **** Getting and installing gradle
 
REM get gradle
cmd /c "gradle init"
cmd /c "gradle wrapper --gradle-version 4.1"
 
@echo **** Done
 
REM gradle wrapper --gradle-version 4.1
 
REM Will download gradle-4.1-bin.zip
REM gradlew -v
 
@echo *** Trying to write file
 
(
  echo rootProject.name = '%ROOT_PROJECT_NAME%'
  echo include 'plugin'
  echo include 'restapi'
  echo include 'ng2page'
) > settings.gradle
 
(
  echo version=%VERSION%
  echo pluginName = %PLUGIN_NAME%
  echo pluginDisplayName = %PLUGIN_DISPLAY_NAME%
  echo // sandbox root url including credentials
  echo distUrl = http://spadmin:admin@localhost:8080/identityiq
) > gradle.properties
 
(
  echo apply plugin: 'java'
  echo subprojects {
  echo   // Declare where to find the dependencies of the project
  echo   repositories {
  echo     // Use maven for resolving dependencies.
  echo     mavenCentral^(^)
  echo     // this is where identityiq.jar lives
  echo     mavenLocal^(^)
  echo   }
  echo }
  echo ext {
  echo   zipName = "${pluginName}.${version}\.zip"
  echo   distDir = "dist"
  echo }
  echo task clean {
  echo   delete "${distDir}"
  echo }
  echo task build^(type: Zip^, dependsOn: [':ng2page:build'^, ':restapi:build'^, ':plugin:build']^) {
  echo   archiveName "${zipName}"
  echo   destinationDir file^("${distDir}"^)
  echo   into^('/'^) {
  echo     from { project^(':plugin'^).file^('build/plugin'^) }
  echo   }
  echo   into^('/ui/ng'^) {
  echo     from { project^(':ng2page'^).file^('dist'^) }
  echo   }
  echo   into^('/lib'^) {
  echo     from { project^(':restapi'^).jar }
  echo   }
  echo }
  echo task deploy^(type: Exec^, dependsOn: build^) {
  echo   commandLine 'curl'^, "${distUrl}/rest/plugins"^, "--form"^, "file=@${distDir}/${zipName};fileName=${zipName}"
  echo }
) > build.gradle
 
REM Creating restapi
echo **** Creating restapi structure
 
md restapi\src\main\java\sailpoint\plugin\restapi
md restapi\src\test\java
 
(
  echo apply plugin: 'java-library'
  echo sourceCompatibility = 1.7
  echo targetCompatibility = 1.7
  echo dependencies {
  echo   // This dependency is used internally, and not exposed to consumers on their own compile classpath.
  echo   implementation 'log4j:log4j:1.2.17'
  echo   //
  echo   implementation 'identityiq:identityiq:7.1p1'
  echo   implementation 'org.glassfish.jersey.bundles:jaxrs-ri:2.22.2'
  echo   // Use JUnit test framework
  echo   testImplementation 'junit:junit:4.12'
  echo }
  echo jar {
  echo   baseName %PLUGIN_NAME%
  echo   manifest {
  echo     attributes^("Implementation-Title": "Gradle",
  echo         "Implementation-Version": %VERSION%^)
  echo   }
  echo }
) > restapi/build.gradle
 
REM Creating plugin
echo **** Creating plugin structure
md plugin\src\import\install
md plugin\src\import\upgrade
md plugin\src\ui\css
md plugin\src\ui\js
 
(
  echo import org.apache.tools.ant.filters.ReplaceTokens
  echo task clean^(type: Delete^) {
  echo   delete 'build'
  echo }
  echo task build^(type: Copy^) {
  echo   from { 'src' }
  echo   into^('build/plugin'^)
  echo   filter^(ReplaceTokens, tokens: [VERSION: %VERSION%, PluginName: %PLUGIN_NAME%]^)
  echo }
) > plugin/build.gradle
 
(
  echo ^<?xml version="1.0" encoding="UTF-8"?^>
  echo ^<!DOCTYPE Plugin PUBLIC "sailpoint.dtd" "sailpoint.dtd"^>
  echo ^<Plugin certificationLevel="None" displayName="%PLUGIN_DISPLAY_NAME%" minSystemVersion="7.1" maxSystemVersion="7.1" name="%PLUGIN_NAME%" version="%VERSION%"^>
  echo   ^<Attributes^>
  echo     ^<Map^>
  echo       ^<entry key="minUpgradableVersion" value="1.0" /^>
  echo       ^<entry key="fullPage"^>
  echo         ^<value^>
  echo           ^<FullPage title="%PLUGIN_DISPLAY_NAME%" /^>
  echo         ^</value^>
  echo       ^</entry^>
  echo       ^<entry key="restResources"^>
  echo         ^<value^>
  echo           ^<List^>
  echo             ^<String^>sailpoint.plugin.rest.ScaffoldingPluginResource^</String^>
  echo           ^</List^>
  echo         ^</value^>
  echo       ^</entry^>
  echo       ^<entry key="snippets"^>
  echo         ^<value^>
  echo           ^<List^>
  echo             ^<Snippet regexPattern=".*identity\.jsf.*"^>
  echo               ^<Scripts^>
  echo                 ^<String^>ui/js/identity-page-snippet.js^</String^>
  echo               ^</Scripts^>
  echo               ^<StyleSheets^>
  echo               ^</StyleSheets^>
  echo             ^</Snippet^>
  echo             ^<Snippet regexPattern=".*debug\.jsf.*"^>
  echo               ^<Scripts^>
  echo                 ^<String^>ui/js/debug-page-snippet.js^</String^>
  echo               ^</Scripts^>
  echo               ^<StyleSheets^>
  echo               ^</StyleSheets^>
  echo             ^</Snippet^>
  echo           ^</List^>
  echo         ^</value^>
  echo       ^</entry^>
  echo     ^</Map^>
  echo   ^</Attributes^>
  echo ^</Plugin^>
) > plugin/src/

