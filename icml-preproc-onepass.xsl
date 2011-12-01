<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
>

<xsl:output method="xml" encoding="UTF-8"/>

<!-- Pass1: remove change tracking -->
<xsl:template match="Document" mode='pass1'>
    <xsl:variable name='pass1'>
        <xsl:apply-templates select="." mode='remove-change-tracking'/>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($pass1)" mode='pass2'/>
</xsl:template>

<!-- Pass2: Run short story templates -->
<xsl:template match="Document" mode='pass2'>
    <xsl:variable name="storytemp">
        <body>
            <xsl:for-each select="Story">
                <div class="story">
                    <xsl:call-template name="parse-story"/>
                </div>
            </xsl:for-each>
        </body>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($storytemp)" mode='pass3'/>
</xsl:template>

<!-- Pass3: Convert to SMD struture -->
<xsl:template match="body" mode='pass3'>
    <!-- call templates in default mode -->
    <xsl:apply-templates select="."/>
</xsl:template>

</xsl:stylesheet>
