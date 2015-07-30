Adobe ICML and ICMA preprocessor stylesheets
============================================

This icml-preproc.xsl stylesheet produces a simplified structure from Adobe
InCopy 4 ICML and ICMA file format. Due to its structure ICML is somewhat hard
to transform into Markup for the Web, especially because ParagraphStyleRanges
do not necessarely correspond exactly to paragraph boundaries.

The simplified structure produced by this stylesheet looks much like a html
fragment and therefore is way easier to transform further:

    <body>
        <article>
            <x:xmpmeta>
                <rdf:RDF>
                    <rdf:Description about="">
                        <xmp:Created>...</xmp:Created>
                        ...
                    </rdf:Description>
                    ...
                </rdf:RDF>
            </x:xmpmeta>

            <section class='ParagraphStyle/Title'>
                <p class='ParagraphStyle/Title'>
                    <span class='CharacterStyle/$ID/[No character style]'>
                       Some Title
                    </span>
                </p>
            </section>

            <section class='ParagraphStyle/Body'>
                <p class='ParagraphStyle/Body'>
                    <span class='CharacterStyle/$ID/[No character style]'>
                        Each paragraph of the story resides in exactly one
                        &lt;p&gt;. Guaranteed. Even if some other
                    </span>
                    <span class='CharacterStyle/Bold'>
                        character style
                    </span>
                    <span class='CharacterStyle/$ID/[No character style]'>
                        is applied in the middle of the a paragraph.
                    </span>
                </p>
            </section>
            ...
        </article>
        <article>
            ...
        </article>
        ...
    </body>

If you want to ignore embedded XMP metadata use an empty template:
    <xsl:template name="xmp-extract">
    </xsl:template>
