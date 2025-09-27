<?php
ob_start();
file_put_contents(__DIR__ . '/debug_cors.log', print_r($_SERVER, true), FILE_APPEND);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Credentials: true");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Code start
error_log("################# We are in Auth v7. #################");
include_once '../../../Raygun4php/raygunClass.php';
include_once './AuthManager.class.php';
include_once '../../../vendor/autoload.php';

use Spatie\ArrayToXml\ArrayToXml;
use SQLhandler\GroupAccountsModel;


function echoResponse($responseBody)
{
    echo ArrayToXml::convert($responseBody, 'API3G', false, 'UTF-8');
}

try {
    require_once DOCROOT.'System/include/db_session.php';
    require_once DOCROOT.'System/include/db_command.php';

    $requestBodyXml = trim(file_get_contents('php://input'));
    $xml = @simplexml_load_string($requestBodyXml, "SimpleXMLElement", LIBXML_NOCDATA);
    $xmlDataArray = @json_decode(@json_encode($xml), true);

    $requestBody = $xmlDataArray ? $xmlDataArray : $_REQUEST;

    $userPassword = $requestBody['userPassword'] ?? null;
    $companyCode = $requestBody['companyCode'] ?? null;
    $userName = $requestBody['userName'] ?? null;
    $userPin = $requestBody['userPin'] ?? null;
    $UserIPAddress = $requestBody['userIP'] ?? null;

    $authManager = new AuthManager();
    $selectedUser = $authManager->getUserByNameAndCompanyCode($userName, $companyCode);

    if (!$selectedUser) {
        echoResponse(["Code" => "999", "Error" => "Wrong details, please try again."]);
        return;
    }

    $usrID = $selectedUser['usrid'];
    $googleSecret = $selectedUser['usrgooglesecret'];
    $usrLoginAttempts = $selectedUser['usrloginattempts'];
    $usrTwoFaEnable = $selectedUser['usrforce2fa'];
    $userDBPassword = $selectedUser['usrpassword'];
    $usrGoogleAuthEnable = $selectedUser['usrgoogleauthenabled'];
    $companyToken = $selectedUser['companyunq'];

    $isValidAttempts = $authManager->verifyUserLoginAttempts($usrLoginAttempts);
    if (!$isValidAttempts) {
        echoResponse(["Code" => "999", "Error" => "User is blocked"]);
        return;
    }

    $isValidPassword = $authManager->verifyUserPassword($userPassword, $userDBPassword);
    if (!$isValidPassword) {
            echoResponse(["Code" => "999", "Error" => "Incorrect username and/or password supplied."]);
            return;
    }

    if ($usrTwoFaEnable || $usrGoogleAuthEnable && $userPin) {
        if (!$userPin) {
            echoResponse(["Code" => "999", "Error" => "Missing 2FA value"]);
            return;
        }
        $isValidPin = $authManager->verifyUserPin($googleSecret, $userPin, $usrLoginAttempts, $usrID);
            if (!$isValidPin) {
                echoResponse(["Code" => "999", "Error" => "Incorrect username and/or password and/or 2FA values supplied."]);
                return;
            }
    }


    $tokenCreated = $authManager->createNewAuthToken($usrID);
    if (!$tokenCreated) {
        echoResponse(["Code" => "999", "Error" => "Error occurred, please try again."]);
        return;
    }

    $newAuthToken = $authManager->getUSRunqById($usrID);
    if (!$newAuthToken) {
        echoResponse(["Code" => "999", "Error" => "Error occurred, please try again."]);
        return;
    }

    $groupAccountUserPermission = $authManager->getGroupAccountUserPermission($usrID);
    $groupAccountGroupLevelPermission = $authManager->getGroupAccountPermission($usrID, 'GroupPermissions');
    $groupAccountUserValue = $groupAccountUserPermission[0]['usrallowgroupaccountsmanagement'] === 1 ?'True':'False';
    $groupAccountValueGroupLevel = $groupAccountGroupLevelPermission[0]['result'];

    if( $groupAccountUserValue == 'True' ||  $groupAccountValueGroupLevel == 'True' ) {
        $groupAccountsModel = new GroupAccountsModel();  
        $childAccounts = $groupAccountsModel->checkParentCompanyAPI($companyCode);
        if (!is_array($childAccounts)) {
            $childAccounts = [];
        }
        $parentCompany = array(
           "childcompanyid"  => $selectedUser['companyid'],
           "childcompanytoken" => $selectedUser['companyunq'],
           "childcompanyname"  => $selectedUser['companyname'], 
           "currencies" => explode(';', $selectedUser['currencies'])
        );

        /* Create XML response */
        array_unshift($childAccounts, $parentCompany); 
        $responseArray = ["Code" => "000", "UserToken" => $newAuthToken];
        $responseArray['CompanyName'] = $selectedUser['companyname'];
        $responseArray['CompanyBrandName'] = $selectedUser['companyname2'];
        $responseArray['CompanyCode'] = $selectedUser['companycode'];
        $responseArray['CompanyToken'] = $selectedUser['companyunq'];
        $responseArray['GroupUser'] = 'True';
       
        $responseArray['TwoFactorEnabled'] = $usrTwoFaEnable;
        $responseArray['GoogleAuthEnabled'] = $usrGoogleAuthEnable;
        $responseArray["ChildAccounts"] = $childAccounts;
        
        echoResponse($responseArray);
    }else{
        
        $parentCompanyNoUser = array(
            "childcompanyid"  => $selectedUser['companyid'],
            "childcompanytoken" => $selectedUser['companyunq'],
            "childcompanyname"  => $selectedUser['companyname'], 
            "currencies" => explode(';', $selectedUser['currencies'])
         );
         $noGroupUser = [];
         $noGroupUser = $parentCompanyNoUser;
         
        
        /* Create XML response */
        $responseArray = ["Code" => "000", "UserToken" => $newAuthToken];
        $responseArray['CompanyName'] = $selectedUser['companyname'];
        $responseArray['CompanyBrandName'] = $selectedUser['companyname2'];
        $responseArray['CompanyCode'] = $selectedUser['companycode'];
        $responseArray['CompanyToken'] = $selectedUser['companyunq'];
        $responseArray['GroupUser'] = 'False';
        $responseArray['TwoFactorEnabled'] = $usrTwoFaEnable;
        $responseArray['GoogleAuthEnabled'] = $usrGoogleAuthEnable;
        $responseArray["ChildAccounts"] = $noGroupUser;
    
        echoResponse($responseArray);
    }

} catch(Exception $e) {
    $client->SendException($e,null,array());
}

ob_end_flush();
