<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE doc [
	<!ENTITY simspecxml SYSTEM "NMSess2SimSpec.xslt">
	]>
	
<!-- Transform NMSessionML file into 1) simspec file and 2) MATLAB session script -->
<xsl:transform id="Test"
	version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
<xsl:output method="text"/>
<xsl:strip-space elements="*"/>

<!-- Construct the output file paths -->
<xsl:param name="scriptDir" select="'.'"/>
<xsl:variable name="scriptoutputpath" select="translate(concat($scriptDir, '/', /nmsession/@id, 'SimSet.m'), '//', '/')" />
<xsl:variable name="simspecdirpath" select="translate(translate(//locationinfo/simspecdir, '//', '/'), '&#x20;&#x9;&#xD;&#xA;', '')" />
<xsl:variable name="simspecfilename" select="concat(/nmsession/@id, 'SimSpec.txt')" />
<xsl:variable name="simspecoutputpath" select="translate(concat($simspecdirpath, '/', $simspecfilename), '//', '/')" /> 

<xsl:template match="nmsession">
<!-- 	<xsl:message>DEBUG</xsl:message>
	<xsl:message>DEBUG2</xsl:message>
	<xsl:message><xsl:value-of select="concat('+', $scriptDir, '+')"/></xsl:message>
	<xsl:message><xsl:value-of select="concat('+', $scriptoutputpath, '+')"/></xsl:message>
	<xsl:message><xsl:value-of select="concat('+', $simspecoutputpath, '+')"/></xsl:message>
-->
	<xsl:apply-templates/>
</xsl:template>

<!-- Pull in the simspec file templates -->
&simspecxml;

<!-- Session Script file templates below -->
<!-- Need to bulletproof stuff from xml file? -->
<xsl:template match="locationinfo">
		<xsl:text>userStaticDataFile = '</xsl:text>
		<xsl:value-of select="translate(userstaticdatafilepath,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:text>';&#x0A;</xsl:text>
		<xsl:text>[nmAuthData, nmDirectorySet, userData] = loadUserStaticData(userStaticDataFile);</xsl:text>
		<!-- <xsl:value-of select="normalize-space('[nmAuthData, nmDirectorySet, userData] = loadUserStaticData(userStaticDataFile);')),' ','')))"/> -->
		<xsl:text>&#x0A;</xsl:text>
		
		<xsl:text>nmDirectorySet.customDir = '</xsl:text>
		<xsl:value-of select="translate(customdir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:text>';&#x0A;</xsl:text>
		
		<xsl:if test="/nmsession/sessionscript/locationinfo/modeldir">
			<xsl:text>nmDirectorySet.modelDir = '</xsl:text>
			<xsl:value-of select="translate(modeldir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
			<xsl:text>';&#x0A;</xsl:text>
		</xsl:if>
		
		<xsl:text>nmDirectorySet.simSpecFileDir = '</xsl:text>
		<xsl:value-of select="translate(simspecdir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:text>';&#x0A;</xsl:text>

		<xsl:text>nmDirectorySet.resultsDir = '</xsl:text>
		<xsl:value-of select="translate(resultsdir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:text>';&#x0A;</xsl:text>
		<xsl:text>%&#x0A;</xsl:text>
		
		<xsl:if test="/nmsession/sessionscript/locationinfo/addlsearchpath">
			<xsl:text>% Additional search paths added here&#x0A;</xsl:text>
			<xsl:for-each select="/nmsession/sessionscript/locationinfo/addlsearchpath">
				<xsl:text>addpath('</xsl:text>
				<xsl:value-of select="translate(.,'&#x20;&#x9;&#xD;&#xA;', '')"/>
				<xsl:text>');&#x0A;</xsl:text>
			</xsl:for-each>
		</xsl:if>
</xsl:template>

<xsl:template match="compilemachine">
		<xsl:value-of select="concat('MLCompileMachineInfoFile = ', '''', infofile, '''')"/>
		<xsl:text>;&#x0A;</xsl:text> 
		<xsl:text>nm.setMLCompileServer(MLCompileMachineInfoFile)</xsl:text>
		<xsl:text>;&#x0A;</xsl:text>
		<xsl:text>nm.doMATLABCompilation()</xsl:text>
		<xsl:text>;&#x0A;</xsl:text>
		<xsl:text>%&#x0A;</xsl:text>
</xsl:template>

<xsl:template match="standaloneserver">
		<xsl:text>nm.addStandaloneServer(</xsl:text>
		<xsl:value-of select="concat('''', infofile, '''')"/>
		<xsl:value-of select="concat(', ', translate(numsimulators,'&#x20;&#x9;&#xD;&#xA;', ''), ', ''')"/>
		<xsl:value-of select="translate(workdir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:value-of select="''');&#x0A;'"/>
</xsl:template>

<xsl:template match="cloudserver">
		<xsl:text>nm.addCloudServer(</xsl:text>
		<xsl:value-of select="concat('''', infofile, '''')"/>
		<xsl:value-of select="concat(', ', translate(numsimulators,'&#x20;&#x9;&#xD;&#xA;', ''), ', ''')"/>
		<xsl:value-of select="translate(workdir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:value-of select="''');&#x0A;'"/>
</xsl:template>

<xsl:template match="wispset">
		<xsl:text>nm.addWispSet(</xsl:text>
		<xsl:value-of select="translate(numwisps,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:value-of select="concat(', ''', wispnameroot, '''')"/>
		<xsl:value-of select="concat(', ''', infofile, '''')"/>
		<xsl:value-of select="concat(', ', translate(numsimulators,'&#x20;&#x9;&#xD;&#xA;', ''), ', ''')"/>
		<xsl:value-of select="translate(workdir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:value-of select="''');&#x0A;'"/>
</xsl:template>

<xsl:template match="cluster">
		<xsl:text>nm.addClusterQueue(</xsl:text>
		<xsl:value-of select="concat('''', infofile, ''', ')"/>
		<xsl:value-of select="concat('''', queue, '''')"/>
		<xsl:value-of select="concat(', ', translate(numsimulators,'&#x20;&#x9;&#xD;&#xA;', ''), ', ''')"/>
		<xsl:value-of select="translate(workdir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:if test="./@wallclocktime">
			<xsl:value-of select="concat(''', ''wallClockTime'', ''', @wallclocktime)"/>
		</xsl:if>
		<xsl:value-of select="''');&#x0A;'"/>
