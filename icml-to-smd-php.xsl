<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- php XMP extraction method -->
<xsl:template name="xmp-extract">
    <xsl:copy-of xmlns:php="http://php.net/xsl" select="php:function('my_xml_parser',string(.))"/>
</xsl:template>

<!-- include ICML preprocessor XSLT -->
<xsl:include href="icml-preproc.xsl"/>

<!-- include SMD document rules -->
<xsl:include href="icml-to-smd-rules.xsl"/>

</xsl:stylesheet>
