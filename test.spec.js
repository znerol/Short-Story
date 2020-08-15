describe('Short Story', function () {
    const tests = [
        "assignment-manifest-01",
        "change-tracking-01",
        // "manifest-merge-01",
        "preproc-assignment-01",
        "preproc-basic-01",
        "preproc-basic-02",
        "preproc-basic-03",
        "preproc-basic-04",
        "preproc-basic-05",
        "preproc-basic-06",
        "preproc-basic-07",
        "preproc-basic-08",
        "preproc-basic-09",
        "preproc-basic-10",
        "preproc-multistory-01",
        "preproc-multistory-02",
    ];

    async function fetchText(url) {
        const response = await fetch(url);
        if (response.ok) {
            return await response.text();
        }
    }

    function serialize(document) {
        const parser = new DOMParser();
        const serial = new XMLSerializer();

        const identity = new XSLTProcessor();
        identity.importStylesheet(parser.parseFromString(`
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
          <xsl:output method="xml" indent="no" encoding="UTF-8"/>
          <xsl:strip-space elements="*"/>
          <xsl:template match="@*|node()">
            <xsl:copy>
              <xsl:apply-templates select="@*|node()"/>
            </xsl:copy>
          </xsl:template>
        </xsl:stylesheet>
        `, "text/xml"));

        return serial.serializeToString(identity.transformToDocument(document));
    }

    async function loadTest(name) {
        const parser = new DOMParser();

        const fixture = await fetchText(`test/${name}/fixture.xml`);
        const expected = await fetchText(`test/${name}/expected.xml`);
        const stylesheet = await fetchText(`test/${name}/stylesheet.xsl`);

        return {
            name,
            fixture: parser.parseFromString(fixture, "text/xml"),
            expected: parser.parseFromString(expected, "text/xml"),
            stylesheet: parser.parseFromString(stylesheet, "text/xml"),
        }
    }

    for (let name of tests) {
        it(name, async function () {
            const test = await loadTest(name);
            const proc = new XSLTProcessor();
            proc.importStylesheet(test.stylesheet);

            const result = proc.transformToDocument(test.fixture);

            chai.expect(result).exist;

            const actual = serialize(result);
            const expected = serialize(test.expected);

            chai.expect(actual).to.equal(expected);
        });
    }
});
