<?xml version="1.0" encoding="UTF-8"?>
<!--
Adobe ICML preprocessor stylesheet
==================================

Copyright (c) 2014 Lorenz Schori <lo@znerol.ch>

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

The format produced by this template is a variation of the one from the
original icml-preproc.xsl. It additionally groups successive p-elements having
the same paragraph style into a section. This especially helps when it is
necessary to wrap a container around elements of the same class (e.g. lists).
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="Document">
    <body>
        <xsl:apply-templates mode="article-start" select=".//Story"/>
    </body>
</xsl:template>

<xsl:template match="Content">
    <xsl:value-of select="."/>
</xsl:template>

<xsl:key name='hyperlinks' match='Hyperlink' use='@Source'/>
<xsl:key name='hyperlink_url_destinations' match='HyperlinkURLDestination' use='@Self'/>
<xsl:template match="HyperlinkTextSource//Content">
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="key('hyperlink_url_destinations', key('hyperlinks', ancestor-or-self::HyperlinkTextSource[1]/@Self)//Destination)/@DestinationURL"/>
        </xsl:attribute>
        <xsl:value-of select="."/>
    </a>
</xsl:template>

<!-- Default template to extract XMP-metadata. If you have an XSLT processor
     which has a parsing extension like saxon:parse, override this template
     in the calling stylesheet -->
<xsl:template name="xmp-extract">
    <xsl:value-of select="." disable-output-escaping="yes"/>
</xsl:template>

<!-- Context: Story node. Extract XMP metadata and regroup all Content nodes
     into section, p and span elements. -->
<xsl:template mode="article-start" match="Story">
    <article>
        <!-- parse metadata by trying to call external defined xml parsing method
             on embedded RDF/XML XMP stuff -->
        <xsl:for-each select="MetadataPacketPreference/Properties/Contents/text()">
            <xsl:call-template name="xmp-extract"/>
        </xsl:for-each>

        <xsl:apply-templates mode="section-start" select="(.//Content)[
                position()=1 or
                ancestor::ParagraphStyleRange/@AppliedParagraphStyle != preceding::Content[1]/ancestor::ParagraphStyleRange/@AppliedParagraphStyle
            ]"/>
        </article>
    </xsl:template>

<!-- Context: First Content node of a section -->
<xsl:template mode="section-start" match="Content">
    <xsl:variable name="story" select="ancestor::Story"/>
    <xsl:variable name="section-class" select="ancestor::ParagraphStyleRange/@AppliedParagraphStyle"/>

    <section class="{$section-class}">
        <xsl:apply-templates mode="paragraph-start" select=".">
            <xsl:with-param name="story" select="$story"/>
            <xsl:with-param name="section-class" select="$section-class"/>
        </xsl:apply-templates>
    </section>
</xsl:template>

<!-- Context: First Content node of a paragraph -->
<xsl:template mode="paragraph-start" match="Content">
    <xsl:param name="story" />
    <xsl:param name="section-class" />

    <xsl:variable name="paragraph-class" select="$section-class"/>

    <p class="{$paragraph-class}">
        <xsl:apply-templates mode="span-start" select=".">
            <xsl:with-param name="story" select="$story"/>
            <xsl:with-param name="paragraph-class" select="$paragraph-class"/>
        </xsl:apply-templates>
    </p>

    <xsl:apply-templates mode="paragraph-next" select="(following::Br)[1]">
        <xsl:with-param name="story" select="$story"/>
        <xsl:with-param name="section-class" select="$section-class"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Context: Br node ending previous paragraph -->
<xsl:template mode="paragraph-next" match="Br">
    <xsl:param name="story" />
    <xsl:param name="section-class" />

    <xsl:apply-templates mode="paragraph-next" select="(following::Content)[1]">
        <xsl:with-param name="story" select="$story"/>
        <xsl:with-param name="section-class" select="$section-class"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Context: Content node probably starting next paragraph -->
