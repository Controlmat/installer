#!/usr/bin/env bash
# ============================================================================
#
# FILE:         updateAliaswallet-ubuntu-18-04.sh
#
# SPDX-FileCopyrightText: © 2020 Alias Developers
# SPDX-FileCopyrightText: © 2016 SpectreCoin Developers
# SPDX-License-Identifier: MIT
#
# DESCRIPTION:  Simple installer script to update Aliaswallet binaries
#               on Ubuntu 18 (Bionic)
#
# AUTHOR:       HLXEasy
# PROJECT:      https://alias.cash/
#               https://github.com/aliascash/alias-wallet
#
# ============================================================================

versionToInstall=$1
installPath=/usr/local/bin
tmpWorkdir=/tmp/AliaswalletUpdate
tmpChecksumfile=checksumfile.txt
tmpBinaryArchive=Aliaswallet.tgz
torRepo="deb https://deb.torproject.org/torproject.org bionic main"
boostVersion='1.67.0'

# ----------------------------------------------------------------------------
# Use ca-certificates if available
if [[ -e /etc/ssl/certs/ca-certificates.crt ]] ; then
    cacertParam="--cacert /etc/ssl/certs/ca-certificates.crt"
fi

# ----------------------------------------------------------------------------
# Define version to install
if [[ -z "${versionToInstall}" ]] ; then
    echo "No version to install (tag) given, installing latest release"
    githubTag=$(curl ${cacertParam} -L -s https://api.github.com/repos/aliascash/alias-wallet/releases/latest | grep tag_name | cut -d: -f2 | cut -d '"' -f2)
else
    githubTag=${versionToInstall}
fi
echo ""

# ----------------------------------------------------------------------------
# Determining current operating system (distribution)
echo "Determining system"
if [[ -e /etc/os-release ]] ; then
    . /etc/os-release
else
    echo "File /etc/os-release not found, not updating anything"
    exit 1
fi
echo "    Determined $NAME"
echo ""

# ----------------------------------------------------------------------------
# Define some variables
usedDistro="Ubuntu"
torRepoFile="/etc/apt/sources.list.d/tor.list"
releaseName='-18-04'
case ${ID} in
    "ubuntu")
        case ${VERSION_CODENAME} in
            "bionic"|"cosmic")
                echo "Running on ${ID}/${VERSION_CODENAME}"
                ;;
            *)
                echo "Unable to execute update script for Ubuntu 18.04 (Bionic) on this system:"
                cat /etc/os-release
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Wrong update script for operating system ${ID}!"
        exit 1
        ;;
esac

# ----------------------------------------------------------------------------
# Create work dir and download release notes and binary archive
mkdir -p ${tmpWorkdir}

#https://github.com/aliascash/alias-wallet/releases/latest
#https://github.com/aliascash/alias-wallet/releases/download/4.3.0/Aliaswallet-2.2.1-8706c85-Ubuntu.tgz
#https://github.com/aliascash/alias-wallet/releases/download/Build123/Aliaswallet-Build123-8e152a8-Debian.tgz
downloadBaseURL=https://github.com/aliascash/alias-wallet/releases/download/${githubTag}
releasenotesToDownload=${downloadBaseURL}/RELEASENOTES.txt
echo "Downloading release notes with checksums ${releasenotesToDownload}"
httpCode=$(curl ${cacertParam} -L -o ${tmpWorkdir}/${tmpChecksumfile} -w "%{http_code}" ${releasenotesToDownload})
if [[ ${httpCode} -ge 400 ]] ; then
    echo "${releasenotesToDownload} not found!"
    exit 1
fi
echo "    Done"
echo ""
# Desired line of text looks like this:
# **Aliaswallet-Build139-0c97a29-Debian-Buster.tgz:** `1128be441ff910ef31361dfb04273618b23809ee25a29ec9f67effde060c53bb`
officialChecksum=$(grep "${usedDistro}${releaseName}.tgz:" ${tmpWorkdir}/${tmpChecksumfile} | cut -d '`' -f2)
filenameToDownload=$(grep "${usedDistro}${releaseName}.tgz:" ${tmpWorkdir}/${tmpChecksumfile} | cut -d '*' -f3 | sed "s/://g")

# If nothing found, try again without ${releaseName}
if [[ -z "${officialChecksum}" ]] || [[ -z "${filenameToDownload}" ]] ; then
    # **Aliaswallet-Build139-0c97a29-Debian.tgz:** `1128be441ff910ef31361dfb04273618b23809ee25a29ec9f67effde060c53bb`
    officialChecksum=$(grep "${usedDistro}.tgz:" ${tmpWorkdir}/${tmpChecksumfile} | cut -d '`' -f2)
    filenameToDownload=$(grep "${usedDistro}.tgz:" ${tmpWorkdir}/${tmpChecksumfile} | cut -d '*' -f3 | sed "s/://g")
fi

echo "Downloading binary archive ${downloadBaseURL}/${filenameToDownload}"
httpCode=$(curl ${cacertParam} -L -o ${tmpWorkdir}/${tmpBinaryArchive} -w "%{http_code}" ${downloadBaseURL}/${filenameToDownload})
if [[ ${httpCode} -ge 400 ]] ; then
    echo "Archive ${downloadBaseURL}/${filenameToDownload} not found!"
    exit 1
