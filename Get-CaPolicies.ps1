Import-Module MSAL.PS, .\CAPolicy.psm1

$token = Get-MsalToken `
    -ClientId "" `
    -Scopes @("Application.Read.All", "Policy.Read.All", "Policy.ReadWrite.ConditionalAccess") `
    -RedirectUri "http://localhost" `
    -TenantId "" `
    -DeviceCode

$response = (Get-GraphConditionalAccessPolicy -accessToken $token.AccessToken -All $true).value

foreach ($policy in $response) 
{
    $policy | ConvertTo-Json -Depth 10| Out-File -FilePath "../policies-temp/$($policy.displayName.replace('/','-').replace('"','')).policy.json"
}