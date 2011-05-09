<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/"
    exclude-result-prefixes="dc rdf xmpMM"
>

<!-- SMD XML Document structure -->
<xsl:template match="div[@class='story']">
<DDD>
    <DD>
        <xsl:apply-templates select="//rdf:RDF/rdf:Description/*"/>
        <xsl:apply-templates select="p"/>
    </DD>
</DDD>
</xsl:template>

<!-- METADATA MATCHING SECTION -->

<!-- Metadata UUID -->
<xsl:template match="rdf:Description/xmpMM:DocumentID">
    <UUID><xsl:value-of select="."/></UUID>
</xsl:template>

<!-- Metadata Title -->
<xsl:template match="rdf:Description/dc:title">
    <HT><xsl:value-of select="rdf:Alt/rdf:li"/></HT>
</xsl:template>

<!-- Metadata Creator -->
<xsl:template match="rdf:Description/dc:creator">
    <xsl:for-each select="rdf:Seq/rdf:li">
    <AU><xsl:value-of select="."/></AU>
    </xsl:for-each>
</xsl:template>

<!-- PARAGRAPH STYLE MATCHING SECTION -->

<!-- ParagraphStyleMatching -->
<xsl:template match="p[@class='ParagraphStyle/Zwischentitel']">
    <ZT><xsl:apply-templates/></ZT>
</xsl:template>

<!-- Default character style template -->
<xsl:template match="span[@class='CharacterStyle/bold']">
    <B><xsl:value-of select="."/></B>
</xsl:template>

<!-- DEFAULTS -->

<!-- Default paragraph style template -->
<xsl:template match="p">
    <P><xsl:apply-templates/></P>
</xsl:template>

<!-- Default character style template -->
<xsl:template match="span">
    <xsl:value-of select="."/>
</xsl:template>

<!-- identity template: ignore everything which was not matched explicitely -->
<xsl:template match="@*|node()">
</xsl:template>

</xsl:stylesheet>

