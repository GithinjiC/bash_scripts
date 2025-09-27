<?php

// $url = "https://enc.dpodev.biz/"; // 
// $url = "https://enc.drectpay.online/api/v6/"; // 
$url = "https://api.directpay.online/API/V6/"; 

$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

// Set the client certificate and private key
// curl_setopt($ch, CURLOPT_SSLCERT, "/Users/lilith/Downloads/dpo-scb/client.crt"); 
// curl_setopt($ch, CURLOPT_SSLKEY, "/Users/lilith/Downloads/dpo-scb/client.key");   

// Optionally, set the certificate authority (CA) bundle if needed
#curl_setopt($ch, CURLOPT_CAINFO, "/path/to/ca-bundle.crt"); // Optional, depending on your CA setup

// Set HTTPS port if not default
curl_setopt($ch, CURLOPT_PORT, 443);

// Enable verbose output for debugging
curl_setopt($ch, CURLOPT_VERBOSE, true); 

$response = curl_exec($ch);

// cURL errors
if (curl_errno($ch)) {
    echo 'cURL error: ' . curl_error($ch);
} else {
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    echo "HTTP code: $http_code\n";
    echo "Response: $response\n";
}

curl_close($ch);
?>
