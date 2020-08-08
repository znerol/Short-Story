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

<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<xsl:template match="Document">
    <body>
        <xsl:for-each select="//Story">
            <xsl:call-template name="article"/>
        </xsl:for-each>
    </body>
</xsl:template>

<xsl:template match="Content">
    <xsl:value-of select="."/>
</xsl:template>

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

<xsl:key name="sameSection" match="Content" use="
    generate-id(
        (
            ancestor::Story |
            preceding::Content[string(ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle) != string(current()/ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle)]
        )[position()=last()]
    )"
/>

<xsl:key name="sameParagraph" match="Content" use="
    generate-id(
        (
            ancestor::Story |
            preceding::Content[string(ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle) != string(current()/ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle)] |
            preceding::Br
        )[position()=last()]
    )"
/>

<xsl:key name="sameSpan" match="Content" use="
    generate-id(
        (
            ancestor::Story |
            preceding::Content[string(ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle) != string(current()/ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle)] |
            preceding::Br |
            preceding::Content[string(ancestor::CharacterStyleRange[1]/@AppliedCharacterStyle) != string(current()/ancestor::CharacterStyleRange[1]/@AppliedCharacterStyle)] |
            preceding::Content[string(ancestor::CharacterStyleRange[1]/@Position) != string(current()/ancestor::CharacterStyleRange[1]/@Position)]
        )[position()=last()]
    )"
/>

<!-- Context: Story node. Extract XMP metadata and regroup all Content nodes
     into section, p and span elements. -->
<xsl:template name="article">
    <article>
        <!-- parse metadata by trying to call external defined xml parsing method
             on embedded RDF/XML XMP stuff -->
        <xsl:for-each select="MetadataPacketPreference/Properties/Contents/text()">
            <xsl:call-template name="xmp-extract"/>
        </xsl:for-each>

        <xsl:for-each select=".//Content">
            <xsl:variable name="sameSectionKey" select="
                generate-id(
                    (
                        ancestor::Story |
                        preceding::Content[string(ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle) != string(current()/ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle)]
                    )[position()=last()]
                )"
            />
            <xsl:variable name="sameSectionElements" select="key('sameSection', $sameSectionKey)"/>

            <xsl:if test=". = $sameSectionElements[1]">
                <section class="{ancestor::ParagraphStyleRange/@AppliedParagraphStyle}">
                    <xsl:for-each select="$sameSectionElements">
                        <xsl:variable name="sameParagraphKey" select="
                            generate-id(
                                (
                                    ancestor::Story |
                                    preceding::Content[string(ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle) != string(current()/ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle)] |
                                    preceding::Br
                                )[position()=last()]
                            )"
                        />
                        <xsl:variable name="sameParagraphElements" select="key('sameParagraph', $sameParagraphKey)"/>

                        <xsl:if test=". = $sameParagraphElements[1]">
                            <p class="{ancestor::ParagraphStyleRange/@AppliedParagraphStyle}">
                                <xsl:for-each select="$sameParagraphElements">

                                    <xsl:variable name="sameSpanKey" select="
                                        generate-id(
                                            (
                                                ancestor::Story |
                                                preceding::Content[string(ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle) != string(current()/ancestor::ParagraphStyleRange[1]/@AppliedParagraphStyle)] |
                                                preceding::Br |
                                                preceding::Content[string(ancestor::CharacterStyleRange[1]/@AppliedCharacterStyle) != string(current()/ancestor::CharacterStyleRange[1]/@AppliedCharacterStyle)] |
                                                preceding::Content[string(ancestor::CharacterStyleRange[1]/@Position) != string(current()/ancestor::CharacterStyleRange[1]/@Position)]
                                            )[position()=last()]
                                        )"
                                    />
                                    <xsl:variable name="sameSpanElements" select="key('sameSpan', $sameSpanKey)"/>

                                    <xsl:variable name="spanClass">
                                        <xsl:value-of select="ancestor::CharacterStyleRange/@AppliedCharacterStyle"/>
                                        <xsl:if test="ancestor::CharacterStyleRange/@Position">
                                            <xsl:text> Position-</xsl:text>
                                            <xsl:value-of select="ancestor::CharacterStyleRange/@Position"/>
                                        </xsl:if>
                                    </xsl:variable>

                                    <xsl:if test=". = $sameSpanElements[1]">
                                        <span class="{$spanClass}">
                                            <xsl:for-each select="$sameSpanElements">
                                                <xsl:apply-templates select="."/>
                                            </xsl:for-each>
                                        </span>
                                    </xsl:if>

                                </xsl:for-each>
                            </p>
                        </xsl:if>

                    </xsl:for-each>
                </section>
            </xsl:if>
        </xsl:for-each>
    </article>
</xsl:template>


<xsl:key name='hyperlinks' match='Hyperlink' use='@Source'/>
<xsl:key name='hyperlink_url_destinations' match='HyperlinkURLDestination' use='@Self'/>

</xsl:stylesheet>
