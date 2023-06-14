#losely based on https://github.com/AlexFilipin/ConditionalAccess/blob/master/Deploy-Policies.ps1
function Get-GraphConditionalAccessPolicy{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        $accessToken,
        [Parameter(Mandatory = $false)]
        $CAURI = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies",
        [Parameter(Mandatory = $false)]
        $All, 
        [Parameter(Mandatory = $false)]
        $DisplayName,
        [Parameter(Mandatory = $false)]
        $Id 
    )
    if($DisplayName){
        $conditionalAccessURI = $CAURI + "?`$filter=endswith(displayName, '$DisplayName')"
    }
    if($Id){
        $conditionalAccessURI = $CAURI + "/{$Id}"
    }
    if($All -eq $true){
        $conditionalAccessURI = $CAURI
    }
    $conditionalAccessPolicyResponse = Invoke-RestMethod -Method Get -Uri $conditionalAccessURI -Headers @{"Authorization"="Bearer $accessToken"}
    $conditionalAccessPolicyResponse     
}

function Set-GraphConditionalAccessPolicy{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $requestBody,
        [Parameter(Mandatory = $true)]
        $accessToken,
        [Parameter(Mandatory = $false)]
        $CAURI = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies",
        [Parameter(Mandatory = $false)]
        $Id
    )
    $conditionalAccessURI = $CAURI + "/{$Id}"
    $conditionalAccessPolicyResponse = Invoke-RestMethod -Method Patch -Uri $conditionalAccessURI -Headers @{"Authorization"="Bearer $accessToken"} -Body $requestBody -ContentType "application/json"
    $conditionalAccessPolicyResponse
}

function Remove-GraphConditionalAccessPolicy{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $Id,
        [Parameter(Mandatory = $true)]
        $accessToken,
        [Parameter(Mandatory = $false)]
        $CAURI = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
    )
    $conditionalAccessURI = $CAURI + "/{$Id}"
    $conditionalAccessPolicyResponse = Invoke-RestMethod -Method Delete -Uri $conditionalAccessURI -Headers @{"Authorization"="Bearer $accessToken"}
    $conditionalAccessPolicyResponse     
}

function New-GraphConditionalAccessPolicy{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        $requestBody,
        [Parameter(Mandatory = $true)]
        $accessToken,
        [Parameter(Mandatory = $false)]
        $CAURI = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
    )
    $conditionalAccessURI = $CAURI
    $conditionalAccessPolicyResponse = Invoke-RestMethod -Method Post -Uri $conditionalAccessURI -Headers @{"Authorization"="Bearer $accessToken"} -Body $requestBody -ContentType "application/json"
    $conditionalAccessPolicyResponse     
}

Export-ModuleMember Get-GraphConditionalAccessPolicy, Set-GraphConditionalAccessPolicy, Remove-GraphConditionalAccessPolicy, New-GraphConditionalAccessPolicy