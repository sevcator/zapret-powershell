#
# sevcator.github.io
#
Clear-Host

# Modifable vars
$folderPath = "C:\Windows\Zapret"
$ARGS = "--wf-tcp=80,443 --wf-udp=80,443,50000-50099 "
$ARGS += "--filter-tcp=80,443 --hostlist-auto=`"$folderPath\autohostlist.txt`" --hostlist-auto-fail-threshold=2 --hostlist-auto-fail-time=60 --hostlist-auto-retrans-threshold=2 --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fooling=md5sig --dpi-desync-fake-tls=`"$folderPath\tls_clienthello_www_google_com.bin`" --dpi-desync-fake-quic=`"$folderPath\quic_initial_www_google_com.bin`" --new "
$ARGS += "--filter-udp=50000-50099 --ipset=`"$folderPath\ipset-discord.txt`" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-any-protocol --dpi-desync-fake-tls=`"$folderPath\tls_clienthello_www_google_com.bin`" --dpi-desync-fake-quic=`"$folderPath\quic_initial_www_google_com.bin`" --new "
$ARGS += "--filter-udp=80,443 --hostlist-auto=`"$folderPath\autohostlist.txt`" --hostlist-auto-fail-threshold=2 --hostlist-auto-fail-time=60 --hostlist-auto-retrans-threshold=2 --dpi-desync=fake,split2 --dpi-desync-repeats=11 --dpi-desync-fake-tls=`"$folderPath\tls_clienthello_www_google_com.bin`" --dpi-desync-fake-quic=`"$folderPath\quic_initial_www_google_com.bin`""

Write-Host "  ______                         _   " -ForegroundColor Cyan
Write-Host " |___  /                        | |  " -ForegroundColor Cyan
Write-Host "    / /  __ _  _ __   _ __  ___ | |_ " -ForegroundColor Cyan
Write-Host "   / /  / _` || '_ \ | '__|/ _ \| __|" -ForegroundColor Cyan
Write-Host "  / /__| (_| || |_) || |  |  __/| |_ " -ForegroundColor Cyan
Write-Host " /_____|\__,_|| .__/ |_|   \___| \__|" -ForegroundColor Cyan
Write-Host "              | |                    " -ForegroundColor Cyan
Write-Host "              |_|                    " -ForegroundColor Cyan
Write-Host "** github.com/sevcator/zapret-powershell"
Write-Host "** github.com/bol-van/zapret"
Write-Host "** github.com/bol-van/zapret-win-bundle"
Write-Host ""

function Check-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Check-Admin)) {
    Add-Type -AssemblyName System.Windows.Forms 
    [System.Windows.Forms.MessageBox]::Show("zapret-sevcator | Run as administrator rights!")
    return
}

$initialDirectory = Get-Location

Write-Host "--- START INSTALLATION ---"

$version = [System.Environment]::OSVersion.Version

$windows10Version = New-Object System.Version(10, 0)

if ($version -gt $windows10Version) {
    Write-Output "Windows version: $version"
} else {
    Write-Host "Your version of Windows is old!" -ForegroundColor White
    return
}

Write-Host "Terminating processes"

$processesToKill = @("GoodbyeDPI.exe", "winws.exe", "zapret.exe")

foreach ($process in $processesToKill) {
    try {
        Stop-Process -Name $process -Force -ErrorAction Stop
        Write-Host "${process}: Killed"
    } catch {
        if ($_.Exception.Message -like "*not running*") {
            Write-Host "${process}: Process not found" -ForegroundColor White
        } else {
            Write-Host ("{0}: {1}" -f $process, $_.Exception.Message) -ForegroundColor White
        }
    }
}

