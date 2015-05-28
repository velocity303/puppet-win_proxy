# == Class: win_proxy
#
# This module allows you to set the following settings within the snap in.
# - Automatically Detect Settings
# - Use Automatic Configuration Script
#   - Address
# - Use a proxy server for your LAN (These settings will not apply to dial-up or VPN connections)
#   - Address
#   - Port
#   - Bypass proxy server for local address
#
# At this time this module does not allow for more advanced configurations past these settings.
#
# Full description of class win_proxy here.
#
# === Parameters
#
# $autodetect
# This accepts a boolean for whether "Automatically Detect Settings" should be enabled or disabled (Default: true)
#
# $staticproxy
# This accepts a boolean for whether "Use a proxy server for your LAN" should be enabled or disabled (Default: false)
#
# $proxyserver
# This accepts a string containing the static proxy server you would like to use. It will only take affect if $staticproxy is true It should be formatted as 'hostname:port'. (Default: '127.0.0.1:80')
#
# $localoverride
# This accepts a boolean for whether "Bypass proxy server for local addresses" should be enabled or disabled. This only takes affect if $staticproxy is true. (Default: false)

# $autoscript
# This accepts a boolean as to whether "Use automatic configuration script" should be enabled or disabled. (Default: false)

# $autoscript_url
# This accepts a string containing the address you would like to use if utilizing "Use automatic configuration script". This will only take affect if $autoscript is set to true. (Default: 'http://test.example.com/file.pac')
#
# === Examples
#
# class {'win_proxy':
#   autodetect     => true,
#   staticproxy    => true,
#   proxyserver    => '127.0.0.1:80',
#   localoverride  => false,
#   autoscript     => false,
#   autoscript_url => 'http://myproxyscript.lan/script.pac',
# }
#
# === Authors
#
# James E. Jones <velocity303@gmail.com>
#
# === Copyright
#
# Copyright 2015 James E. Jones 
#
class win_proxy (
  $autodetect     = true,
  $staticproxy    = false,
  $proxyserver    = '127.0.0.1:8080',
  $localoverride  = false,
  $autoscript     = false,
  $autoscript_url = 'http://test.example.com/proxy.pac',
)
{
  validate_bool($autodetect)
  validate_bool($staticproxy)
  validate_bool($localoverride)
  validate_bool($autoscript)

  if $autodetect == true and $autoscript == true and $staticproxy == true {
    $bitnum = 15
  }
  if $autodetect == true and $autoscript == true and $staticproxy == false {
    $bitnum = 13
  }
  if $autodetect == true and $autoscript == false and $staticproxy == true {
    $bitnum = 11
  }
  if $autodetect == true and $autoscript == false and $staticproxy == false {
    $bitnum = 9
  }
  if $autodetect == false and $autoscript == true and $staticproxy == true {
    $bitnum = 7
  }
  if $autodetect == false and $autoscript == true and $staticproxy == false {
    $bitnum = 5
  }
  if $autodetect == false and $autoscript == false and $staticproxy == true {
    $bitnum = 3
  }
  if $autodetect == false and $autoscript == false and $staticproxy == false {
    $bitnum = 1
  }
  exec { 'Set Default Connection Settings':
    command  => "\$regKeyPath = \"HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\Connections\"; \$conSet = $(Get-ItemProperty \$regKeyPath).DefaultConnectionSettings; \$conSet[8] = ${bitnum}; Set-ItemProperty -Path \$regKeyPath -Name DefaultConnectionSettings -Value \$conSet; Set-ItemProperty -Path \$regKeyPath -Name DefaultConnectionSettings -Value \$conSet",
    provider => powershell,
    unless   => "if ($(Get-ItemProperty \"HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\Connections\").DefaultConnectionSettings[8] -eq ${bitnum})  {return 0} else {write-error 1}",
  }
  if $staticproxy == true {
    exec { 'Turn on specified proxy':
      command   => "\$proxyServerToDefine = \"${proxyserver}\"; \$regKey=\"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\"; Set-ItemProperty -path \$regKey -name ProxyEnable -value 1; Set-ItemProperty -path \$regKey ProxyServer -value \$proxyServerToDefine",
      provider  => powershell,
      unless    => "\$proxyServerToDefine = \"${proxyserver}\"; \$regKey=\"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\"; if((Get-ItemProperty -path \$regKey -name ProxyServer).ProxyServer -eq \$proxyServerToDefine) {return 0} else {write-error 1}",
      require   => Exec['Set Default Connection Settings'],
    }
    if $localoverride == true {
      exec { 'Turn on local proxy override':
        command  => '$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"; Set-ItemProperty -path $regKey -name ProxyOverride -value "<local>"',
        provider => powershell,
        unless   => '$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\";try { Get-ItemProperty -path $regKey | select-object -ExpandProperty ProxyOverride -ErrorAction stop | Out-Null } catch { write-error 1}',
      }
    }
    else {
      exec { 'Turn off local proxy override':
        command  => '$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"; Remove-ItemProperty -path $regKey -name ProxyOverride',
        provider => powershell,
        onlyif   => '$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\";try { Get-ItemProperty -path $regKey | select-object -ExpandProperty ProxyOverride -ErrorAction stop | Out-Null } catch { write-error 1}',
      }
    }
  }
  else {
    exec { 'Turn off proxy settings if they exist':
      command   => '$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"; Remove-ItemProperty -path $regKey -name ProxyServer; Set-ItemProperty -path $regKey -name ProxyEnable -value 0; Remove-ItemProperty -path $regKey -name ProxyOverride',
      provider  => powershell,
      onlyif    => '$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\";try { Get-ItemProperty -path $regKey | select-object -ExpandProperty ProxyServer -ErrorAction stop | Out-Null } catch { write-error 1}',
    }
  }
  if $autoscript == true {
    exec { 'Turn on specified autoconfig script':
      command   => "\$proxyConfigToDefine = \"${autoscript_url}\"; \$regKey=\"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\"; Set-ItemProperty -path \$regKey AutoConfigURL -value \$proxyConfigToDefine",
      provider  => powershell,
      unless    => "\$proxyConfigToDefine = \"${autoscript_url}\"; \$regKey=\"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\"; if((Get-ItemProperty -path \$regKey -name AutoConfigURL).AutoConfigURL -eq \$proxyConfigToDefine) {return 0} else {write-error 1}",
      require   => Exec['Set Default Connection Settings'],
    }
  }
  else {
    exec { 'Turn off specified autoconfig script':
      command   => '$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"; Remove-ItemProperty -path $regKey -name AutoConfigURL',
      provider  => powershell,
      onlyif    => '$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\";try { Get-ItemProperty -path $regKey | select-object -ExpandProperty AutoConfigURL -ErrorAction stop | Out-Null } catch { write-error 1}',
    }
  }
}
