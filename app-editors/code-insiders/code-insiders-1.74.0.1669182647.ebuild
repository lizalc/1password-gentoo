# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop pax-utils xdg

MY_URL_ID="58e7c7b8865e3c3ea77055461ffb5d656a7a46af"
MY_PV="${PV##*.*.*.}"

DESCRIPTION="Multiplatform Visual Studio Code from Microsoft - Insiders Edition"
HOMEPAGE="https://code.visualstudio.com"
SRC_URI="https://az764295.vo.msecnd.net/insider/${MY_URL_ID}/code-insider-x64-${MY_PV}.tar.gz -> ${P}-amd64.tar.gz"
S="${WORKDIR}"

RESTRICT="mirror strip bindist"

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
SLOT="0"
KEYWORDS="-* ~amd64"

RDEPEND="
	app-accessibility/at-spi2-atk:2
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret[crypt]
	dev-libs/atk
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
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

QA_PREBUILT="
	/opt/code-insiders/chrome_crashpad_handler
	/opt/code-insiders/chrome-sandbox
	/opt/code-insiders/code-insiders
	/opt/code-insiders/libEGL.so
	/opt/code-insiders/libffmpeg.so
	/opt/code-insiders/libGLESv2.so
	/opt/code-insiders/libvk_swiftshader.so
	/opt/code-insiders/libvulkan.so*
	/opt/code-insiders/resources/app/extensions/*
	/opt/code-insiders/resources/app/node_modules.asar.unpacked/*
	/opt/code-insiders/swiftshader/libEGL.so
	/opt/code-insiders/swiftshader/libGLESv2.so
"

src_install() {
	if use amd64; then
		cd "${WORKDIR}/VSCode-linux-x64" || die
	else
		die "Only amd64 is supported"
	fi

	# Cleanup
	rm -r ./resources/app/LICENSES.chromium.html ./resources/app/LICENSE.rtf || die

	# Install
	pax-mark m code-insiders
	insinto "/opt/${PN}"
	doins -r *
	fperms +x /opt/${PN}/{,bin/}code-insiders
	fperms +x /opt/${PN}/chrome_crashpad_handler
	fperms 4711 /opt/${PN}/chrome-sandbox
	fperms 755 /opt/${PN}/resources/app/extensions/git/dist/askpass.sh
	fperms 755 /opt/${PN}/resources/app/extensions/git/dist/askpass-empty.sh
	fperms -R +x /opt/${PN}/resources/app/out/vs/base/node
	fperms +x /opt/${PN}/resources/app/node_modules.asar.unpacked/@vscode/ripgrep/bin/rg
	dosym "../../opt/${PN}/bin/code-insiders" "usr/bin/code-insiders"
	domenu "${FILESDIR}/code-insiders.desktop"
	domenu "${FILESDIR}/code-insiders-url-handler.desktop"
	newicon "resources/app/resources/linux/code.png" "code-insiders.png"
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "You may want to install some additional utils, check in:"
	elog "https://code.visualstudio.com/Docs/setup#_additional-tools"
}
