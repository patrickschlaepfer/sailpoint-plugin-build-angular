#!/bin/bash
ROOT_PROJECT_NAME="scaffolding_root"
PLUGIN_NAME="PluginName"
PLUGIN_DISPLAY_NAME="Plugin Display Name"
PLUGIN_VERSION="1.0.0-SNAPSHOT"
SOURCECOMPATIBILITY="1.8"
TARGETCOMPATIBILITY="1.8"

read -p "This script will delete all sources. Do you want to continue (y/n)? " answer
case ${answer:0:1} in
    y|Y )
        echo Removing source and rebuilding
    ;;
    * )
        echo Exiting
        exit 1
    ;;
esac


# remove all gradle files
rm -rf .gradle
rm -rf gradle
rm -f build.gradle
rm -f gradlew.bat
rm -f settings.gradle
rm -f gradle.properties

rm -rf restapi
rm -rf plugin

echo "**** Getting and installing gradle"

# get gradle
gradle init
gradle wrapper --gradle-version 4.1

# Will download gradle-4.1-bin.zip
./gradlew -v

# Will download gradle-4.1-bin.zip
cat <<EOF > settings.gradle
rootProject.name = '$ROOT_PROJECT_NAME'

include 'plugin'
include 'restapi'
include 'ng2page'
EOF

cat <<EOF > gradle.properties
version = $VERSION
pluginName = $PLUGIN_NAME
pluginDisplayName = $PLUGIN_DISPLAY_NAME

// sandbox root url including credentials
distUrl = http://spadmin:admin@localhost:8080/identityiq
EOF

cat <<EOF > build.gradle
apply plugin: 'java'

subprojects {
    // Declare where to find the dependencies of the project
    repositories {
        // Use maven for resolving dependencies.
        mavenCentral()
        // this is where identityiq.jar lives
        mavenLocal()
    }
}

ext {
    zipName = "${pluginName}.${version}.zip"
    distDir = "dist"
}

task clean {
    delete "${distDir}"
}

task build(type: Zip, dependsOn: [':ng2page:build', ':restapi:build', ':plugin:build']) {
    archiveName "${zipName}"
    destinationDir file("${distDir}")

    into('/') {
        from { project(':plugin').file('build/plugin') }
    }
    into('/ui/ng') {
        from { project(':ng2page').file('dist') }
    }
    into('/lib') {
        from { project(':restapi').jar }
    }
}

task deploy(type: Exec, dependsOn: build) {
    commandLine 'curl', "${distUrl}/rest/plugins", "--form", "file=@${distDir}/${zipName};fileName=${zipName}"
}
EOF

#
# Creating restapi
#
echo "**** Creating restapi structure"

mkdir -p restapi/src/main/java/sailpoint/plugin/restapi
mkdir -p restapi/src/test/java

cat <<EOF > restapi/build.gradle
apply plugin: 'java-library'

sourceCompatibility = $SOURCECOMPATIBILITY
targetCompatibility = $TARGETCOMPATIBILITY

dependencies {
  // This dependency is used internally, and not exposed to consumers on their own compile classpath.
  implementation 'log4j:log4j:1.2.17'

  //
  implementation 'identityiq:identityiq:7.1p1'
  implementation 'org.glassfish.jersey.bundles:jaxrs-ri:2.22.2'

  // Use JUnit test framework
  testImplementation 'junit:junit:4.12'
}

jar {
  baseName pluginName
  manifest {
    attributes("Implementation-Title": "Gradle",
               "Implementation-Version": version)
  }
}
EOF

#
# Creating plugin
#
echo "**** Creating plugin structure"
mkdir -p plugin/src/import/install
mkdir -p plugin/src/import/upgrade
mkdir -p plugin/src/ui/css
mkdir -p plugin/src/ui/js

cat <<EOF > plugin/build.gradle
import org.apache.tools.ant.filters.ReplaceTokens

task clean(type: Delete) {
    delete 'build'
}

task build(type: Copy) {
    from { 'src' }
    into('build/plugin')
    filter(ReplaceTokens, tokens: [VERSION: version, PluginName: pluginName])
}
EOF

cat <<EOF > plugin/src/manifest.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Plugin PUBLIC "sailpoint.dtd" "sailpoint.dtd">
<Plugin certificationLevel="None" displayName="$PLUGIN_DISPLAY_NAME" minSystemVersion="7.1" maxSystemVersion="7.1" name="$PLUGIN_NAME" version="@VERSION@">
  <Attributes>
    <Map>
      <entry key="minUpgradableVersion" value="1.0" />
      <entry key="fullPage">
        <value>
          <FullPage title="$PLUGIN_DISPLAY_NAME" />
        </value>
      </entry>
      <entry key="restResources">
        <value>
          <List>
            <String>sailpoint.plugin.rest.ScaffoldingPluginResource</String>
          </List>
        </value>
      </entry>
      <entry key="snippets">
        <value>
          <List>
            <Snippet regexPattern=".*identity\.jsf.*">
              <Scripts>
                <String>ui/js/identity-page-snippet.js</String>
              </Scripts>
              <StyleSheets>
              </StyleSheets>
            </Snippet>
            <Snippet regexPattern=".*debug\.jsf.*">
              <Scripts>
                <String>ui/js/debug-page-snippet.js</String>
              </Scripts>
              <StyleSheets>
              </StyleSheets>
            </Snippet>
          </List>
        </value>
      </entry>
    </Map>
  </Attributes>
</Plugin>
EOF


npm uninstall -g angular-cli
npm cache clean
npm install -g angular-cli@latest
