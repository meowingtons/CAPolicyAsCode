Param(
    [string]$VariablesFile = "$PSScriptRoot/../policies/placeholders.csv",
    [string]$ConfigDirectory = "$PSScriptRoot/../policies",
    [string]$OutputDirectory = "",
    [Parameter(Mandatory=$true)][string]$Environment
)

$ErrorActionPreference = 'Stop'

if ($Environment -ne "production") {
    $Environment = "development"
}

$tokens = @()
$variables = Import-Csv -Path $variablesFile
foreach ($var in $variables) {
        $tokens += @{Name = "%%$($var.Name)%%"; Value = $var.$environment}
}

foreach ($file in Get-ChildItem -Path $configDirectory -Filter "*.policy.json" -Recurse) {
    $content = Get-Content -Raw $file.FullName
    if ($content -match "\%\%[\w-_\.]+\%\%") {
        Write-Host "Applying customizations to $($file.Name)"
        foreach ($token in $tokens) {
            if ($token.Value -ne "ignore") {
                $content = $content -replace $token.Name, $token.Value
            }
            else {
                $content = $content -split "`n" | Select-String -NotMatch -Pattern $($token.Name) | Where-Object {$_.ToString().trim() -ne "" } | Out-String
            }
        }
    }

    if ($OutputDirectory -ne "") {
        $content | Out-File "$OutputDirectory/$($file.Name)"
    }
    else 
    {
        $content | Set-Content $file.FullName
    }
}
