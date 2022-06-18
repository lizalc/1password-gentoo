# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="OpenPGP keys used by 1Password"
HOMEPAGE="https://1password.com/"
SRC_URI="https://downloads.1password.com/linux/keys/1password.asc"

LICENSE="public-domain"
SLOT="0"
KEYWORDS="-* amd64 arm64"
RESTRICT="mirror"

S=${WORKDIR}

src_install() {
	local files=( ${A} )
	insinto /usr/share/openpgp-keys
	newins - 1password.com.asc < <(cat "${files[@]/#/${DISTDIR}/}" || die)
}
