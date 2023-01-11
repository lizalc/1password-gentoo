# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="af am ar bg bn ca cs da de el en-GB es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk ur vi zh-CN zh-TW"

inherit chromium-2 desktop pax-utils verify-sig xdg

if [ "$ARCH" = amd64 ]; then
	MY_ARCH="x64"
elif [ "$ARCH" = arm64 ]; then
	MY_ARCH="arm64"
fi

# Need X.Y.Z-A.BETA.arch where A is the beta number.
MY_P="${PN}-$(ver_cut 1-3 "${PV}")-$(ver_cut 5 "${PV}").BETA"

DESCRIPTION="1Password - Password Manager and Secure Wallet"
HOMEPAGE="https://1password.com"
SRC_URI="
	amd64? (
		https://downloads.1password.com/linux/tar/beta/x86_64/${MY_P}.x64.tar.gz
		https://downloads.1password.com/linux/tar/beta/x86_64/${MY_P}.x64.tar.gz.sig
	)
	arm64? (
		https://downloads.1password.com/linux/tar/beta/aarch64/${MY_P}.arm64.tar.gz
		https://downloads.1password.com/linux/tar/beta/aarch64/${MY_P}.arm64.tar.gz.sig
	)
"
S="${WORKDIR}/${MY_P}.${MY_ARCH}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
RESTRICT="bindist mirror splitdebug test"
IUSE="appindicator homed policykit +suid wayland"
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

src_prepare() {
	default

	rm ./LICENSE.electron.txt ./LICENSES.chromium.html || die
	rm ./after-install.sh ./after-remove.sh || die
	rm ./install_biometrics_policy.sh || die

	# Clean unneeded languages
	pushd locales > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die

	sed -i "s|opt/1Password|usr/share/${PN}|g" "resources/${PN}.desktop" || die

	if use wayland; then
		cp ./resources/${PN}.desktop ./resources/${PN}-wayland.desktop || die
		sed -i 's/Name=.*/\0 Wayland/g' ./resources/${PN}-wayland.desktop || die
		sed -i 's/Exec=.*/\0 --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto/g' ./resources/${PN}-wayland.desktop || die
	fi

	if use policykit; then
		use homed && ewarn "systemd-homed users will not be automatically added to polkit policy"

		# NOTE: is there a better way to do this?
		# Fill in policy kit file with a list of (the first 10) human users of the system.
		local policy_owners="$(cut -d: -f1,3 /etc/passwd | grep -E ':[0-9]{4}$' | cut -d: -f1 | head -n 10 | sed 's/^/unix-user:/' | tr '\n' ' ')"
		sed -i "s/\${POLICY_OWNERS}/${policy_owners}/g" "com.${PN}.1Password.policy.tpl" || die
	fi
}

src_install() {
	insinto "/etc/${PN}"
	newins resources/custom_allowed_browsers custom_allowed_browsers.example
	rm resources/custom_allowed_browsers || die

	domenu resources/${PN}.desktop
	rm resources/${PN}.desktop || die

	if use wayland; then
		domenu resources/${PN}-wayland.desktop || die
		rm resources/${PN}-wayland.desktop || die
	fi

	if use policykit; then
		insinto "/usr/share/polkit-1/actions"
		newins "com.${PN}.1Password.policy.tpl" "com.${PN}.1Password.policy"
	fi
	rm "com.${PN}.1Password.policy.tpl"

	local size
	for size in 32 64 256 512; do
		doicon -s ${size} ./resources/icons/hicolor/${size}x${size}/apps/${PN}.png
	done
	unset size
	rm -r ./resources/icons || die

	pax-mark m "${PN}"

	insinto "/usr/share/${PN}"
	doins -r *

	fperms +x "/usr/share/${PN}/${PN}"
	dosym "../../usr/share/${PN}/${PN}" "usr/bin/${PN}"

	fperms +x "/usr/share/${PN}/1Password-HIDHelper"
	fperms +x "/usr/share/${PN}/chrome_crashpad_handler"
	fperms +x "/usr/share/${PN}/op-ssh-sign"

	use suid && fperms 4755 "/usr/share/${PN}/chrome-sandbox"

	fowners "0:onepassword" "/usr/share/${PN}/1Password-KeyringHelper"
	# The binary requires setuid so it may interact with the Kernel keyring facilities
	use suid && fperms 6755 "/usr/share/${PN}/1Password-KeyringHelper"

	fowners "0:onepassword" "/usr/share/${PN}/1Password-BrowserSupport"
	# For hardening against tampering
	use suid && fperms 2755 "/usr/share/${PN}/1Password-BrowserSupport"
}

pkg_postinst() {
	xdg_pkg_postinst

	if use suid; then
		if has sfperms ${FEATURES} && ! has suidctl ${FEATURES}; then
			ewarn "FEATURES=sfperms removes the setuid/setguid read-bit for others from"
			ewarn "  /usr/share/${PN}/chrome-sandbox"
			ewarn "  /usr/share/${PN}/1Password-KeyringHelper"
			ewarn "  /usr/share/${PN}/1Password-BrowserSupport"
			ewarn "This prevents browser integration from working propery."
			ewarn "Please remerge with FEATURES=suidctl set either by package.env"
			ewarn "or globally in make.conf. /etc/portage/suidctl.conf can then be"
			ewarn "edited to prevent the setuid/setguid read-bit stripping when re-merged."
		fi

		elog
		elog "Browser integration can be controlled via /etc/${PN}/custom_allowed_browsers."
		elog "A commented example file has been installed."

		if ! use policykit; then
			ewarn
			ewarn 'Installed with USE="-policykit"!'
			ewarn 'System / biometric authentication may not be available.'
			ewarn 'Reinstall with USE="policykit" to install polkit authentication policy.'
		else
			elog
			elog "${PN} polkit file installed to /usr/share/polkit-1/actions/."
			elog "This file is configured with the first ten human users of the system."
			elog "If additional users are needed this file will need to be modified."

			if has homed ${USE}; then
				ewarn
				ewarn "systemd-homed prevents polkit file from being filled automatically"
				ewarn "with systemd-homed users. 1password CLI connection and SSH agent may"
				ewarn "not work correctly for such users."
			fi
		fi
	else
		ewarn "Installing without USE=suid breaks many 1password features such as browser"
		ewarn "and system integration."
	fi
}
