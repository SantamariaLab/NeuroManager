<xsl:template match="simset">
	<xsl:result-document href="file:///{$simspecoutputpath}">
		<xsl:text>% This file produced automatically by NeuroManager. Do not edit.&#13;</xsl:text>
		<xsl:text>SIMSETDEF </xsl:text>
		<xsl:value-of select="id"/>
		<xsl:value-of select="concat(' ',simtype)"/>
		<xsl:value-of select="'&#13;%&#13;'"/>
		<!-- Following may not work with interleaved comments and simdefs -->
		<xsl:apply-templates select="commentline"/>
		<xsl:apply-templates select="simdef"/>
	</xsl:result-document>
</xsl:template>
	
<xsl:template match="simdef">
<xsl:value-of select="'&#13;SIMDEF'"/>
	<xsl:choose>
		<xsl:when test="@notifications='true'">
			<xsl:value-of select="'N'"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="' '"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:value-of select="concat(' ',id)"/>
	<xsl:value-of select="concat(' ',param01)"/>
	<xsl:value-of select="concat(' ',param02)"/>
	<xsl:value-of select="concat(' ',param03)"/>
	<xsl:value-of select="concat(' ',param04)"/>
	<xsl:value-of select="concat(' ',param05)"/>
	<xsl:value-of select="concat(' ',param06)"/>
	<xsl:value-of select="concat(' ',param07)"/>
	<xsl:value-of select="concat(' ',param08)"/>
	<xsl:value-of select="concat(' ',param09)"/>
	<xsl:value-of select="concat(' ',param10)"/>
</xsl:template>

<xsl:template match="commentline">
% <xsl:value-of select="comment"/>
</xsl:template>