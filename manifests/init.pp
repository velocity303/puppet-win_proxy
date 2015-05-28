# == Class: win_proxy
#
# Full description of class win_proxy here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'win_proxy':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
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
