# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="af am ar bg bn ca cs da de el en-GB es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk ur vi zh-CN zh-TW"

inherit chromium-2 desktop pax-utils unpacker verify-sig xdg

# Example URI
# https://downloads.1password.com/linux/debian/amd64/pool/main/1/1password/1password-8.9.12-4.BETA.amd64.deb

MY_P="${P/_beta/-}.BETA"

DESCRIPTION="1Password - Password Manager and Secure Wallet"
HOMEPAGE="https://1password.com"
SRC_URI="
	amd64? (
		https://downloads.1password.com/linux/debian/amd64/pool/main/1/1password/${MY_P}.amd64.deb
		https://downloads.1password.com/linux/tar/beta/x86_64/${MY_P}.x64.tar.gz.sig -> ${MY_P}.sig
	)
"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="bindist mirror splitdebug strip test"
#IUSE="appindicator policykit wayland"
IUSE="appindicator policykit"
CONFIG_PROTECT="/etc/${PN} /usr/share/polkit-1/actions"

DEPEND="acct-group/onepassword"

BDEPEND="
	${DEPEND}
	verify-sig? ( sec-keys/openpgp-keys-1password )
"

VERIFY_SIG_OPENPGP_KEY_PATH=${BROOT}/usr/share/openpgp-keys/1password.com.asc

# NOTE: These dependencies are based on dependencies listed in the Debian package.
RDEPEND="
	${DEPEND}

	appindicator? ( dev-libs/libappindicator )
	policykit? ( sys-auth/polkit )

	app-accessibility/at-spi2-atk:2
	app-accessibility/at-spi2-core:2
	app-crypt/gnupg
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-misc/curl
	virtual/libudev
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libxcb
	x11-libs/libxshmfence
	x11-libs/gtk+:3
	x11-themes/hicolor-icon-theme
"

QA_PREBUILT="*"

ONEPASSWORD_HOME="usr/share/${PN}"
ONEPASSWORD_GROUP="onepassword"
ONEPASSWORD_KEYRING_HELPER="${ONEPASSWORD_HOME}/1Password-KeyringHelper"
ONEPASSWORD_BROWSER_SUPPORT="${ONEPASSWORD_HOME}/1Password-BrowserSupport"

pkg_setup() {
	if use amd64; then
		MY_P="${MY_P}.x64"
	else
		die "${PN} only supports amd64 and arm64"
	fi

	chromium_suid_sandbox_check_kernel_config
}

src_unpack() {
	:
}

src_install() {
	dodir /
	cd "${ED}" || die
	unpacker

	mv opt/1Password "${ONEPASSWORD_HOME}" || die
	sed -i "s|opt/1Password|${ONEPASSWORD_HOME}|g" "usr/share/applications/${PN}.desktop" || die

	rm -r usr/share/doc || die
	# rm ./LICENSE.electron.txt ./LICENSES.chromium.html || die
	# rm ./after-install.sh ./after-remove.sh || die
	# rm ./install_biometrics_policy.sh || die

	# Clean unneeded languages
	pushd "${ONEPASSWORD_HOME}/locales" > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die

	if use policykit; then
		local ACTIONS_HOME="usr/share/polkit-1/actions"
		mkdir -p "${ACTIONS_HOME}" || die
		mv "${ONEPASSWORD_HOME}/com.${PN}.1Password.policy.tpl" "${ACTIONS_HOME}/com.${PN}.1Password.policy" || die

		# NOTE: is there a better way to do this?
		# Fill in policy kit file with a list of (the first 10) human users of the system.
		local policy_owners="$(cut -d: -f1,3 /etc/passwd | grep -E ':[0-9]{4}$' | cut -d: -f1 | head -n 10 | sed 's/^/unix-user:/' | tr '\n' ' ')"
		sed -i "s/\${POLICY_OWNERS}/${policy_owners}/g" "${ACTIONS_HOME}/com.${PN}.1Password.policy" || die
	fi

	mkdir -p "etc/${PN}" || die
	cp "${ONEPASSWORD_HOME}/resources/custom_allowed_browsers" "etc/${PN}/" || die

	# if use wayland; then
	# 	cp ./resources/${PN}.desktop ./resources/${PN}-wayland.desktop || die
	# 	sed -i 's/Name=.*/\0 Wayland/g' ./resources/${PN}-wayland.desktop || die
	# 	sed -i 's/Exec=.*/\0 --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto/g' ./resources/${PN}-wayland.desktop || die
	# 	domenu ./resources/${PN}-wayland.desktop || die
	# 	rm ./resources/${PN}-wayland.desktop || die
	# fi

	pax-mark m "${ONEPASSWORD_HOME}/${PN}"

	chgrp "${ONEPASSWORD_GROUP}" "${ONEPASSWORD_KEYRING_HELPER}"
	chgrp "${ONEPASSWORD_GROUP}" "${ONEPASSWORD_BROWSER_SUPPORT}"

	dosym "../../${ONEPASSWORD_HOME}/${PN}" "/usr/bin/${PN}"
}

pkg_postinst() {
	xdg_pkg_postinst

	# NOTE: Possible to do this in src_install without permissions being modified by portage?
	chmod 4755 "${EROOT}/${ONEPASSWORD_HOME}/chrome-sandbox"
	# The binary requires setuid so it may interact with the Kernel keyring facilities
	chmod 6755 "${EROOT}/${ONEPASSWORD_KEYRING_HELPER}"
	# For hardening against tampering
	chmod 2755 "${EROOT}/${ONEPASSWORD_BROWSER_SUPPORT}"

	elog "Browser integration can be controlled via /etc/${PN}/custom_allowed_browsers."
	elog "A commented example file has been installed."
	elog

	if ! use policykit; then
		ewarn 'Installed with USE="-policykit"!'
		ewarn 'System / biometric authentication may not be available.'
		ewarn 'Reinstall with USE="+policykit" to install policykit authentication profile.'
	else
		elog "${PN} policykit file installed to /usr/share/polkit-1/actions/."
		elog "This file is configured with the first ten human users of the system."
		elog "If additional users are needed this file will need to be modified."
	fi
}
