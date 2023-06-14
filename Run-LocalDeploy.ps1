#use this script to test run a deployment in development locally, to see what it will do.

$clientid = "" #dev
$tenantid = "" #dev
$clientsecret = ""

./Replace-Tokens.ps1 -Environment development -OutputDirectory ../release/policies
./Deploy-CaPolicies.ps1 -localPolicyPath ../release/policies -ClientId $clientid -ClientSecret $clientsecret -TenantId $tenantid