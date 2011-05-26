<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<xsl:output method="xml" encoding="UTF-8"/>

<!-- SMD XML Document structure -->
<xsl:template match="Document">
    <xsl:variable name="storytemp">
        <body>
            <xsl:for-each select="Story">
                <div class="story">
                    <xsl:call-template name="parse-story"/>
                </div>
            </xsl:for-each>
        </body>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($storytemp)"/>
</xsl:template>

</xsl:stylesheet>
