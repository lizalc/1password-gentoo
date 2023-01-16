# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="af am ar bg bn ca cs da de el en-GB es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk ur vi zh-CN zh-TW"

inherit chromium-2 desktop optfeature pax-utils unpacker xdg

MY_URL_ID="7ef08adcc620ba1e4fcda7530c8bc907264acae9"

MY_PVR="${PV##*.*.*.}"
MY_PV="${PV%.*}-${MY_PVR}"
MY_P="${PN}_${MY_PV}"

DESCRIPTION="Multiplatform Visual Studio Code from Microsoft - Insiders Edition"
HOMEPAGE="https://code.visualstudio.com"
SRC_URI="
	amd64? ( https://az764295.vo.msecnd.net/insider/${MY_URL_ID}/${MY_P}_amd64.deb )
"
S="${WORKDIR}"

SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="wayland"
RESTRICT="mirror bindist"

LICENSE="
	Apache-2.0
	BSD
	BSD-1
	BSD-2
	BSD-4
	CC-BY-4.0
	ISC
	LGPL-2.1+
	Microsoft-vscode
	MIT
	MPL-2.0
	openssl
	PYTHON
	TextMate-bundle
	Unlicense
	UoI-NCSA
	W3C
"

RDEPEND="
	|| (
		>=app-accessibility/at-spi2-core-2.46.0:2
		( app-accessibility/at-spi2-atk dev-libs/atk )
	)
	app-crypt/libsecret[crypt]
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	sys-apps/util-linux
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libxkbfile
	x11-libs/libXrandr
	x11-libs/libxshmfence
	x11-libs/pango
"

QA_PREBUILT="*"

pkg_setup() {
	chromium_suid_sandbox_check_kernel_config
}

src_unpack() {
	:
}

src_install() {
	dodir /
	cd "${ED}" || die
	unpacker

	# Appdata location is deprecated. This fixes QA warning.
	mv usr/share/appdata usr/share/metainfo || die

	if use wayland; then
		cp usr/share/applications/code-insiders.desktop usr/share/applications/code-insiders-wayland.desktop || die
		cp usr/share/applications/code-insiders-url-handler.desktop usr/share/applications/code-insiders-url-handler-wayland.desktop || die

		sed -i 's/Name=.*/\0 Wayland/g' usr/share/applications/code-insiders-wayland.desktop || die
		sed -i 's/Name=.*/\0 Wayland/g' usr/share/applications/code-insiders-url-handler-wayland.desktop || die

		sed -i 's/Exec=.*/\0 --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto/g' usr/share/applications/code-insiders-wayland.desktop || die
		sed -i 's/Exec=.*/\0 --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto/g' usr/share/applications/code-insiders-url-handler-wayland.desktop || die
	fi

	local CODE_INSIDERS_HOME="usr/share/${PN}"

	# Clean unneeded languages
	pushd "${CODE_INSIDERS_HOME}/locales" > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die

	pax-mark m "${CODE_INSIDERS_HOME}/bin/${PN}"
	pax-mark m "${CODE_INSIDERS_HOME}/bin/code-tunnel-insiders"

	dosym "../../${CODE_INSIDERS_HOME}/bin/${PN}" "/usr/bin/${PN}"
	dosym "../../${CODE_INSIDERS_HOME}/bin/code-tunnel-insiders" /usr/bin/code-tunnel-insiders
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "You may want to install some additional utils, check in:"
	elog "https://code.visualstudio.com/Docs/setup#_additional-tools"
	optfeature "keyring support inside ${PN}" "gnome-base/gnome-keyring"
}
