# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson vala

DESCRIPTION="GTK library by Paulo Queiroz"
HOMEPAGE="https://gitlab.gnome.org/raggesilver/marble"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.gnome.org/raggesilver/${PN}.git"
	EGIT_BRANCH="wip/gtk4"
else
	inherit gnome.org
	MY_PV="v${PV}"
	MY_P="${PN}-${MY_PV}"
	SRC_URI="https://gitlab.gnome.org/raggesilver/${PN}/-/archive/${MY_PV}/${MY_P}.tar.bz2"
	KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~riscv ~sparc ~x86"
	S="${WORKDIR}/${MY_P}"
fi

LICENSE="GPL-3"
SLOT="0"

DEPEND="
	>=dev-libs/glib-2.50:2
"
if [[ ${PV} == 9999 ]]; then
	DEPEND+=">=gui-libs/gtk-4.6:4"
else
	DEPEND+=">=gui-libs/gtk-3.24:3"
fi
RDEPEND="${DEPEND}"
BDEPEND="
	$(vala_depend)
"

src_prepare() {
	default
	vala_setup
}

src_configure() {
	meson_src_configure
}
