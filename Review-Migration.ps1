#Requires -Version 5.1
[CmdletBinding()]
param([string]$WinGetExport)
$ErrorActionPreference = 'Stop'
$warnings = @()
$packages = @()
$temp = $null
try {
    if (!$WinGetExport) {
        $temp = Join-Path ([IO.Path]::GetTempPath()) ("migration-" + [guid]::NewGuid() + ".json")
        & winget export --output $temp --disable-interactivity | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "WinGet export exit code $LASTEXITCODE" }
        $WinGetExport = $temp
    }
    $export = Get-Content -Raw -LiteralPath $WinGetExport | ConvertFrom-Json
    if ($null -eq $export.Sources) { throw 'Missing Sources array' }
    $packages = @(foreach ($source in $export.Sources) {
        foreach ($pkg in $source.Packages) {
            if (!$pkg.PackageIdentifier) { throw 'Missing package identifier' }
            [pscustomobject]@{Kind='Package'; Key=($source.SourceDetails.Identifier + '/' + $pkg.PackageIdentifier); Name=$pkg.PackageIdentifier}
        }
    })
} catch { $warnings += "WinGet inventory incomplete: $_" }
finally { if ($temp -and [IO.File]::Exists($temp)) { [IO.File]::Delete($temp) } }
$apps = @(foreach ($scope in 'HKLM','HKCU') {
    foreach ($branch in 'SOFTWARE','SOFTWARE\Wow6432Node') {
        $path = $scope + ':\' + $branch + '\Microsoft\Windows\CurrentVersion\Uninstall'
        try {
            if (Test-Path -LiteralPath $path) {
                Get-ItemProperty "$path\*" | Where-Object DisplayName | ForEach-Object {
                    [pscustomobject]@{Kind='Registration'; Key=("$scope/$branch/" + $_.PSChildName + '/' + $_.Publisher); Name=$_.DisplayName}
                }
            }
        } catch { $warnings += "Incomplete registry inventory for $path" }
    }
})
[pscustomobject]@{Format='migration-1'; Items=@($packages + $apps); Warnings=$warnings} | ConvertTo-Json -Depth 5
