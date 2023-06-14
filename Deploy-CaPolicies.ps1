[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]
    $localPolicyPath = "$PSScriptRoot/../policies",
    [Parameter(Mandatory = $true)]
    [string]
    $ClientId,
    [Parameter(Mandatory = $true)]
    [string]
    $ClientSecret,
    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,
    [Parameter(Mandatory = $false)]
    [boolean]
    $DryRun = $true
)

Import-Module MSAL.PS, "$PSScriptRoot/../tools/CAPolicy.psm1"

$ErrorActionPreference = "Stop"

$token = Get-MsalToken `
    -ClientId $ClientId `
    -ClientSecret $($ClientSecret | ConvertTo-SecureString -AsPlainText -Force) `
    -RedirectUri "http://localhost" `
    -TenantId $TenantId

#region FindChanges
$currentAzurePolicies = (Get-GraphConditionalAccessPolicy -accessToken $token.AccessToken -All $true).value
#somtimes the display names get serialized with line breaks in them - I have no idea why this happens. It seems to be worse on Windows?
$currentAzurePolicies | ForEach-Object {$_.displayName = $_.displayName.replace("`r`n","")}
$currentAzurePolicies | ForEach-Object {$_.displayName = $_.displayName.replace("`n", "")}
#need a select statement on the end of the next line to put the properties in an expected order for the string compare. The Azure API will randomly change the order.
$currentAzurePoliciesNoId = $currentAzurePolicies | Select-Object displayName, state, sessionControls, conditions, grantControls

$currentLocalPolicies = Get-ChildItem -Path $localPolicyPath -Filter '*.policy.json' | ForEach-Object {Get-Content -Path $_.FullName | ConvertFrom-Json -Depth 5 | Select-Object displayName, state, sessionControls, conditions, grantControls}

$NameDifferences = Compare-Object -ReferenceObject $currentAzurePoliciesNoId.displayName -DifferenceObject $currentLocalPolicies.displayName -IncludeEqual
$policiesToDelete = $NameDifferences | Where-Object {$_.SideIndicator -eq "<="}
$policiesToCreate = $NameDifferences | Where-Object {$_.SideIndicator -eq "=>"}
$policiesToCheckForUpdates = $NameDifferences | Where-Object {$_.SideIndicator -eq "=="}
$policiesToUpdate = @()

foreach ($policy in $policiesToCheckForUpdates) 
{
    $localPolicy = $currentLocalPolicies | Where-Object {$_.displayName -eq $policy.InputObject} | ConvertTo-Json -Depth 3
    $azurePolicy = $currentAzurePoliciesNoId | Where-Object {$_.displayName -eq $policy.InputObject} | ConvertTo-Json -Depth 3

    if ($localPolicy -ne $azurePolicy)
    {
        $policiesToUpdate += [PSCustomObject]@{
            AzurePolicy = $azurePolicy;
            AzurePolicyId = $currentAzurePolicies | Where-Object {$_.displayName -eq $policy.InputObject} | Select-Object -ExpandProperty id;
            AzurePolicyDisplayName = $policy.InputObject;
            LocalPolicy = $localPolicy;
        }
    }
}
#endregion FindChanges

Write-Host "Policies to delete:"$policiesToDelete.Count -ForegroundColor Red
Write-Host "Policies to create:"$policiesToCreate.Count -ForegroundColor Green
Write-Host "Policies to Update:"$policiesToUpdate.Count -ForegroundColor Yellow

#region ProcessChanges
foreach ($policy in $policiesToDelete) 
{
    $policyId = $($currentAzurePolicies | Where-Object {$_.displayName -eq $policy.InputObject}).id
    Write-Host "Attempting to delete '$($policy.InputObject)' with ID: '$policyId'"
    if(!$DryRun) 
    {
        Remove-GraphConditionalAccessPolicy -accessToken $token.AccessToken -Id $policyId
    }
    else
    {
        Write-Host "Dry Run Enabled - Skipping actual provisioning" -ForegroundColor Green    
    }
    Write-Host "Successfully deleted '$($policy.InputObject)' with ID: '$policyId'"
}

foreach ($policy in $policiesToCreate)
{
    Write-Host "Attempting to create '$($policy.InputObject)'"
    if(!$DryRun) 
    {
        New-GraphConditionalAccessPolicy -accessToken $token.AccessToken -requestBody $($currentLocalPolicies | Where-Object {$_.displayName -eq $policy.InputObject} | ConvertTo-Json -Depth 3 -Compress)
    }
    else
    {
        Write-Host "Dry Run Enabled - Skipping actual provisioning" -ForegroundColor Green    
    }
    Write-Host "Successfully created '$($policy.InputObject)'"
}

foreach ($policy in $policiesToUpdate)
{
    Write-Host "Attempting to update '$($policy.AzurePolicyDisplayName)' with ID: '$($policy.AzurePolicyId)'"
    if(!$DryRun) 
    {
        Set-GraphConditionalAccessPolicy -accessToken $token.AccessToken -requestBody $policy.LocalPolicy -Id $policy.AzurePolicyId
    }
    else
    {
        Write-Host "Dry Run Enabled - Skipping actual provisioning" -ForegroundColor Green    
    }
    Write-Host "Successfully updated '$($policy.AzurePolicyDisplayName)' with ID: '$($policy.AzurePolicyId)'"
}