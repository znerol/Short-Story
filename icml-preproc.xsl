<?xml version="1.0" encoding="UTF-8"?>
<!--
    Adobe ICML preprocessor stylesheet
    ==================================

    Use one of the following xslt processor specific templates to configure
    extraction and processing of embedded XMP metadata together with content
    processing in one pass:

    XSLT template for Saxon:
        <xsl:template name="xmp-extract">
            <xsl:copy-of xmlns:saxon="http://saxon.sf.net/" select="saxon:parse(string(.))"/>
        </xsl:template>

        Usage (command line):
        saxonb-xslt -ext:on -xsl:icml-to-smd-saxon.xsl test-source-1.icml

    XSLT template for php5-xslt:
        <xsl:template name="xmp-extract">
            <xsl:copy-of xmlns:php="http://php.net/xsl" select="php:function('my_xml_parser',string(.))"/>
        </xsl:template>

        Usage:
        <?php
            $xsldoc = new DOMDocument();
            $xsldoc->load('icml-to-smd-php.xsl');
            $xsltproc = new XSLTProcessor();
            $xsltproc->importStylesheet($xsldoc);

            function my_xml_parser($text) {
                $newdoc = new DOMDocument();
                $newdoc->loadXML($text);
                return $newdoc;
            }
            $xsltproc->registerPHPFunctions('my_xml_parser');

            $xmldoc = new DOMDocument();
            $xmldoc->load('test-source-1.icml');
            echo $xsltproc->transformToXml($xmldoc);
        ?>

    If you want to ignore embedded XMP metadata use an empty template:
        <xsl:template name="xmp-extract">
        </xsl:template>
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    xmlns:saxon="http://saxon.sf.net/"
    xmlns:php="http://php.net/xsl"
    extension-element-prefixes="exsl"
>

<!-- entry point matching the root node of an ICML -->
<xsl:template match="Document">
    <!-- Client stylesheets may define templates which match on our output
        with the following structure:
        <body>
            <x:xmpmeta>
                <rdf:RDF>
                    <rdf:Description about="">
                        <xmp:Created>...</xmp:Created>
                        ...
                    </rdf:Description>
                    ...
                </rdf:RDF>
            </x:xmpmeta>

            <p class='ParagraphStyle/Title'>
                <span='CharacterStyle/$ID/[No character style]'>
                   Some Title
                </span>
            </p>

            <p class='ParagraphStyle/Body'>
                <span='CharacterStyle/$ID/[No character style]'>Each paragraph of the body resides in exactly one &lt;p&gt;. Guaranteed. Even if some other </span>
                <span='CharacterStyle/Bold'>character style</span> is applied in the middle of the a paragraph.
            </p>
            ...
        </body>

        In order to enable our clients to operate on the result set, it is
        necessary to convert that back into a node-set. It is possible to do
        that by accumulating the document body in a variable and convert its
        content using exsl:node-set() back to a node set which is selectable
        in a call to apply-templates.
    -->

    <xsl:variable name="storytemp">
        <body>
            <xsl:copy-of select="@*"/>

            <!-- parse metadata by trying to call external defined xml parsing
                 method on embedded RDF/XML XMP stuff -->
            <xsl:for-each select="Story/MetadataPacketPreference/Properties/Contents/text()">
                <xsl:call-template name="xmp-extract"/>
            </xsl:for-each>

            <!-- iterate over all ParagraphStyleRange tags in the Story -->
            <xsl:for-each select="Story/ParagraphStyleRange">
                <xsl:call-template name="regroup-paragraph"/>
            </xsl:for-each>
        </body>
    </xsl:variable>
    <xsl:apply-templates select="exsl:node-set($storytemp)"/>
</xsl:template>

<!-- tokenize <Content> by <Br> -->
<xsl:template name="regroup-paragraph">
    <xsl:for-each select="CharacterStyleRange/Content[name(following-sibling::*[position()=1]) = 'Br']">
        <!-- put result fragment into a variable -->
        <p>
            <!-- copy AppliedParagraphStyle attribute of ParagraphStyleRange ancestor -->
            <xsl:attribute name="class" select="ancestor::*[position()=2]/@AppliedParagraphStyle"/>
            <xsl:call-template name="content-backtrack"/>
        </p>
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
    <span>
        <!-- copy attributes of CharacterStyleRange ancestor to the charstyle
             tag -->
        <!-- copy AppliedCharacterStyle attribute of CharacterStyleRange ancestor -->
        <xsl:attribute name="class" select="ancestor::*[position()=1]/@AppliedCharacterStyle"/>
        <xsl:value-of select="."/>
    </span>
</xsl:template>

</xsl:stylesheet>

