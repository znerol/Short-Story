<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- saxon XMP extraction method -->
<xsl:template name="xmp-extract">
    <xsl:copy-of xmlns:saxon="http://saxon.sf.net/" select="saxon:parse(string(.))"/>
</xsl:template>

<!-- include ICML preprocessor XSLT -->
<xsl:include href="icml-preproc.xsl"/>

<!-- include SMD document rules -->
<xsl:include href="icml-to-smd-rules.xsl"/>

</xsl:stylesheet>
