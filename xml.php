<?php

function isXml($filename) {
	$xml = new XMLReader();
	$xml->open($filename);
	$xml->setParserProperty(XMLReader::VALIDATE, true);
	return $xml->isValid();
}

require_once __DIR__.'/functions.glob_recursive.php';
$xml_files = glob_recursive(__DIR__.'/*.xml');
$result['invalid_files'] = array();
$result['valid_files']   = array();

foreach ( $xml_files as $filename ) {
	// Validate
	if ( isXml($filename) ) {
		$result['valid_files'][] = $filename;
	} else {
		$result['invalid_files'][] = $filename;
	}
}

var_dump($result);

if ( !empty($result['invalid_files']) ) {
	// That's an error
	exit(1);
}
