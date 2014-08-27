<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <xsl:param name="prefix-url"/>
    <xsl:variable name="prefix-len" select="string-length($prefix-url)"/>

    <xsl:template match="Document">
        <manifest>
            <xsl:for-each select="Assignment">
                <xsl:apply-templates select="AssignedStory/@StoryReference"/>
            </xsl:for-each>
        </manifest>
    </xsl:template>

    <xsl:template match="AssignedStory/@StoryReference">
        <xsl:apply-templates select="//*[@Self = current()]//Link"/>
    </xsl:template>

    <xsl:template match="Link">
        <item>
            <xsl:attribute name="href">
                <xsl:choose>
                    <xsl:when test="substring(@LinkResourceURI, 1, $prefix-len) = $prefix-url">
                        <xsl:value-of select="substring(@LinkResourceURI, $prefix-len + 1)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@LinkResourceURI"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </item>
    </xsl:template>

</xsl:stylesheet>
