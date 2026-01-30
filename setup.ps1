# ﻿Set-ExecutionPolicy Bypass -Scope Process -Force
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# variables // change as needed
$hostonly_mac = "52:54:00:d4:e2:8d" # MAC address of the guest's host-only interface
$hostonly_gateway = "10.0.0.1" # gateway IP of host-only interface 
$hostonly_subnet = 30 # subnet prefix length for host-only adapter
$hostonly_ip = "10.0.0.2" # VM's host-only IP

$nat_mac = "52:54:00:4f:ae:80" # MAC address of the guest's NAT interface
$nat_gateway = "172.16.20.1" # gateway IP of NAT interface
$nat_subnet = 30 # subnet prefix length for NAT adapter
$nat_ip = "172.16.20.2" # VM's NAT IP

$http_server_port = 8888 # python http.server port

# configuring host-only adapter
write-host "configuring host-only adapter..."
$hostonly_mac=$hostonly_mac.ToUpper().Replace(":", "-")
$hostonly_adpt = (Get-NetAdapter | select Name, ifIndex, MacAddress | Where-Object {$_.MacAddress -eq $hostonly_mac})
Remove-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $hostonly_adpt.ifIndex -ErrorAction SilentlyContinue -Confirm:$false
Remove-NetRoute -AddressFamily IPv4 -InterfaceIndex $hostonly_adpt.ifIndex -ErrorAction SilentlyContinue -Confirm:$false
New-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $hostonly_adpt.ifIndex -IPAddress $hostonly_ip -PrefixLength $hostonly_subnet -DefaultGateway $hostonly_gateway
Set-DnsClientServerAddress -InterfaceIndex $hostonly_adpt.ifIndex -ServerAddresses $hostonly_gateway

# configuring NAT adapter
write-host "configuring NAT adapter..."
$nat_mac=$nat_mac.ToUpper().Replace(":", "-")
$nat_adpt = (Get-NetAdapter | select Name, ifIndex, MacAddress | Where-Object {$_.MacAddress -eq $nat_mac})
Remove-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $nat_adpt.ifIndex -ErrorAction SilentlyContinue -Confirm:$false
Remove-NetRoute -AddressFamily IPv4 -InterfaceIndex $nat_adpt.ifIndex -ErrorAction SilentlyContinue -Confirm:$false
New-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $nat_adpt.ifIndex -IPAddress $nat_ip -PrefixLength $nat_subnet -DefaultGateway $nat_gateway
Set-DnsClientServerAddress -InterfaceIndex $nat_adpt.ifIndex -ServerAddresses $nat_gateway

# activating windows
Write-Host "activating windows..."
Write-Host "choose [1] HWID, then go back and [0] to exit"
Start-Sleep 5
irm https://get.activated.win | iex

# performance/appearance settings
$fxpath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
Set-ItemProperty -Path $fxpath -Name VisualFXSetting -Value 3
get-childitem $fxpath | Set-ItemProperty -Name DefaultApplied -Value 0
Set-ItemProperty -Path "$fxpath\FontSmoothing" -Name DefaultApplied -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\" -Name EnableTransparency -Value 0
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\" -Name AppsUseLightTheme -Value 0
powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a
powercfg /setdcvalueindex a1841308-3541-4fab-bc81-f71556f20b4a 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600
powercfg /setacvalueindex a1841308-3541-4fab-bc81-f71556f20b4a 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600

# changing powershell $profile
Set-Content -Path $PROFILE -Value 'function prompt { "PS > " }'
. $PROFILE

# creating and adding defender exclusions for desktop folders
$tools_folder = "$env:userprofile\Desktop\tools"
$mal_folder = "$env:userprofile\Desktop\mal"
$out_folder = "$env:userprofile\Desktop\out"

mkdir $tools_folder; Add-MpPreference -ExclusionPath $tools_folder
mkdir $mal_folder; Add-MpPreference -ExclusionPath $mal_folder
mkdir $out_folder; Add-MpPreference -ExclusionPath $out_folder

# removing trash
winget uninstall "Copilot"
winget uninstall "OneDrive"
winget uninstall "Skype"

# installing Chocolatey
write-host "installing Chocolatey..."
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# installing tools
write-host "installing tools..."
$tools = @(
  'pestudio', 'imhex', 'x64dbg.portable', 'temurin', 'ghidra',
  'cyberchef', 'floss', 'pesieve', 'die', 'capa', 'yara', 'wireshark',
  'sysinternals', 'systeminformer', 'regshot', 'fakenet',
  'upx', '7zip', 'vscode', 'mitmproxy', 'volatility3', 'python',
  'notepadplusplus', 'everything', 'pebear', 'dnspyex'
)
foreach ($tool in $tools) {
  choco install $tool -y --ignore-checksums
}

