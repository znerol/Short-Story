<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- ignore metadata -->
<xsl:template match="MetadataPacketPreference" mode='remove-metadata'>
    <!-- ignore -->
</xsl:template>

<!-- identity template -->
<xsl:template match="@*|node()" mode='remove-metadata'>
    <xsl:copy>
        <xsl:apply-templates select="@*|node()" mode='remove-metadata'/>
    </xsl:copy>
</xsl:template>

<!-- override from importing stylesheet when run within an xslt pipeline -->
<xsl:template match="Document">
    <xsl:apply-templates select="." mode='remove-metadata'/>
</xsl:template>

</xsl:stylesheet>
