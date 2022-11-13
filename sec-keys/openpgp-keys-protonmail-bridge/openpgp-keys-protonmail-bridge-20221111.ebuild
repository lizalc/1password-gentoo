# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OpenPGP key used by Proton Mail Bridge binary releases"
HOMEPAGE="https://proton.me/mail/bridge"
SRC_URI="https://proton.me/download/bridge_pubkey.gpg -> ${PN}.gpg"

LICENSE="public-domain"
SLOT="0"
KEYWORDS="-* amd64 arm64"
RESTRICT="mirror"

S=${WORKDIR}

src_install() {
	local files=(${A})
	insinto /usr/share/openpgp-keys
	newins - "${PN}.gpg" < <(cat "${files[@]/#/${DISTDIR}/}" || die)
}
