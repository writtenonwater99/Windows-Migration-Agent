# Windows Migration Agent

Compare installed Windows desktop registrations and WinGet package IDs before and after a PC migration. Produce a local reinstall and backup checklist.

## For AI agents

Start with [AGENTS.md](AGENTS.md). Run the scripts as the signed-in user in Windows PowerShell 5.1. Keep reports local unless the owner chooses to share them.

## Usage

```powershell
.\Review-Migration.ps1 | Set-Content old.json
.\Compare-Migration.ps1 -OldManifest .\old.json
```

Run the first command on the old PC. Copy the manifest privately to the new PC and run the second command there. Supply -WinGetExport to read an existing WinGet JSON export, or -NewManifest to compare two saved manifests. Pass exact result IDs to -LeaveBehind to record intentional omissions in the comparison. The scripts use native Windows PowerShell and work in the current account. Use a 64-bit shell on 64-bit Windows.
