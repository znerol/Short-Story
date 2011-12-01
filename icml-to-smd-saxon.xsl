<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- include SMD document rules -->
<xsl:import href="icml-to-smd-rules.xsl"/> <!-- mode: default -->

<!-- import preprocessing rules plus onepass extension -->
<xsl:import href="icml-remove-change-tracking.xsl"/> <!-- mode: remove-change-tracking -->
<xsl:import href="icml-preproc.xsl"/> <!-- mode: pass1, pass2 -->
<xsl:import href="icml-preproc-onepass.xsl"/>

<xsl:output method="xml" encoding="UTF-8"/>

<xsl:template match="Document">
    <xsl:apply-templates select="." mode='pass1'/>
</xsl:template>

<!-- saxon XMP extraction method -->
<xsl:template name="xmp-extract">
    <xsl:copy-of xmlns:saxon="http://saxon.sf.net/" select="saxon:parse(string(.))"/>
</xsl:template>

</xsl:stylesheet>
