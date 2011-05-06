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