fi
echo "    Done"
echo ""

# ----------------------------------------------------------------------------
# Get checksum from release notes and verify downloaded archive
echo "Verifying checksum"
determinedSha256Checksum=$(sha256sum ${tmpWorkdir}/${tmpBinaryArchive} | awk '{ print $1 }')
if [[ "${officialChecksum}" != "${determinedSha256Checksum}" ]] ; then
    echo "ERROR: sha256sum of downloaded file not matching value from ${releasenotesToDownload}: (${officialChecksum} != ${determinedSha256Checksum})"
    exit 1
else
    echo "    sha256sum OK"
fi
echo "    Downloaded archive is ok, checksums match values from ${releasenotesToDownload}"
echo ""

# ----------------------------------------------------------------------------
# Backup current binaries
if [[ -e ${installPath}/aliaswalletd ]] ; then
    echo "Determining current binary version"
    # Version is something like "v2.2.2.0 (86e9b92 - 2019-01-26 17:20:20 +0100)"
    # but only the version and the commit hash separated by "_" is used later on.
    # Option '-version' is working since v3.x
    currentVersion=$(${installPath}/aliaswalletd -version | awk '{print $1}')
    gitHash=$(${installPath}/aliaswalletd -version | awk '{print substr($2,2);}')
    if [[ -n "${gitHash}" ]] ; then
        fullVersion=${currentVersion}-${gitHash}
    else
        fullVersion=${currentVersion}
    fi
    if [[ -z "${fullVersion}" ]] ; then
        fullVersion=$(date +%Y%m%d-%H%M)
        echo "    Unable to determine version of current binaries, using timestamp '${fullVersion}'"
    else
        echo "    Creating backup of current version ${fullVersion}"
    fi
    if [[ -f ${installPath}/aliaswalletd-${fullVersion} ]] ; then
        echo "    Backup of current version already existing"
    else
        sudo mv ${installPath}/aliaswalletd ${installPath}/aliaswalletd-${fullVersion}
        if [[ -e ${installPath}/aliaswallet ]] ; then
            sudo mv ${installPath}/aliaswallet  ${installPath}/aliaswallet-${fullVersion}
        fi
        echo "    Done"
    fi
else
    echo "Binary ${installPath}/aliaswalletd not found, skip backup creation"
fi
echo ""

# ----------------------------------------------------------------------------
# Setup Tor
echo "Setup Tor package repo"
sudo apt-get install -y \
    gpg
if [[ -e ${torRepoFile} ]] ; then
    echo "    Tor repo already configured"
else
    echo "${torRepo}" | sudo tee --append ${torRepoFile} > /dev/null
    curl ${cacertParam} https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
    echo "    Done"
fi
echo ""

# ----------------------------------------------------------------------------
# Update/upgrade system
echo "Updating system and installing required packages"
sudo apt-get update -y
sudo apt-get install -y \
    apt-transport-https \
    deb.torproject.org-keyring \
    dirmngr
sudo apt-get upgrade -y
sudo apt-get install -y \
    --no-install-recommends \
    tor
sudo apt-get clean
echo "    Done"
echo ""

# ----------------------------------------------------------------------------
# Handle old binary location /usr/bin/
if [[ -e /usr/bin/aliaswalletd && ! -L /usr/bin/aliaswalletd ]] ; then
    # Binary found on old location and is _not_ a symlink,
    # so move to new location and create symlink
    echo "Found binaries on old location, cleaning them up"
    mv /usr/bin/aliaswalletd ${installPath}/aliaswalletd
    ln -s ${installPath}/aliaswalletd /usr/bin/aliaswalletd
    if [[ -e /usr/bin/aliaswallet && ! -L /usr/bin/aliaswallet ]] ; then
        mv /usr/bin/aliaswallet ${installPath}/aliaswallet
        ln -s ${installPath}/aliaswallet /usr/bin/aliaswallet
    fi
    echo "    Done"
    echo ""
fi

# ----------------------------------------------------------------------------
# Backup wallet.dat
if [[ -e ~/.aliaswallet/wallet.dat ]] ; then
    backupFile=$(date +%Y-%m-%d_%H-%M)-wallet.dat
    echo "Creating backup of wallet.dat (${backupFile})"
    cp ~/.aliaswallet/wallet.dat ~/${backupFile}
    echo "    Done"
fi
if [[ -e ~/.aliaswallet/testnet/wallet.dat ]] ; then
    backupFile=$(date +%Y-%m-%d_%H-%M)-testnet-wallet.dat
    echo "Creating backup of testnet wallet.dat (${backupFile})"
    cp ~/.aliaswallet/testnet/wallet.dat ~/${backupFile}
    echo "    Done"
fi
echo ""

# ----------------------------------------------------------------------------
# Install new binaries
echo "Installing new binaries"
cd ${tmpWorkdir}
tar xzf ${tmpBinaryArchive} .
sudo mv usr/local/bin/aliaswallet* /usr/local/bin/
sudo chmod +x /usr/local/bin/aliaswallet /usr/local/bin/aliaswalletd
echo "    Done"
echo ""

# ----------------------------------------------------------------------------
# Cleanup temporary data
echo "Cleanup"
rm -rf ${tmpWorkdir}
echo "    Done"
echo ""
