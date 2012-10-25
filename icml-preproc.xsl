<?xml version="1.0" encoding="UTF-8"?>
<!--
Adobe ICML preprocessor stylesheet
==================================

Copyright (c) 2011 Lorenz Schori <lo@znerol.ch>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

This stylesheet produces a simplified structure from Adobe InCopy 4 ICML file
format. Due to its structure ICML is somewhat hard to transform into Markup for
the Web, especially because ParagraphStyleRanges do not necessarely correspond
exactly to paragraph boundaries.

The simplified structure produced by this stylesheet looks much like a html
fragment and therefore is much easier to transform further:

    <div class="story">
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
            <span='CharacterStyle/$ID/[No character style]'>
                Each paragraph of the story resides in exactly one
                &lt;p&gt;. Guaranteed. Even if some other
            </span>
            <span='CharacterStyle/Bold'>
                character style
            </span>
            <span='CharacterStyle/$ID/[No character style]'>
                is applied in the middle of the a paragraph.
            </span>
        </p>
        ...
    </div>

Use this stylesheet by including it into another one where you define templates
to transform the simplified structure into a target document. A skeletton of
might look something like this:

    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:include href="icml-preproc.xsl"/>

    <xsl:template name="xmp-extract">
    </xsl:template>

    <xsl:template match="p">
        <P><xsl:apply-templates/></P>
    </xsl:template>

    <xsl:template match="span">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="@*|node()">
    </xsl:template>

    </xsl:stylesheet>

Use one of the following xslt processor specific templates to configure
extraction and processing of embedded XMP metadata together with content
simplification in one pass.

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
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:output method="xml" encoding="UTF-8"/>

<xsl:template match="Document">
    <body>
        <xsl:for-each select="Story">
            <div class="story">
                <xsl:call-template name="parse-story"/>
            </div>
        </xsl:for-each>
    </body>
</xsl:template>

<!-- Default template to extract XMP-metadata. If you have an XSLT processor
     which has a parsing extension like saxon:parse, override this template
     in the calling stylesheet -->
<xsl:template name="xmp-extract">
    <xsl:value-of select="." disable-output-escaping="yes"/>
</xsl:template>

<!-- Context: Story node. Extract XMP metadata and regroup all Content nodes
     into p and span elements. -->
<xsl:template name="parse-story">
    <!-- parse metadata by trying to call external defined xml parsing method
         on embedded RDF/XML XMP stuff -->
    <xsl:for-each select="MetadataPacketPreference/Properties/Contents/text()">
        <xsl:call-template name="xmp-extract"/>
    </xsl:for-each>

    <!-- Start text processing with first Content-Node -->
    <xsl:for-each select=".//Content[count(preceding::Content)=0]">
        <xsl:call-template name="start-paragraph"/>
    </xsl:for-each>
</xsl:template>

<!-- Context: The first content node of a paragraph. Construct new paragraph
     and start processing of all content nodes of this paragraph -->
<xsl:template name="start-paragraph">
    <p>
        <!-- copy paragraph style name to the class attribute -->
        <xsl:attribute name="class">
            <xsl:value-of select="ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle"/>
            <xsl:if test="ancestor::ParagraphStyleRange[1]/@Position">
                <xsl:text> Position-</xsl:text>
                <xsl:value-of select="ancestor::ParagraphStyleRange[1]/@Position"/>
            </xsl:if>
        </xsl:attribute>
        <xsl:call-template name="start-content"/>
    </p>

    <!-- Jump to the Content node following the next Br tag and recurse -->
    <xsl:for-each select="following::Br[1]">
        <xsl:for-each select="following::Content[1]">
            <xsl:call-template name='start-paragraph'/>
        </xsl:for-each>
    </xsl:for-each>
</xsl:template>

<!-- Context: A Content node. Construct span and copy style attribute -->
<xsl:template name="start-content">
    <span>
        <!-- copy character style name to the class attribute -->
        <xsl:attribute name="class">
            <xsl:value-of select="ancestor::CharacterStyleRange[1]/@AppliedCharacterStyle"/>
            <xsl:if test="ancestor::CharacterStyleRange[1]/@Position">
                <xsl:text> Position-</xsl:text>
                <xsl:value-of select="ancestor::CharacterStyleRange[1]/@Position"/>
            </xsl:if>
        </xsl:attribute>
        <xsl:value-of select="."/>
    </span>

    <!-- Jump to the next Content node, if no Br is following us -->
    <xsl:for-each select="(following::Br|following::Content)[1][name()='Content']">
        <xsl:call-template name='start-content'/>
    </xsl:for-each>
</xsl:template>

</xsl:stylesheet>