Write-Host "Checking services"
$servicesToStop = @("zapret", "winws1", "goodbyedpi", "windivert", "windivert14")
foreach ($service in $servicesToStop) {
    $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue

    if ($serviceStatus) {
        Write-Host "${service}: Stopping"
        # Stop the service and handle potential errors
        try {
            Stop-Service -Name $service -Force -ErrorAction Stop
            Write-Host "${service}: Stopped successfully"
        } catch {
            Write-Host ("{0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Red
        }
        
        try {
            sc.exe delete $service -ErrorAction Stop | Out-Null
            Write-Host "${service}: Deleted"
        } catch {
            Write-Host ("{0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Yellow
	    Write-Host "If you have problems, try restart your machine!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "${service}: Not found" -ForegroundColor White
    }
}

if (Test-Path $folderPath) {
    Get-ChildItem -Path $folderPath | Remove-Item -Force -ErrorAction SilentlyContinue | Out-Null
}

if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
}

$exclusionPath = "$folderPath\winws.exe"

if (-not (Test-Path $exclusionPath)) {
    New-Item -Path $exclusionPath -ItemType File | Out-Null
    Write-Host "${exclusionPath}: Created"
} else {
    Write-Host "${exclusionPath}: Already exists" -ForegroundColor Yellow
}

try {
    Add-MpPreference -ExclusionPath $exclusionPath
    Write-Host "${exclusionPath}: Added to exclusions in Windows Defender"
    Start-Sleep -Seconds 5
} catch {
    Write-Host ("${exclusionPath}: Error to add exclusion - {0}" -f $_.Exception.Message) -ForegroundColor Red
}


$files = @(
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/WinDivert.dll"; Name = "WinDivert.dll"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/WinDivert64.sys"; Name = "WinDivert64.sys"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/cygwin1.dll"; Name = "cygwin1.dll"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/winws.exe"; Name = "winws.exe"},
    @{Url = "https://raw.githubusercontent.com/bol-van/zapret-win-bundle/refs/heads/master/zapret-winws/ipset-discord.txt"; Name = "ipset-discord.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/autohostlist.txt"; Name = "autohostlist.txt"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/tls_clienthello_www_google_com.bin"; Name = "tls_clienthello_www_google_com.bin"}
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/quic_initial_www_google_com.bin"; Name = "quic_initial_www_google_com.bin"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/uninstall.cmd"; Name = "uninstall.cmd"}
)

foreach ($file in $files) {
    try {
        Invoke-WebRequest -Uri $file.Url -OutFile "$folderPath\$($file.Name)" -ErrorAction Stop | Out-Null
        Write-Host "$($file.Name): Downloaded"
    } catch {
        Write-Host ("{0}: {1}" -f $($file.Name), $_.Exception.Message) -ForegroundColor Red
    }
}

Set-Location $folderPath | Out-Null

try {
    sc.exe create winws1 binPath= "`"$folderPath\winws.exe $ARGS`"" DisplayName= "zapret DPI bypass" start= auto | Out-Null
    sc.exe start winws1 | Out-Null
    Write-Host "Service created and started!"
} catch {
    Write-Host ("Failed to create or start service: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

Write-Host "--- END OF INSTALLATION ---"
Write-Host ""
Write-Host "Done! Now enjoy."
Write-Host "To remove Zapret, run script located in $folderPath\uninstall.cmd as administrator!" -ForegroundColor Yellow
Write-Host ""
Write-Host "--- NOTES ---"
Write-Host ""
Write-Host "!! Have a problems with YouTube and something? Try fix your browser: set to default flags in experemental features (if you do something) or enable Secure DNS (example: 1.1.1.1 or OpenDNS)" -ForegroundColor Gray
Write-Host "!! If Discord stucks on 'Checking for updates...' terminate process and open again" -ForegroundColor Gray
Write-Host ""
Write-Host "!!! On some providers this DPI Bypass may not working! Uninstall and use VPN or something else (try other zapret)" -ForegroundColor Gray
Write-Host ""
Write-Host "Follow me ** sevcator.github.io"
Write-Host ""
Set-Location $initialDirectory
