<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rnews="http://iptc.org/std/rNews/2011-02-02#"
    exclude-result-prefixes="dc rdf rnews"
>

<xsl:output method="xml" encoding="UTF-8"/>

<!-- Match short-story structure and convert to SMD -->
<xsl:template match="body">
    <DDD>
        <xsl:apply-templates select="*"/>
    </DDD>
</xsl:template>

<!-- Match story div -->
<xsl:template match='div[@class="story"]'>
    <DD>
        <SO>WOZ</SO>
        <SO_TXT>Die Wochenzeitung</SO_TXT>

        <!-- XMP metadaten einlesen -->
        <xsl:apply-templates select="//rdf:RDF/rdf:Description/*"/>
        <xsl:apply-templates select="//rdf:RDF/rdf:Description/@*"/>

        <!-- Spitzmarke, erster Titel, erster Untertitel extrahieren -->
        <SM><xsl:value-of select="p[contains(@class, 'Spitz')]"/></SM>
        <HT><xsl:value-of select="p[contains(@class, 'Titel')]"/></HT>
        <UT><xsl:value-of select="p[contains(@class, 'Untertitel')]"/></UT>

        <!-- Das SMD möchte alle Autoren in einem AU tag, getrennt mit einem
             Zeichen -->
        <AU>
            <xsl:for-each select="//rdf:Description/dc:creator/rdf:Seq/rdf:li">
                <xsl:value-of select="."/>
                <xsl:if test="position() != last()">; </xsl:if>
            </xsl:for-each>
        </AU>

        <TX>
            <!-- Trennen von Texten (Haupttext, Kotext, Factbox).  Falls ein
                 Paragraph (p) diesem Pattern entspricht wird ein neuer
                 Textteil erstellt.
                 Diese XPath expression muss immer derjenigen in der
                 text-continue template entsprechen.-->
            <xsl:for-each select="*[(
                contains(@class, 'Spitz') or
                contains(@class, 'Factbox Titel')
                )]">

                <xsl:choose>
                    <!-- Factbox und Kotext kommen in einen Kasten -->
                    <xsl:when test="contains(@class, 'Factbox')">
                        <xsl:call-template name='factbox-start'/>
                    </xsl:when>
                    <xsl:when test="contains(@class, 'Kotext')">
                        <xsl:call-template name='factbox-start'/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name='maintext-start'/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </TX>
    </DD>
</xsl:template>

<xsl:template name='text-continue'>
    <!-- Die XPath expression muss immer derjenigen weiter oben entsprechen -->
    <xsl:if test="not(
        contains(@class, 'Spitz') or
        contains(@class, 'Factbox Titel')
        )">
        <xsl:apply-templates select='.'/>

        <!-- text-continue auf das nächste XML element anwenden -->
        <xsl:for-each select='following-sibling::*[position()=1]'>
            <!-- rekursion -->
            <xsl:call-template name='text-continue'/>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

<xsl:template name='factbox-start'>
    <KA>
        <xsl:apply-templates select="."/>

        <!-- text-continue auf das nächste XML element anwenden -->
        <xsl:for-each select='following-sibling::*[position()=1]'>
            <xsl:call-template name='text-continue'/>
        </xsl:for-each>
    </KA>
</xsl:template>

<xsl:template name='maintext-start'>
    <xsl:apply-templates select="."/>

    <!-- text-continue auf das nächste XML element anwenden -->
    <xsl:for-each select='following-sibling::*[position()=1]'>
        <xsl:call-template name='text-continue'/>
    </xsl:for-each>
</xsl:template>

<!-- METADATA MATCHING SECTION -->

<!-- DA (alte methode)-->
<xsl:template match="rdf:Description/dc:date">
    <xsl:for-each select="rdf:Seq/rdf:li">
    <DA><xsl:value-of select="."/></DA>
    </xsl:for-each>
</xsl:template>

<!-- DA (Falls als Element in den Metadaten) -->
<xsl:template match="rdf:Description/rnews:datePublished">
    <DA><xsl:value-of select="."/></DA>
</xsl:template>

<!-- DA (Falls als Attribut in den Metadaten) -->
<xsl:template match="rdf:Description/@rnews:datePublished">
    <DA><xsl:value-of select="."/></DA>
</xsl:template>

<!-- NR (Falls als Element in den Metadaten) -->
<xsl:template match="rdf:Description/rnews:printEdition">
    <NR><xsl:value-of select="."/></NR>
</xsl:template>

<!-- NR (Falls als Attribut in den Metadaten) -->
<xsl:template match="rdf:Description/@rnews:printEdition">
    <NR><xsl:value-of select="."/></NR>
</xsl:template>

<!-- PG (Falls als Element in den Metadaten) -->
<xsl:template match="rdf:Description/rnews:printPage">
    <PG><xsl:value-of select="."/></PG>
</xsl:template>

<!-- PG (Falls als Attribut in den Metadaten) -->
<xsl:template match="rdf:Description/@rnews:printPage">
    <PG><xsl:value-of select="."/></PG>
</xsl:template>

<!-- RU (Falls als Element in den Metadaten) -->
<xsl:template match="rdf:Description/rnews:printSection">
    <RU><xsl:value-of select="."/></RU>
</xsl:template>

<!-- RU (Falls als Attribut in den Metadaten) -->
<xsl:template match="rdf:Description/@rnews:printSection">
    <RU><xsl:value-of select="."/></RU>
</xsl:template>


<!-- PARAGRAPH STYLE MATCHING SECTION -->

<!-- ZT -->
<xsl:template match="p[contains(@class, 'Zwischentitel')]">
    <ZT><xsl:value-of select="."/></ZT>
</xsl:template>
<xsl:template match="p[contains(@class, 'Factbox Titel')]" priority="1">
    <ZT><xsl:value-of select="."/></ZT>
</xsl:template>
<xsl:template match="p[contains(@class, 'Kotext Titel')]" priority="1">
    <ZT><xsl:value-of select="."/></ZT>
</xsl:template>
<xsl:template match="p[contains(@class, 'Wieder Titel')]" priority="1">
    <ZT><xsl:value-of select="."/></ZT>
</xsl:template>

<!-- NT -->
<xsl:template match="p[contains(@class, 'Fussnote')]">
    <NT><P><xsl:value-of select="."/></P></NT>
</xsl:template>

<!-- Supress stuff matched in metadata section -->
<xsl:template match="p[contains(@class, 'Spitz')]">
    <!-- ignored -->
</xsl:template>

<xsl:template match="p[contains(@class, 'Titel')]">
    <!-- ignored -->
</xsl:template>

<xsl:template match="p[contains(@class, 'Untertitel')]">
    <!-- ignored -->
</xsl:template>

<!-- DEFAULTS -->

<!-- Default paragraph style template -->
<xsl:template match="p">
    <P><xsl:apply-templates/></P>
</xsl:template>

<!-- Default character style template -->
<xsl:template match="span">
    <xsl:value-of select="."/>
</xsl:template>

<!-- identity template: ignore everything which was not matched explicitely -->
<xsl:template match="@*|node()">
</xsl:template>

</xsl:stylesheet>

