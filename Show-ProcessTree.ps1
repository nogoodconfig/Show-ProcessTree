$IdLookup = @{}
$ParentLookup = @{}
$Orphans = @()

$Processes = Get-WMIObject -Class Win32_Process

foreach ($Process in $Processes)
{
    $IdLookup[$Process.ProcessId] = $Process
    if (($Process.ParentProcessId -eq 0) -or (!$IdLookup.ContainsKey($Process.ParentProcessId)))
    {
        $Orphans += $Process
        continue
    }

    if (!$ParentLookup.ContainsKey($Process.ParentProcessId))
    {
        $ParentLookup[$Process.ParentProcessId] = @()
    }

    $Siblings = $ParentLookup[$Process.ParentProcessId]
    $Siblings += $Process
    $ParentLookup[$Process.ParentProcessId] = $Siblings
}

function Show-ProcessTree($ProcessId, $IndentLevel)
{
  $Process = $IdLookup[$ProcessId]
  $Indent = "-" * $IndentLevel
  Write-Output ("{1}-| {0} PID: {2} PPID: {3}" -f $Process.ProcessName, $Indent, $Process.ProcessId, $Process.ParentProcessId)
  foreach ($Child in ($ParentLookup[$ProcessId] | Sort-Object CreationDate))
  {
    Show-ProcessTree $Child.ProcessId ($IndentLevel + 1)
  }
}

foreach ($Process in ($Orphans | Sort-Object CreationDate))
{
  Show-ProcessTree $Process.ProcessId 1
}
