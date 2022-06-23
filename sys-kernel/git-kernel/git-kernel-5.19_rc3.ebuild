# Copyright 2020-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit kernel-build toolchain-funcs

MY_PV=${PV/_/-}
MY_INST_PV=${PV/_/.0-}
MY_P=linux-${MY_PV}

DESCRIPTION="Linux kernel built from vanilla upstream sources"
HOMEPAGE="https://www.kernel.org/"
SRC_URI="
	https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/snapshot/${MY_P}.tar.gz
"
S=${WORKDIR}/${MY_P}

LICENSE="GPL-2"
KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~ppc ~ppc64 ~x86"
IUSE="debug hardened"
REQUIRED_USE="savedconfig"
RESTRICT="mirror"

DEPEND="
	>=sys-devel/patch-2.7.6-r4
"
BDEPEND="
	debug? ( dev-util/pahole )
"
PDEPEND="
	>=virtual/dist-kernel-${PV}
"

src_install() {
	PV=${MY_INST_PV} kernel-build_src_install
}

pkg_preinst() {
	PV=${MY_INST_PV} kernel-install_pkg_preinst
}

pkg_postinst() {
	PV=${MY_INST_PV} kernel-build_pkg_postinst
}

pkg_postrm() {
	PV=${MY_INST_PV} kernel-install_pkg_postrm
}

pkg_config() {
	PV=${MY_INST_PV} kernel-install_pkg_config
}
