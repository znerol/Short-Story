<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:php="http://php.net/xsl"
    extension-element-prefixes="exsl saxon php"
>

<!-- entry point matching the root node of an ICML -->
<xsl:template match="Document">
    <!-- use exslt to transform the result fragment after applying the
         templates to convert the funny adobe tree into a usable one into a
         node-set and apply user templates on it -->
    <xsl:variable name="storytemp">
        <story>
            <xsl:copy-of select="@*"/>

            <!-- Pull in the embedded xmpmeta section. Regrettably neither
                 XSLT 1.0 nor EXSLT provide a way to parse XML contained in
                 a CDATA section, thats why we have to fall back on some funny
                 ways to achieve that:
                 1. Use saxon:parse if running on saxon
                 2. Call a PHP function if running under php
            -->
            <xsl:variable name="xmpmeta" select="Story/MetadataPacketPreference/Properties/Contents/text()"/>
            <xsl:choose>
                <xsl:when test="$xml_parse_method='saxon'">
                    <xsl:copy-of select="saxon:parse(string($xmpmeta))"/>
                </xsl:when>
                <xsl:when test="$xml_parse_method='php'">
                    <xsl:copy-of select="php:function('icml_preproc_parse_xml',string($xmpmeta))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message terminate = "yes">
                        Unknown method <xsl:value-of select="$xml_parse_method"/> specified in parameter xml_parse_method.
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>

            <!-- iterate over all ParagraphStyleRange tags in the Story -->
            <xsl:for-each select="Story/ParagraphStyleRange">
                <xsl:call-template name="regroup-paragraph"/>
            </xsl:for-each>
        </story>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($storytemp)"/>
</xsl:template>

<!-- tokenize <Content> by <Br> -->
<xsl:template name="regroup-paragraph">
    <xsl:for-each select="CharacterStyleRange/Content[name(following-sibling::*[position()=1]) = 'Br']">
        <!-- put result fragment into a variable -->
        <parastyle>
            <!-- copy attributes of ParagraphStyleRange ancestor -->
            <xsl:copy-of select="ancestor::*[position()=2]/@*"/>
            <xsl:call-template name="content-backtrack"/>
        </parastyle>
    </xsl:for-each>
</xsl:template>

<!-- called within <ParagraphStyleRange>, context is the last <Content> before
     a <BR/> -->
<xsl:template name="content-backtrack">
    <xsl:if test="position()=1">
        <!-- if this <Content> is the first node within a
             <CharacterStyleRange>, we must backtrack to the last node of the
             previous <CharacterStyleRange> within the current
             <ParagraphStyleRange> and check if that is also a <Content> if it
             is, we must recurse before copying the stuff over -->

        <!-- Note: this loops do select at most one node. The goal is to set
             the context node to the last child of the preceding sibling if
             that is a <Content> tag -->
        <xsl:for-each select="ancestor::*[position()=1]">
            <!-- Now we are at ParagraphStyleRange -->
            <xsl:for-each select="preceding-sibling::*[position()=1]">
                <!-- Now we are at the preceding CharacterStyleRange -->
                <xsl:if test="name(*[position()=last()]) = 'Content'">
                    <!-- select last sibling inside -->
                    <xsl:for-each select="*[position()=last()]">
                        <!-- Now we are at the last Content: recurse -->
                        <xsl:call-template name="content-backtrack"/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:if>

    <!-- apply templates on content -->
    <charstyle>
        <!-- copy attributes of CharacterStyleRange ancestor to the charstyle
             tag -->
        <xsl:copy-of select="ancestor::*[position()=1]/@*"/>
        <xsl:value-of select="."/>
    </charstyle>
</xsl:template>

</xsl:stylesheet>