<xsl:template mode="paragraph-next" match="Content">
    <xsl:param name="story" />
    <xsl:param name="section-class" />

    <xsl:if test="
            $story = ancestor::Story and
            $section-class = ancestor::ParagraphStyleRange/@AppliedParagraphStyle
        ">
        <xsl:apply-templates mode="paragraph-start" select=".">
            <xsl:with-param name="story" select="$story"/>
            <xsl:with-param name="section-class" select="$section-class"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- Context: First Content node of a span -->
<xsl:template mode="span-start" match="Content">
    <xsl:param name="story" />
    <xsl:param name="paragraph-class" />

    <xsl:variable name="span-class">
        <xsl:value-of select="ancestor::CharacterStyleRange/@AppliedCharacterStyle"/>
        <xsl:if test="ancestor::CharacterStyleRange[1]/@Position">
            <xsl:text> Position-</xsl:text>
            <xsl:value-of select="ancestor::CharacterStyleRange[1]/@Position"/>
        </xsl:if>
    </xsl:variable>

    <span class="{$span-class}">
        <xsl:apply-templates mode="span-build" select=".">
            <xsl:with-param name="story" select="$story"/>
            <xsl:with-param name="paragraph-class" select="$paragraph-class"/>
            <xsl:with-param name="span-class" select="$span-class"/>
        </xsl:apply-templates>
    </span>

    <xsl:apply-templates mode="span-next" select="(
            following::Br |
            following::Content[string(ancestor::CharacterStyleRange/@AppliedCharacterStyle) != string(current()/ancestor::CharacterStyleRange/@AppliedCharacterStyle)] |
            following::Content[string(ancestor::CharacterStyleRange/@Position) != string(current()/ancestor::CharacterStyleRange/@Position)]
        )[1]">
        <xsl:with-param name="story" select="$story"/>
        <xsl:with-param name="paragraph-class" select="$paragraph-class"/>
        <xsl:with-param name="span-class" select="$span-class"/>
    </xsl:apply-templates>
</xsl:template>

<!-- Context: Content node of a span -->
<xsl:template mode="span-build" match="Content">
    <xsl:param name="story" />
    <xsl:param name="paragraph-class" />
    <xsl:param name="span-class" />

    <xsl:variable name="current-span-class">
        <xsl:value-of select="ancestor::CharacterStyleRange/@AppliedCharacterStyle"/>
        <xsl:if test="ancestor::CharacterStyleRange[1]/@Position">
            <xsl:text> Position-</xsl:text>
            <xsl:value-of select="ancestor::CharacterStyleRange[1]/@Position"/>
        </xsl:if>
    </xsl:variable>

    <xsl:if test="
            $story = ancestor::Story and
            $paragraph-class = ancestor::ParagraphStyleRange/@AppliedParagraphStyle and
            $span-class = $current-span-class
        ">

        <!-- apply templates in default mode / copy actual content -->
        <xsl:apply-templates select="."/>

        <xsl:apply-templates mode="span-build" select="(following::Content | following::Br)[1]">
            <xsl:with-param name="story" select="$story"/>
            <xsl:with-param name="paragraph-class" select="$paragraph-class"/>
            <xsl:with-param name="span-class" select="$span-class"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<xsl:template mode="span-build" match="Br">
    <!-- Nothing to do. Br always terminates a span -->
</xsl:template>

<!-- Context: Content node probably starting next span -->
<xsl:template mode="span-next" match="Content">
    <xsl:param name="story" />
    <xsl:param name="paragraph-class" />

    <xsl:if test="
            $story = ancestor::Story and
            $paragraph-class = ancestor::ParagraphStyleRange/@AppliedParagraphStyle
        ">

        <xsl:apply-templates mode="span-start" select=".">
            <xsl:with-param name="story" select="$story"/>
            <xsl:with-param name="paragraph-class" select="$paragraph-class"/>
        </xsl:apply-templates>
    </xsl:if>
</xsl:template>

<!-- Context: Br node ending previous span -->
<xsl:template mode="span-next" match="Br">
    <!-- Nothing to do. Br always terminates a span -->
</xsl:template>

</xsl:stylesheet>
