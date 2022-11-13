# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop rpm systemd verify-sig xdg-utils

MY_PN="${PN/-bin/}"
MY_P="${MY_PN}-${PV}"

# https://github.com/ProtonMail/proton-bridge/releases/download/v2.4.5/protonmail-bridge-2.4.5-1.x86_64.rpm
DESCRIPTION="The Bridge is an application that runs on your computer in the background and seamlessly encrypts and decrypts your mail as it enters and leaves your computer."
HOMEPAGE="https://proton.me/mail/bridge https://github.com/ProtonMail/proton-bridge/"
SRC_URI="
	https://github.com/ProtonMail/proton-bridge/releases/download/v${PV}/${MY_P}-1.x86_64.rpm
	https://github.com/ProtonMail/proton-bridge/releases/download/v${PV}/${MY_P}-1.x86_64.rpm.sig
"

LICENSE="Apache-2.0 BSD BSD-2 GPL-3+ ISC LGPL-3+ MIT MPL-2.0 Unlicense"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="gnome-keyring pass verify-sig"
RESTRICT="bindist mirror splitdebug strip test"

QA_PREBUILT="*"

BDEPEND="verify-sig? ( sec-keys/openpgp-keys-protonmail-bridge )"
RDEPEND="
	app-crypt/libsecret
	dev-libs/glib
	media-libs/libglvnd
	sys-libs/glibc
	gnome-keyring? ( gnome-base/gnome-keyring )
	pass? ( app-admin/pass )
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

VERIFY_SIG_OPENPGP_KEY_PATH="${BROOT}/usr/share/openpgp-keys/openpgp-keys-protonmail-bridge.gpg"

src_unpack() {
	default
	rpm_src_unpack
}

src_prepare() {
	default
	xdg_environment_reset
}

src_install() {
	insinto /usr/lib
	doins -r usr/lib/protonmail

	dosym "../../lib/protonmail/bridge/proton-bridge" "/usr/bin/${MY_PN}"

	domenu usr/share/applications/*.desktop
	doicon "usr/share/icons/hicolor/scalable/apps/${MY_PN}.svg"

	systemd_douserunit "${FILESDIR}/${PN}.service"

	fperms +x /usr/lib/protonmail/bridge/{bridge,bridge-gui,proton-bridge}
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
