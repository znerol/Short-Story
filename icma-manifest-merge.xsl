<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template match="manifest">
        <Document>
            <xsl:for-each select="item/@href">
                <xsl:copy-of select="document(.)//Story"/>
            </xsl:for-each>
        </Document>
    </xsl:template>

</xsl:stylesheet>
