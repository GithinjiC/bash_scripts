<?php

// $privateKey = '2984e9a9c3383f26a868c68c3ad2616b';
$privateKey = 'CRRaUQiimbjEXaWsIVjU0GyRysi4BtPs';
// $privateKey = '';

/*
$request = 
'<?xml version="1.0" encoding="utf-8"?>
<API3G>
  <CompanyToken>8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3</CompanyToken>
  <Request>chargeTokenAuth</Request>
  <CompanyRef>24000946890</CompanyRef>
  <TransactionToken>767D971F-8D88-42EB-B174-B018924C458</TransactionToken>
</API3G>';
*/


$request = 
'<?xml version="1.0" encoding="utf-8"?>
<API3G>
    <CompanyToken>BD0B25BD-4F7E-49B0-80CD-37C2BF6F6368</CompanyToken>
    <Request>getcompanydetails</Request>
    <isForSibling>true</isForSibling>
    <siblingCompanyToken>99B80561-B2CA-417D-AC1F-058F1E0105B6</siblingCompanyToken>
</API3G>';


/*$request =
    '<?xml version="1.0" encoding="utf-8"?>
<API3G>
    <CompanyToken>8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3</CompanyToken>
    <Request>createToken</Request>
    <Transaction>
        <PaymentAmount>125.00</PaymentAmount>
        <PaymentCurrency>KES</PaymentCurrency>
        <CompanyRef>24000946890</CompanyRef>
        <RedirectURL>https://test-s2bpay.sc.com/s2bpay/dpo-response?cHNwaWQ9S0VEUE9DUkQmZW5=</RedirectURL>
        <BackURL>https://test-s2bpay.sc.com/s2bpay/dpo-response?cHNwaWQ9S0VEUE9DUkQmZW5=</BackURL>
        <CompanyRefUnique>1</CompanyRefUnique>
        <PTL>96</PTL>
        <PTLtype>minutes</PTLtype>
        <TransactionChargeType>1</TransactionChargeType>
    </Transaction>
       <Services>
    ...
    </Services>
    ...
</API3G>';
*/

$b64Request = base64_encode(trim($request));

echo "b64 request: " . $b64Request . " \n";

$encHeader =  hash_hmac('sha256', $b64Request, $privateKey);

echo "enc header: " . $encHeader;

$curl = curl_init();

curl_setopt_array($curl, array(
    // CURLOPT_URL => 'https://enc.dpodev.biz/api/v6/',
    CURLOPT_URL => 'https://enc.directpay.online/api/v6/',
    // CURLOPT_URL => 'https://sprz7xxdc8.execute-api.eu-west-1.amazonaws.com/prod',
    // CURLOPT_URL => 'https://f2f.staging.directpay.online/api/v6/',
    // CURLOPT_URL => 'https://api.directpay.online/API/V6/',
    // CURLOPT_URL => 'http://secure.3gdirectpay.com/API/V6/',
    CURLOPT_SSLCERT => "/Users/lilith/Documents/finally/client.crt",
    CURLOPT_SSLKEY => "/Users/lilith/Documents/finally/client.key",
    // CURLOPT_SSLKEY => "/Users/lilith/Downloads/dpo-scb/client.key",
    // CURLOPT_SSLCERT => "/Users/lilith/Downloads/dpo-scb/client.crt",    
    // CURLOPT_VERBOSE => true,
    // CURLOPT_SSLCERTTYPE => "P12",
    // CURLOPT_SSLCERTPASSWD => "Dp05cB@254!",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_ENCODING => '',
    CURLOPT_MAXREDIRS => 10,
    CURLOPT_TIMEOUT => 0,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
    CURLOPT_CUSTOMREQUEST => 'POST',
    CURLOPT_POSTFIELDS => $request,
    CURLOPT_HTTPHEADER => array(
        "dpo-enc: $encHeader",
        "dpo-enc-version: 20231010",
        'Content-Type: application/xml'
    ),
));

try {
    $response = curl_exec($curl);
    $escapedXml = escapeshellarg($response);
    $command = "echo $escapedXml | xmlstarlet fo";
    $formattedXml = shell_exec($command);

    if (!$formattedXml) {
        $error = curl_error($curl);
        echo $error;
    }

    // if (!$response) {
    //     $error = curl_error($curl);
    //     echo $error;
    // }

    curl_close($curl);
    $httpcode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
    echo "\n\n";
    // echo  "http code: " . $httpcode . " and response: " . json_encode($response);
    echo  "http code: " . $httpcode . " and response: " . $formattedXml;
    echo "\n";
    echo "\n\n\n" . var_dump($response);
} catch (Throwable $e) {
    echo $e->getMessage();
}

// curl --cert /Users/lilith/Downloads/dpo-scb/client.crt --key /Users/lilith/Downloads/dpo-scb/client.key \
//     -X POST https://enc.dpodev.biz/api/v6/ \
//     -H "Content-Type: application/xml" \
//     -d '<API3G>
//     <CompanyToken>BD0B25BD-4F7E-49B0-80CD-37C2BF6F6368</CompanyToken>
//     <Request>getcompanydetails</Request>
//     <isForSibling>true</isForSibling>
//     <siblingCompanyToken>99B80561-B2CA-417D-AC1F-058F1E0105B6</siblingCompanyToken>
//     </API3G>'


// openssl pkcs12 -in certificate.p12 -out certificate.pem -nodes -clcerts
?>