$allowedOrigins = [
    'https://liteportal.dpodev.biz',
    'https://f2f-portal.dpodev.biz',
];

// Always set CORS headers if Origin is sent
if (isset($_SERVER['HTTP_ORIGIN'])) {
    $origin = $_SERVER['HTTP_ORIGIN'];
    if (in_array($origin, $allowedOrigins)) {
        header("Access-Control-Allow-Origin: $origin");
        header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
        header("Access-Control-Allow-Headers: Content-Type, Authorization");
        header("Access-Control-Allow-Credentials: true");
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // CORS headers must be set before returning
    http_response_code(200);
    exit;
}



<rule name="Preflight OPTIONS" stopProcessing="true">
					<match url=".*" />
					<conditions>
						<add input="{REQUEST_METHOD}" pattern="OPTIONS" />
					</conditions>
					<action type="None" />
				</rule>