# installing imhex (NoGPU)
# Invoke-WebRequest -Uri https://github.com/WerWolv/ImHex/releases/download/v1.38.1/imhex-1.38.1-Windows-Portable-NoGPU-x86_64.zip -OutFile ImHex.zip
# Expand-Archive -Path .\ImHex.zip -DestinationPath "$env:ProgramFiles\ImHex"
# Remove-Item .\ImHex.zip

# installing Universal Extractor 2
Invoke-WebRequest -Uri https://github.com/Bioruebe/UniExtract2/releases/download/v2.0.0-rc.3/UniExtractRC3.zip -OutFile UniExtractRC3.zip
Expand-Archive -Path .\UniExtractRC3.zip -DestinationPath "$env:ProgramFiles\UniExtract"
Remove-Item .\UniExtractRC3.zip

# installing api-monitor
Invoke-WebRequest -Uri http://www.rohitab.com/download/api-monitor-v2r13-x86-x64.zip -OutFile api-monitor.zip
Expand-Archive -Path .\api-monitor.zip -DestinationPath .\api-monitor
Move-Item .\api-monitor -Destination $env:ProgramFiles
Remove-Item .\api-monitor.zip

# installing npcap
Invoke-WebRequest -Uri https://npcap.com/dist/npcap-1.85.exe -OutFile npcap-1.85.exe
.\npcap-1.85.exe
Remove-Ttem .\npcap-1.85.exe

# installing disable-defender.exe
Invoke-WebRequest -Uri https://github.com/pgkt04/defender-control/releases/download/v1.5/disable-defender.exe -OutFile $tools_folder\disable-defender.exe

# installing mesa drivers
Write-Host "installing mesa drivers..."
Write-Host "choose '1. Core desktop OpenGL drivers', then 9. Exit"
Start-Sleep 5
Invoke-WebRequest -Uri https://github.com/pal1000/mesa-dist-win/releases/download/25.3.2/mesa3d-25.3.2-release-msvc.7z -OutFile mesa-dist-win.7z
7z.exe x .\mesa-dist-win.7z -omesa-dist-win -y
.\mesa-dist-win\systemwidedeploy.cmd
Remove-Item mesa-dist-win.7z, .\mesa-dist-win -Recurse

# changing screen res
write-host "changing screen resolution..."
Install-Module -Name DisplaySettings
Set-DisplayResolution -Width 1280 -Height 800

# setting wallpaper and locksreen
write-host "setting wallpaper and locksreen..."
$image = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
Set-ItemProperty -path "HKCU:\Control Panel\Desktop\" -name WallPaper -value $image
New-Item -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows" -name "Personalization" -Force
Set-ItemProperty -path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -name "LockScreenImage" -value $image

# allow host machine to access python server
write-host "Creating firewall rule to allow host to access python server..."
$path_to_python = (Get-Command python).source
New-NetFirewallRule -DisplayName "allow_in_host_to_vm_pyhttp" -Enabled True -Action Allow -Direction Inbound -LocalAddress $hostonly_ip -LocalPort $http_server_port -Protocol TCP -RemoteAddress $hostonly_gateway -Profile Any -Program $path_to_python

# disabling redundant rule created by fakenet
# write-host "Disabling stupid fw rule..."
# Set-NetFirewallRule -DisplayName "inbound from internet = block" -Enabled False -ErrorAction SilentlyContinue

# explorer config
Write-Host "configuring file explorer..."
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name Hidden -Value 1
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name HideFileExt -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\" -Name ShowRecent -Value 0
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\" -Name ShowFrequent -Value 0
# Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name ShowSuperHidden -Value 1
Stop-Process -ProcessName explorer -Force

# disabling NAT interface
Write-Host "disabling NAT interface..."
Disable-NetAdapter -Name $nat_adpt.Name -Confirm:$False

# setting proxy for mitmproxy
Write-Host "setting proxy for mitmproxy on (127.0.0.1:8080)..."
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "127.0.0.1:8080"
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value 10.0.0.1

# disabling MS defender
Write-Host "disabling MS defender..."
Start-Process $tools_folder\disable-defender.exe

# reboot
write-host "Done! rebooting in 10s..."
Start-Sleep 10
Restart-Computer -Force

<# do manually
1. clean panel
2. shortcuts of all tools in tools folder (most tools saved to C:\ProgramData\chocolatey\lib)
3. disable all startup apps
4. edge settings (download path, etc.), mal sample DB bookmarks
5. installing root cert for mitmproxy
#>



