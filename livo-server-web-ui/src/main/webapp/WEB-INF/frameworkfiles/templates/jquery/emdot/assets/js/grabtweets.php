<?php

// This retired sample previously embedded reusable provider credentials and
// dispatched a caller-selected Twitter API method. Keep the endpoint closed
// until it is replaced by an authenticated, allowlisted, server-side adapter.
http_response_code(410);
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
echo json_encode(array(
    'error' => 'retired_integration',
    'message' => 'The legacy Twitter integration is disabled.'
));