</xsl:template>

<!--
<xsl:template match="machine">
		<xsl:text>nm.addClusterQueue(MachineType.</xsl:text>
		<xsl:value-of select="translate(machinetype,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:value-of select="concat(', ', translate(numsimulators,'&#x20;&#x9;&#xD;&#xA;', ''), ', ''')"/>
		<xsl:value-of select="translate(workdir,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:if test="./@wallclocktime">
			<xsl:value-of select="concat(''', ''wallClockTime'', ''', @wallclocktime)"/>
		</xsl:if>
		<xsl:value-of select="''');&#x0A;'"/>
</xsl:template>
-->

<xsl:template match="machineset">
		<!--<xsl:text>config = MachineSetConfig(nm.isSingleMachine());&#x0A;</xsl:text>-->
		<!-- do the machines here -->
		<xsl:apply-templates select="compilemachine"/>
		<xsl:apply-templates select="standaloneserver"/>
		<xsl:apply-templates select="cluster"/>
		<xsl:apply-templates select="cloudserver"/>
		<xsl:apply-templates select="wispset"/>
		<xsl:text>nm.printConfig();&#x0A;</xsl:text>
		<xsl:text>if ~nm.verifyConfig()&#x0A;</xsl:text>
		<xsl:text>    nm.removeWisps();&#x0A;</xsl:text>
		<xsl:text>    return;&#x0A;</xsl:text>
		<xsl:text>end&#x0A;</xsl:text>
		<xsl:text>nm.constructMachineSet();&#x0A;</xsl:text>
		<xsl:text>%&#x0A;</xsl:text>
</xsl:template>

<xsl:variable name="nummachines" select="count(/nmsession/sessionscript/machineset/machine)" />

<xsl:template match="sessionscript">
	<xsl:result-document href="file:///{$scriptoutputpath}">
		<xsl:text>% This file produced automatically by NeuroManager. Do not edit.&#x0A;</xsl:text>
		<xsl:text>disp('Clearing variables, classes, and java. Please wait...');&#x0A;</xsl:text>
		<xsl:text>clear; clear variables; clear classes; clear java;&#x0A;</xsl:text>
		<xsl:text>%&#x0A;</xsl:text>

		<xsl:apply-templates select="locationinfo"/>

		<xsl:text>%&#x0A;</xsl:text>
		<xsl:text>nm = NeuroManager(nmDirectorySet, nmAuthData, userData</xsl:text> 
		<xsl:if test="./machineset/@singlemachine='true'">
			<xsl:text>, 'isSingleMachine', true</xsl:text>
			<xsl:if test="$nummachines>1">
				<xsl:message terminate="yes">
Error: singlemachine=true but more than one machine specified.
				</xsl:message>
			</xsl:if>
		</xsl:if>
		<xsl:if test="./machineset/@usedualkey='true'">
			<xsl:text>, 'useDualKey', true</xsl:text>
		</xsl:if>
		<!-- What about interactions between options, such as singlemachine and usedualkey?  Also defaults are not working properly. -->
		<xsl:text></xsl:text>
		<xsl:value-of select="concat(', ''notificationsType'', ''', /nmsession/@notificationmode, '''')"/>
		<xsl:value-of select="concat(', ''logEchoFlag'', ', /nmsession/@logecho)"/>
		<xsl:value-of select="concat(', ''showWebPage'', ', /nmsession/@showwebpage)"/>
		<xsl:value-of select="concat(', ''pollDelay'', ', ./machineset/@polldelay)"/>
		<xsl:text>);&#x0A;</xsl:text> 
		<xsl:text>disp(['NeuroManager Version: ' nm.getVersion()]);&#x0A;</xsl:text>
		<xsl:text>%&#x0A;</xsl:text>
		<xsl:text>simulatorType = SimType.</xsl:text>
		<xsl:value-of select="translate(//simset/simtype,'&#x20;&#x9;&#xD;&#xA;', '')"/>
		<xsl:text>;&#x0A;</xsl:text>
		<xsl:text>nm.setSimulatorType(simulatorType)</xsl:text>
		<xsl:text>;&#x0A;</xsl:text>

		<xsl:apply-templates select="machineset"/>

		<xsl:value-of select="concat('result = nm.runFromFile(''', $simspecfilename, ''');&#x0A;')"/>
		<xsl:text>nm.removeMachineSet();&#x0A;</xsl:text>
		<xsl:text>nm.removeWisps();&#x0A;</xsl:text>
		<xsl:text>nm.shutdown();&#x0A;</xsl:text>
		<xsl:text>% End of script.&#x0A;</xsl:text>
	</xsl:result-document>
</xsl:template>

</xsl:transform>
