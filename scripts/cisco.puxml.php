<?php

function push2phone($ip, $uri, $uid, $pwd) {
	$auth = base64_encode($uid.":".$pwd);
	$xml = "<CiscoIPPhoneExecute><ExecuteItem Priority=\"0\" URL=\"$uri\"/></CiscoIPPhoneExecute>";
	$xml = "XML=".urlencode($xml);
	$post = "POST /CGI/Execute HTTP/1.0\r\n";
	$post .= "Host: $ip\r\n";
	$post .= "Authorization: Basic $auth\r\n";
	$post .= "Connection: close\r\n";
	$post .= "Content-Type: application/x-www-form-urlencoded\r\n";
	$post .= "Content-Length: ".strlen($xml)."\r\n\r\n";

	$fp = fsockopen ( $ip, 80, $errno, $errstr, 30);
		if(!$fp){ echo "$errstr ($errno)<br>\n"; }
		else {
			fputs($fp, $post.$xml);
			flush();
			while (!feof($fp)) {
				$response .= fgets($fp, 128);
				flush();
			}
		}
	return $response;
}

$ip = "192.168.70.117";
$uri = "http://your.web.server.here/hello_world.php";
$uid = "test";
$pwd = "test";
echo push2phone($ip, $uri, $uid, $pwd);
?>