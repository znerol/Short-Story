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
    extension-element-prefixes="exsl"
>

<!-- entry point matching the root node of an ICML -->
<xsl:template match="Document">
    <!--
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

            <!-- iterate over all ParagraphStyleRange tags in the Story ond
                 split them into processable pieces along Br tags -->
            <xsl:for-each select="Story/ParagraphStyleRange">
                <xsl:call-template name="split-paragraph"/>
            </xsl:for-each>
        </body>
    </xsl:variable>

    <!-- Apply templates matching on the simplified document. Replace this with
         an xsl:copy-of if you don't want to further process the simplified
         structure with own templates -->
    <xsl:apply-templates select="exsl:node-set($storytemp)"/>
</xsl:template>

<!-- Split up paragraphs by <Br> burried inside ParagraphStyleRange /
     CharacterStyleRange -->
<xsl:template name="split-paragraph">
    <!-- Check if the first node of the first character style range is
         <Content> and if yes, construct a paragraph around it. Note:
         xsl:for-each selects at most one node here -->
    <xsl:for-each select="CharacterStyleRange[position()=1]/*[position()=1]">
        <xsl:if test="name(.) = 'Content'">
            <xsl:call-template name="construct-paragraph"/>
        </xsl:if>
    </xsl:for-each>

    <!-- Select all <Content> nodes which are preceded by a <Br> and start
         another paragraph construction on them -->
    <xsl:for-each select="CharacterStyleRange/Content[name(preceding-sibling::*[position()=1]) = 'Br']">
        <xsl:call-template name="construct-paragraph"/>
    </xsl:for-each>

</xsl:template>

<!-- called within split-paragraph, context is the first <Content> of a
     paragraph -->
<xsl:template name="construct-paragraph">
    <p>
        <!-- copy paragraph style name to the class attribute -->
        <xsl:attribute name="class">
            <xsl:value-of select="../../@AppliedParagraphStyle"/>
        </xsl:attribute>
        <xsl:call-template name="construct-charstyle"/>
    </p>
</xsl:template>

<!-- called from construct-paragraph, context a <Content> -->
<xsl:template name="construct-charstyle">
    <!-- apply templates on content -->
    <span>
        <!-- copy character style name to the class attribute -->
        <xsl:attribute name="class">
            <xsl:value-of select="../@AppliedCharacterStyle"/>
        </xsl:attribute>
        <xsl:value-of select="."/>
    </span>

    <xsl:if test="position()=last()">
        <!-- if this <Content> is the first node within a
             <CharacterStyleRange>, we must backtrack to the last node of the
             previous <CharacterStyleRange> within the current
             <ParagraphStyleRange> and check if that is also a <Content> if it
             is, we must recurse before copying the stuff over

             Note: this loops purpose is solely to switch the context node to
             the last child in the parents preceeding sibling. It selects at 
             most one node -->
        <xsl:for-each select="../following-sibling::*[position()=1]/*[position()=1]">
            <xsl:if test="name(.) = 'Content'">
                <xsl:call-template name="construct-charstyle"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

</xsl:stylesheet>

