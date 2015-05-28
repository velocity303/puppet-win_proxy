# win_proxy

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with win_proxy](#setup)
    * [What win_proxy affects](#what-win_proxy-affects)
    * [Beginning with win_proxy](#beginning-with-win_proxy)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Example](#example)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module allows the user to modify the settings of their proxies used on Windows machines as set in the Internet Settings snap-in within the Control Panel. This module was directly tested against Windows Server 2012 R2 but should work against most Windows versions.

## Module Description

This module allows you to set the following settings within the snap in.
 - Automatically Detect Settings
 - Use Automatic Configuration Script
   - Address
 - Use a proxy server for your LAN (These settings will not apply to dial-up or VPN connections)
   - Address
   - Port
   - Bypass proxy server for local address

At this time this module does not allow for more advanced configurations past these settings.

## Setup

### What win_proxy affects

This module will affect the registry settings behind these entries within the HKCU registry area.

### Setup Requirements

This module requires the puppetlabs-stdlib and puppetlabs-powershell modules.

### Beginning with win_proxy

This module by default will enable "Automatically Detect Settings" within the snap-in. If you need additional customization please see the usage details below. 

## Usage

Parameters:

#####`$autodetect`
This accepts a boolean for whether "Automatically Detect Settings" should be enabled or disabled (Default: true)

#####`$staticproxy`
This accepts a boolean for whether "Use a proxy server for your LAN" should be enabled or disabled (Default: false)

#####`$proxyserver`
This accepts a string containing the static proxy server you would like to use. It will only take affect if $staticproxy is true It should be formatted as 'hostname:port'. (Default: '127.0.0.1:80')

#####`$localoverride`
This accepts a boolean for whether "Bypass proxy server for local addresses" should be enabled or disabled. This only takes affect if $staticproxy is true. (Default: false)

#####`$autoscript`
This accepts a boolean as to whether "Use automatic configuration script" should be enabled or disabled. (Default: false)

#####`$autoscript_url`
This accepts a string containing the address you would like to use if utilizing "Use automatic configuration script". This will only take affect if $autoscript is set to true. (Default: 'http://test.example.com/file.pac')

## Example
```puppet
class {'win_proxy':
  autodetect     => true,
  staticproxy    => true,
  proxyserver    => '127.0.0.1:80',
  localoverride  => false,
  autoscript     => false,
  autoscript_url => 'http://myproxyscript.lan/script.pac',
}
```
## Limitations

Currently tested only against Windows Server 2012 R2.

## Development

All contributions are welcome. Feel free to fork and contribute or file an issue.

## Release Notes
Currently on the initial release
