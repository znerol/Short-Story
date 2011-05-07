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

This stylesheet produces a simplified structure from Adobe InCopy 4 files in
the ICML file format. Due to its structure ICML is somewhat hard to transform
into Markup for the Web, especially because ParagraphStyleRanges do not
necessarely correspond exactly to paragraph boundaries.

The simplified structure produced by this stylesheet looks much like a html
fragment and therefore is much easier to transform further:

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
            <span='CharacterStyle/$ID/[No character style]'>
                Each paragraph of the body resides in exactly one
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
    </body>

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
        <p>
            <!-- copy AppliedParagraphStyle attribute of ParagraphStyleRange ancestor -->
            <xsl:attribute name="class" select="ancestor::*[position()=2]/@AppliedParagraphStyle"/>
            <xsl:call-template name="content-backtrack"/>
        </p>
    </xsl:for-each>

    <!-- if we are in the last ParagraphStyleNode, let's check if the last node
         within the last CharacterStyleRange is a Content. If it is, we need
         to treat that also -->
    <xsl:if test="position()=last()">
        <xsl:for-each select="CharacterStyleRange[position()=last()]/*[position()=last()]">
            <xsl:if test="name(.) = 'Content'">
                <p>
                    <!-- copy AppliedParagraphStyle attribute of ParagraphStyleRange ancestor -->
                    <xsl:attribute name="class" select="ancestor::*[position()=2]/@AppliedParagraphStyle"/>
                    <xsl:call-template name="content-backtrack"/>
                </p>
            </xsl:if>
        </xsl:for-each>
    </xsl:if>
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

        <!-- Note: this loops purpose is solely to switch the context node to
             the last child in the parents preceeding sibling. It selects at 
             most one node -->
        <xsl:for-each select="../preceding-sibling::*[position()=1]/*[position()=last()]">
            <xsl:if test="name(.) = 'Content'">
                <xsl:call-template name="content-backtrack"/>
            </xsl:if>
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

