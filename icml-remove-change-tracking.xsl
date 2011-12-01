<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" encoding="UTF-8"/>

<!-- include inserted text -->
<xsl:template match="Change[@ChangeType='InsertedText']" mode='remove-change-tracking'>
    <xsl:apply-templates select="*" mode='remove-change-tracking'/>
</xsl:template>

<!-- include moved text -->
<xsl:template match="Change[@ChangeType='MovedText']" mode='remove-change-tracking'>
    <xsl:apply-templates select="*" mode='remove-change-tracking'/>
</xsl:template>

<!-- ignore removed text -->
<xsl:template match="Change[@ChangeType='DeletedText']" mode='remove-change-tracking'>
    <!-- ignore -->
</xsl:template>

<!-- bail out on unknown change record -->
<xsl:template match="Change" mode='remove-change-tracking'>
    <xsl:message terminate="yes">Encountered an unknown Change-Type</xsl:message>
</xsl:template>

<!-- identity template -->
<xsl:template match="@*|node()" mode='remove-change-tracking'>
    <xsl:copy>
        <xsl:apply-templates select="@*|node()" mode='remove-change-tracking'/>
    </xsl:copy>
</xsl:template>

<!-- override from importing stylesheet when run within an xslt pipeline -->
<xsl:template match="Document">
    <xsl:apply-templates select="." mode='remove-change-tracking'/>
</xsl:template>

</xsl:stylesheet>
