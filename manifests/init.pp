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
  Boolean $autodetect     = true,
  Boolean $staticproxy    = false,
  String  $proxyserver    = '127.0.0.1:8080',
  Boolean $localoverride  = false,
  Boolean $autoscript     = false,
  String  $autoscript_url = 'http://test.example.com/proxy.pac',
) {

  # Each option sets a bit in a bitmap. Determine the numeric value of that
  # bitmap. The first value in the bitmap is always 1.
  $bitnum = $autodetect.bool2num  * 8 +
            $autoscript.bool2num  * 4 +
            $staticproxy.bool2num * 2 + 1

  exec { 'Set Default Connection Settings':
    provider => powershell,
    command  => @("SCRIPT"/$),
      \$regKeyPath = "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\Connections"
      \$conSet = $(Get-ItemProperty \$regKeyPath).DefaultConnectionSettings
      \$conSet[8] = ${bitnum}
      Set-ItemProperty -Path \$regKeyPath -Name DefaultConnectionSettings -Value \$conSet
      Set-ItemProperty -Path \$regKeyPath -Name DefaultConnectionSettings -Value \$conSet
      | SCRIPT
    unless   => @("SCRIPT"/$),
      \$regKeyPath = "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\Connections"
      if ($(Get-ItemProperty \$regKeyPath).DefaultConnectionSettings[8] -eq ${bitnum}) {
        return 0
      } else {
        write-error 1
      }
      | SCRIPT
  }

  if $staticproxy {
    exec { 'Turn on specified proxy':
      provider  => powershell,
      require   => Exec['Set Default Connection Settings'],
      command   => @("SCRIPT"/$),
        \$proxyServerToDefine = "${proxyserver}"
        \$regKey="HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings"
        Set-ItemProperty -path \$regKey -name ProxyEnable -value 1
        Set-ItemProperty -path \$regKey ProxyServer -value \$proxyServerToDefine
        | SCRIPT
      unless    => @("SCRIPT"/$)
        \$proxyServerToDefine = "${proxyserver}"
        \$regKey="HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings"
        if((Get-ItemProperty -path \$regKey -name ProxyServer).ProxyServer -eq \$proxyServerToDefine) {
          return 0
        } else {
          write-error 1
        }
        | SCRIPT
    }

    if $localoverride {
      exec { 'Turn on local proxy override':
        provider => powershell,
        command  => @(SCRIPT),
          $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
          Set-ItemProperty -path $regKey -name ProxyOverride -value "<local>"
          | SCRIPT
        unless   => @(SCRIPT),
          $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
          try {
            Get-ItemProperty -path $regKey | select-object -ExpandProperty ProxyOverride -ErrorAction stop | Out-Null
          } catch {
            write-error 1
          }
          | SCRIPT
      }
    }
    else {
      exec { 'Turn off local proxy override':
        provider => powershell,
        command  => @(SCRIPT),
          $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
          Remove-ItemProperty -path $regKey -name ProxyOverride
          | SCRIPT
        onlyif   => @(SCRIPT),
          $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
          try {
            Get-ItemProperty -path $regKey | select-object -ExpandProperty ProxyOverride -ErrorAction stop | Out-Null
          } catch {
            write-error 1
          }
          | SCRIPT
      }
    }
  }
  else {
    exec { 'Turn off proxy settings if they exist':
      provider  => powershell,
      command   => @(SCRIPT),
        $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        Remove-ItemProperty -path $regKey -name ProxyServer
        Set-ItemProperty -path $regKey -name ProxyEnable -value 0
        Remove-ItemProperty -path $regKey -name ProxyOverride
        | SCRIPT
      onlyif    => @(SCRIPT),
        $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        try {
          Get-ItemProperty -path $regKey | select-object -ExpandProperty ProxyServer -ErrorAction stop | Out-Null
        } catch {
          write-error 1
        }
        | SCRIPT
    }
  }

  if $autoscript {
    exec { 'Turn on specified autoconfig script':
      provider  => powershell,
      require   => Exec['Set Default Connection Settings'],
      command   => @("SCRIPT"/$),
        \$proxyConfigToDefine = "${autoscript_url}"
        \$regKey="HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings"
        Set-ItemProperty -path \$regKey AutoConfigURL -value \$proxyConfigToDefine
        | SCRIPT
      unless    => @("SCRIPT"/$),
        \$proxyConfigToDefine = "${autoscript_url}";
        \$regKey="HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings"
        if((Get-ItemProperty -path \$regKey -name AutoConfigURL).AutoConfigURL -eq \$proxyConfigToDefine) {
          return 0
        } else {
          write-error 1
        }
        | SCRIPT
    }
  }
  else {
    exec { 'Turn off specified autoconfig script':
      provider  => powershell,
      command   => @(SCRIPT),
        $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        Remove-ItemProperty -path $regKey -name AutoConfigURL
        | SCRIPT
      onlyif    => @(SCRIPT),
        $regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        try {
          Get-ItemProperty -path $regKey | select-object -ExpandProperty AutoConfigURL -ErrorAction stop | Out-Null
        } catch {
          write-error 1
        }
        | SCRIPT
    }
  }
}
