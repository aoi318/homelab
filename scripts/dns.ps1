<#
  dns.ps1  -  Phase 1 / Step 6: ラボ用 DNS 切替トグル(デスクトップ母艦)

  lab on : 物理LANの DNS を infra01 (192.168.10.10) 単独に。
           ISPの IPv6 DNS が lab.local を NXDOMAIN で奪うのを防ぐため IPv6 DNS はクリア。
  lab off: IPv4 DNS を {192.168.10.1, 1.1.1.1} に戻し、IPv6 DNS は DHCP(ISP)へ戻す。

  使い方:
    powershell -ExecutionPolicy Bypass -File .\scripts\dns.ps1 -Mode on
    powershell -ExecutionPolicy Bypass -File .\scripts\dns.ps1 -Mode off
    powershell -ExecutionPolicy Bypass -File .\scripts\dns.ps1 -Mode status   # 確認のみ(管理者不要)
  ※ on/off は自動で管理者昇格(UAC)します。
#>
param(
    [ValidateSet('on','off','status')]
    [string]$Mode = 'status'
)

$LAB_DNS_V4 = @('192.168.10.10')
$OFF_DNS_V4 = @('192.168.10.1','1.1.1.1')
$LAB_NS     = '.lab.local'          # NRPTで infra01 に固定する名前空間

function Get-LabAdapter {
    # 既定ルートを持つ物理アダプタ(WSL/Hyper-V仮想は除外)
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
             Sort-Object RouteMetric | Select-Object -First 1
    if ($route) {
        $a = Get-NetAdapter -InterfaceIndex $route.InterfaceIndex -ErrorAction SilentlyContinue
        if ($a -and $a.InterfaceDescription -notmatch 'Hyper-V|Virtual|WSL') { return $a }
    }
    Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1
}

function Show-Status($adapter) {
    $v4 = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4).ServerAddresses
    $v6 = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv6).ServerAddresses
    Write-Host ("Adapter  : {0} (ifIndex {1})" -f $adapter.Name, $adapter.ifIndex)
    Write-Host ("DNS IPv4 : {0}" -f ($(if ($v4) { $v4 -join ', ' } else { '(none)' })))
    Write-Host ("DNS IPv6 : {0}" -f ($(if ($v6) { $v6 -join ', ' } else { '(none)' })))
    $nrpt = Get-DnsClientNrptRule -ErrorAction SilentlyContinue | Where-Object { $_.Namespace -contains $LAB_NS }
    Write-Host ("NRPT     : {0}" -f ($(if ($nrpt) { "$LAB_NS -> $($nrpt.NameServers -join ',')" } else { '(none)' })))
    if (($v4 -contains '192.168.10.10') -or $nrpt) { Write-Host 'State    : LAB ON'  -ForegroundColor Green }
    else                                           { Write-Host 'State    : LAB OFF' -ForegroundColor Yellow }
}

$adapter = Get-LabAdapter
if (-not $adapter) { Write-Error 'LANアダプタが見つかりません'; exit 1 }

if ($Mode -eq 'status') { Show-Status $adapter; exit 0 }

# on/off は管理者権限が必要 -> 自己昇格(UAC)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
    Write-Host '管理者権限が必要です -> UACで昇格します...' -ForegroundColor Cyan
    Start-Process powershell -Verb RunAs -ArgumentList @(
        '-NoExit','-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"",'-Mode',$Mode
    )
    exit
}

switch ($Mode) {
    'on' {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $LAB_DNS_V4
        # lab.local は NRPT で必ず infra01 へ(インタフェースのIPv6 ISP DNSに奪われないように)
        Get-DnsClientNrptRule -ErrorAction SilentlyContinue |
            Where-Object { $_.Namespace -contains $LAB_NS } |
            Remove-DnsClientNrptRule -Force -ErrorAction SilentlyContinue
        Add-DnsClientNrptRule -Namespace $LAB_NS -NameServers $LAB_DNS_V4
    }
    'off' {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $OFF_DNS_V4
        # NRPTルールを削除して通常DNSへ
        Get-DnsClientNrptRule -ErrorAction SilentlyContinue |
            Where-Object { $_.Namespace -contains $LAB_NS } |
            Remove-DnsClientNrptRule -Force -ErrorAction SilentlyContinue
    }
}
Clear-DnsClientCache
Write-Host ("== lab {0} applied ==" -f $Mode) -ForegroundColor Green
Show-Status $adapter
