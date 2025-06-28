# PowerShell script to export scheduled tasks to CSV format
# Output location: C:\Temp

# Ensure the output directory exists
$OutputPath = "C:\Temp"
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force
}

# Get the server name
$ServerName = $env:COMPUTERNAME

# Get all scheduled tasks (including disabled ones)
$Tasks = Get-ScheduledTask

# Create an array to store task information
$TaskInfo = @()

foreach ($Task in $Tasks) {
    try {
        # Get task details
        $TaskDetail = Get-ScheduledTaskInfo -TaskName $Task.TaskName -TaskPath $Task.TaskPath -ErrorAction SilentlyContinue
        
        # Get security settings from task principal
        $Principal = $Task.Principal
        $Author = if ($Task.Author) { $Task.Author } else { "Unknown" }
        $RunAsAccount = if ($Principal -and $Principal.UserId) { $Principal.UserId } else { "Unknown" }
        
        # Determine logon type
        $UserLoggedOn = switch ($Principal.LogonType) {
            "Interactive" { "User must be logged on" }
            "Password" { "Run whether user is logged on or not" }
            "S4U" { "Run whether user is logged on or not" }
            "InteractiveOrPassword" { "Run only when user is logged on" }
            "ServiceAccount" { "Run whether user is logged on or not" }
            default { "Unknown" }
        }
        
        # Check if task runs with highest privileges
        $HighestPrivileges = if ($Principal -and $Principal.RunLevel -eq "Highest") { "Yes" } else { "No" }
        
        # Format Last Run Time and Next Run Time
        $LastRunTime = if ($TaskDetail -and $TaskDetail.LastRunTime) {
            try { $TaskDetail.LastRunTime.ToString('dd-MM-yyyy HH:mm') }
            catch { "Unknown" }
        } else { "Never" }
        
        $NextRunTime = if ($TaskDetail -and $TaskDetail.NextRunTime) {
            try { $TaskDetail.NextRunTime.ToString('dd-MM-yyyy HH:mm') }
            catch { "Unknown" }
        } else { "Not scheduled" }
        
        # Get trigger information
        $Triggers = $Task.Triggers
        $TriggerText = ""
        
        if ($Triggers) {
            $TriggerDescriptions = @()
            foreach ($Trigger in $Triggers) {
                switch ($Trigger.CimClass.CimClassName) {
                    "MSFT_TaskDailyTrigger" {
                        $StartTime = if ($Trigger.StartBoundary) { 
                            try { [DateTime]$Trigger.StartBoundary | Get-Date -Format 'HH:mm' } 
                            catch { "Unknown time" }
                        } else { "Unknown time" }
                        $TriggerDescriptions += "Daily at $StartTime"
                    }
                    "MSFT_TaskWeeklyTrigger" {
                        $Days = @()
                        if ($Trigger.DaysOfWeek -band 1) { $Days += "Sunday" }
                        if ($Trigger.DaysOfWeek -band 2) { $Days += "Monday" }
                        if ($Trigger.DaysOfWeek -band 4) { $Days += "Tuesday" }
                        if ($Trigger.DaysOfWeek -band 8) { $Days += "Wednesday" }
                        if ($Trigger.DaysOfWeek -band 16) { $Days += "Thursday" }
                        if ($Trigger.DaysOfWeek -band 32) { $Days += "Friday" }
                        if ($Trigger.DaysOfWeek -band 64) { $Days += "Saturday" }
                        
                        $DayText = if ($Days.Count -gt 0) { $Days -join ", " } else { "Unknown days" }
                        $IntervalText = if ($Trigger.WeeksInterval -gt 1) { " every $($Trigger.WeeksInterval) weeks" } else { "" }
                        
                        $StartTime = if ($Trigger.StartBoundary) { 
                            try { [DateTime]$Trigger.StartBoundary | Get-Date -Format 'HH:mm' } 
                            catch { "Unknown time" }
                        } else { "Unknown time" }
                        
                        $TriggerDescriptions += "$StartTime every $DayText$IntervalText"
                    }
                    "MSFT_TaskTimeTrigger" {
                        $StartDateTime = if ($Trigger.StartBoundary) { 
                            try { [DateTime]$Trigger.StartBoundary | Get-Date -Format 'yyyy-MM-dd HH:mm' } 
                            catch { "Unknown date/time" }
                        } else { "Unknown date/time" }
                        $TriggerDescriptions += "One time at $StartDateTime"
                    }
                    "MSFT_TaskBootTrigger" {
                        $TriggerDescriptions += "At startup"
                    }
                    "MSFT_TaskLogonTrigger" {
                        $TriggerDescriptions += "At logon"
                    }
                    "MSFT_TaskRepetitionPattern" {
                        if ($Trigger.Interval) {
                            $TriggerDescriptions += "Repeats every $($Trigger.Interval)"
                        }
                    }
                    default {
                        $TriggerDescriptions += "Custom trigger"
                    }
                }
            }
            $TriggerText = $TriggerDescriptions -join "; "
        } else {
            $TriggerText = "No triggers defined"
        }
        
        # Extract folder name from task path
        $FolderName = if ($Task.TaskPath -eq "\") { "Root" } else { $Task.TaskPath.Trim("\") }
        
        # Apply filters - skip tasks that match exclusion criteria
        $SkipTask = $false
        
        # Skip if Folder Name starts with Microsoft\
        if ($FolderName -like "Microsoft\*") {
            $SkipTask = $true
        }
        
        # Skip if Task Name starts with specified prefixes
        $ExcludedTaskPrefixes = @(
            "MicrosoftEdgeUpdate",
            "SensorFramework", 
            "User_Feed_Synchronization",
            "CheckAutoServices",
            "Configuration Manager Health Evaluation",
            "CreateExplorerShellUnelevatedTask"
        )
        
        foreach ($Prefix in $ExcludedTaskPrefixes) {
            if ($Task.TaskName -like "$Prefix*") {
                $SkipTask = $true
                break
            }
        }
        
        # Skip this task if it matches exclusion criteria
        if ($SkipTask) {
            continue
        }
        
        # Create custom object with the required properties
        $TaskObj = [PSCustomObject]@{
            "Task Name" = $Task.TaskName
            "Server" = $ServerName
            "Folder Name" = $FolderName
            "Triggers" = $TriggerText
            "Status" = $Task.State
            "Last Run Time" = $LastRunTime
            "Next Run Time" = $NextRunTime
            "Author" = $Author
            "Run As Account" = $RunAsAccount
            "User Logged On" = $UserLoggedOn
            "Highest Privileges" = $HighestPrivileges
        }
        
        $TaskInfo += $TaskObj
        
    } catch {
        Write-Warning "Error processing task $($Task.TaskName): $($_.Exception.Message)"
    }
}

# Export to CSV
$OutputFile = Join-Path $OutputPath "$ServerName-Task-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
$TaskInfo | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "Scheduled tasks exported to: $OutputFile"
Write-Host "Total tasks exported: $($TaskInfo.Count)"

# Copy CSV file to network location
$NetworkPath = "\\igi\root\SCCMSource\Temp"
try {
    if (Test-Path $NetworkPath) {
        $NetworkFile = Join-Path $NetworkPath (Split-Path $OutputFile -Leaf)
        Copy-Item -Path $OutputFile -Destination $NetworkFile -Force
        Write-Host "CSV file copied to network location: $NetworkFile"
    } else {
        Write-Warning "Network path not accessible: $NetworkPath"
    }
} catch {
    Write-Warning "Failed to copy file to network location: $($_.Exception.Message)"
}

# Display the first few rows as preview
Write-Host "`nPreview of exported data:"
$TaskInfo | Select-Object -First 5 | Format-Table -AutoSize
