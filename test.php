<?php
$doc = new DOMDocument();
$doc->load('test-source-1.icml');

$xslt = new XSLTProcessor(); 
$XSL = new DOMDocument(); 
$XSL->load('icml-to-smd.xsl');
$xslt->importStylesheet( $XSL );

function icml_preproc_parse_xml($text) {
    $doc = new DOMDocument();
    $doc->loadXML($text);
    return $doc;
}
$xslt->registerPHPFunctions('icml_preproc_parse_xml');

echo $xslt->transformToXml($doc);
