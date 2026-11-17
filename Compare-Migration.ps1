#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OldManifest,[string]$NewManifest,[string[]]$LeaveBehind=@())
$ErrorActionPreference = 'Stop'
$old = Get-Content -Raw -LiteralPath $OldManifest | ConvertFrom-Json
if ($NewManifest) { $new = Get-Content -Raw -LiteralPath $NewManifest | ConvertFrom-Json }
else { $new = & "$PSScriptRoot\Review-Migration.ps1" | ConvertFrom-Json }
foreach ($report in $old,$new) {
    foreach ($item in $report.Items) {
        if ($item.Kind -notin 'Package','Registration' -or [string]::IsNullOrWhiteSpace($item.Key)) {
            throw 'Manifest item needs a recognized Kind and nonempty Key.'
        }
    }
    if ($report.Format -ne 'migration-1' -or $report.Items -isnot [array]) { throw 'Expected a migration-1 manifest.' }
}
$observed = @{}
foreach ($item in $new.Items) { $observed[$item.Kind + ':' + $item.Key] = $true }
$results = @(foreach ($item in $old.Items) {
    $id = $item.Kind + ':' + $item.Key
    $status = if ($LeaveBehind -contains $id) { 'Intentionally left behind' }
        elseif ($observed.ContainsKey($id)) { 'Present' }
        elseif ($new.Warnings.Count) { 'Uncertain (partial inventory)' }
        else { 'No matching identity observed' }
    [pscustomobject]@{Name=$item.Name; Id=$id; Status=$status}
})
[pscustomobject]@{Results=$results; OldWarnings=$old.Warnings; NewWarnings=$new.Warnings} | ConvertTo-Json -Depth 5
