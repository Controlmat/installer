# Spectrecoin Installer
[![GitHub version](https://badge.fury.io/gh/spectrecoin%2Finstaller.svg)](https://badge.fury.io/gh/spectrecoin%2Finstaller) [![HitCount](http://hits.dwyl.io/spectrecoin/https://github.com/spectrecoin/installer.svg)](http://hits.dwyl.io/spectrecoin/https://github.com/spectrecoin/installer)
[![Build Status](https://ci.spectreproject.io/buildStatus/icon?job=Spectrecoin/installer/master)](https://ci.spectreproject.io/job/Spectrecoin/job/installer/job/master/)

This repository contains various components to create standalone installer packages
or to update an existing Spectrecoin installation.

## Linux
For the supportet Linux distributions there's a simple updater script
located under the folder _linux_. This is the easiest way to update an
existing installation, as long as we cannot provide dedicated packages.

### Requirements
The script is able to update an existing Spectrecoin installation resp.
backup and update the Spectrecoin binaries located on _/usr/local/bin/_.

To do so, the following additional requirements must be installed:
- bash (to execute the updater script itself)
- curl (to download components to install)
- sudo (to replace binaries)

### How to use
At first, spectrecoind must be stopped to replace the binaries.

Execute the updater script afterwards with

```
curl -L -s https://raw.githubusercontent.com/spectrecoin/installer/master/linux/updateSpectrecoin.sh | sudo bash -s
```

This will update the local installation to the latest release.

To update with a dedicated (develop-) version, just add the corresponding
tag to the cmdline. The following example shows the installation of `Build129`:

```
curl -L -s https://raw.githubusercontent.com/spectrecoin/installer/master/linux/updateSpectrecoin.sh | sudo bash -s Build129
```

### What it does
1. Determine current OS by examining `/etc/os-release`
1. Download checksum file
1. Download binary archive
1. Verify md5, sha1, sha256 and sha512 hashes
1. Backup current binaries if no backup of current version exists.
1. Install new binaries
1. Cleanup download folder

### Spectrecoin Shell UI
If you're using the [Spectrecoin Shell UI](https://github.com/spectrecoin/spectrecoin-sh-rpc-ui),
the update script is fully integrated since version 2.5.
Go to _Advanced_ -> _Update_ to use it.

## Windows

Work in progress!

### Requirements
* Install [QT Installer Framework](http://doc.qt.io/qtinstallerframework/index.html)
* Setup env var QTIFWDIR with path to installed QT Installer Framework

### Windows - offline
%QTIFWDIR%\bin\binarycreator.exe --offline-only -c config\config.xml -p packages Spectrecoin-Installer.exe

### Windows - online
%QTIFWDIR%\bin\repogen.exe -p packages -i Spectrecoin,Tor repository
%QTIFWDIR%\bin\binarycreator.exe -n -c config\config.xml -p packages Spectrecoin-Installer.exe