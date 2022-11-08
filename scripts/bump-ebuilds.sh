#!/usr/bin/env bash

set -euo pipefail

log() {
	printf "%16s: %s\n" "$1" "$2"
}

find_ebuild() {
	find "$ebuilds_path" -type f -name "$1*ebuild" | sort | tail -1
}

check_1password() {
	filename="1password-latest.tar.gz"
	url="https://downloads.1password.com/linux/tar/beta/x86_64/$filename"
	wget "$url"
	version="$(tar --exclude='*/*' -tf "$filename")"
	version="${version%%\.BETA*}"
	version="${version//-/_}"
	version="${version/_/-}"
	version="${version/_/_beta}"

	current="$(find_ebuild "1password")"
	ebuildDir="$(dirname "$current")"
	currentFile="$(basename "$current")"

	log "Latest version" "$version"
	log "Current ebuild" "$currentFile"

	if [[ "$version" > "${currentFile%.*}" ]]; then
		echo "New version available, bumping ebuild"
		newEbuild="$ebuildDir/$version.ebuild"
		cp -v "$current" "$newEbuild"
		ebuild "$newEbuild" manifest
	else
		echo "No new version available"
	fi
}

check_vscode() {
	# Check if new revision is available
	currentURL="$(wget --spider "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64" -o - | grep 'Location:' | cut -d ' ' -f 2)"
	urlPart="$(cut -d '/' -f 5 <<< "$currentURL")"
	revisionPart="$(basename -s ".tar.gz" "$currentURL" | cut -d '-' -f 4)"

	current="$(find_ebuild "code-insiders")"
	ebuildDir="$(dirname "$current")"
	currentFile="$(basename "$current")"
	curRevision="$(cut -d '.' -f 4 <<< "$currentFile")"

	log "Latest URL" "$currentURL"
	log "URL Part" "$urlPart"
	log "Revision" "$revisionPart"
	log "Current ebuild" "$currentFile"

	if ((revisionPart > curRevision)); then
		echo "New version available, bumping ebuild"

		wget "$currentURL" -O vscode-insiders.tar.gz
		tar xf vscode-insiders.tar.gz
		curVersion="$(./VSCode-linux-x64/bin/code-insiders --version | grep '\-insider' | cut -d '-' -f 1)"
		pkgBaseName="code-insiders-${curVersion}.${revisionPart}"

		newEbuild="${ebuildDir}/${pkgBaseName}.ebuild"
		cp -v "$current" "$newEbuild"
		sed -i "s/^MY_URL_ID=.*\$/MY_URL_ID=\"$urlPart\"/g" "$newEbuild"
		ebuild "$newEbuild" manifest

		echo "Ebuild ready"
	else
		echo "No new version, nothing to do"
	fi
}

tmpdir="$(mktemp -d)"
ebuilds_path="$1"

pushd "$tmpdir" || exit

check_1password
check_vscode

popd || exit

rm -rf "$tmpdir"
