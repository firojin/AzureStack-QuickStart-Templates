param(
	[parameter(Mandatory = $true)][System.String]$ServiceUserName
)

function LogToFile
{
   param (
		[parameter(Mandatory = $true)][System.String]$Message,
		[System.String]$LogFilePath = "$env:SystemDrive\CustomScriptExtensionLogs\CustomScriptExtension.log"
   )
   $timestamp = Get-Date -Format s
   $logLine = "[$($timestamp)] $($Message)"
   Add-Content $LogFilePath -value $logLine
}

# Create log file
$logFolderName = "CustomScriptExtensionLogs"
$logFolderPath = Join-Path $env:SystemDrive $logFolderName
if(!(Test-Path $logFolderPath))
{
	New-Item $logFolderPath -ItemType directory	
}
$logFileName = "CustomScriptExtension.log"
$logFilePath = Join-Path $logFolderPath $logFileName
if(!(Test-Path $logFilePath))
{
	New-Item $logFilePath -ItemType file	
}

Import-Module NetSecurity -ErrorAction SilentlyContinue
LogToFile -Message "Adding domain user $($ServiceUserName) to the local administrators group"
$Domain = (Get-WmiObject Win32_ComputerSystem).Domain
$group = [ADSI]"WinNT://localhost/Administrators,group"
$members = $group.psbase.Invoke("Members")
if(($members | foreach {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}) -notcontains $ServiceUserName)
{
	$group.psbase.Invoke("Add",([ADSI]"WinNT://$Domain/$ServiceUserName").path)
}
LogToFile -Message "Done adding domain user $($ServiceUserName) to the local administrators group"

LogToFile -Message "Enabling fire wall rules for remote performance counter capture"
Enable-NetFirewallRule –Group "@FirewallAPI.dll,-34752"
LogToFile -Message "Done enabling fire wall rules for remote performance counter capture"