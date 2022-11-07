# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit gnome2-utils meson vala xdg

DESCRIPTION="A beautiful GTK 4 terminal."
HOMEPAGE="https://gitlab.gnome.org/raggesilver/blackbox"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.gnome.org/raggesilver/${PN}.git"
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
	>=gui-libs/gtk-4.6:4
	>=gui-libs/libadwaita-1.1:1
	>=gui-libs/marble-42
	>=gui-libs/vte-0.69.0:2.91-gtk4
	>=dev-libs/json-glib-1.4.4
	>=dev-libs/libpcre2-8
	>=dev-libs/libxml2-2.9.12:2
	>=gnome-base/librsvg-2.54.0:2
	>=media-libs/graphene-1.0
"
RDEPEND="${DEPEND}"
BDEPEND="
	$(vala_depend)
	virtual/pkgconfig
"

src_prepare() {
	default
	vala_setup
	xdg_environment_reset
}

src_configure() {
	meson_src_configure
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
