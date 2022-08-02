# Copyright 2020-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit kernel-build toolchain-funcs

GENTOO_CONFIG_VER=g2

DESCRIPTION="The source for the Linux kernel used in Windows Subsystem for Linux 2 (WSL2)"
HOMEPAGE="https://github.com/microsoft/WSL2-Linux-Kernel"
SRC_URI="
	https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/linux-msft-wsl-${PV}.tar.gz
	https://github.com/mgorny/gentoo-kernel-config/archive/${GENTOO_CONFIG_VER}.tar.gz
		-> gentoo-kernel-config-${GENTOO_CONFIG_VER}.tar.gz
"
S=${WORKDIR}/WSL2-Linux-Kernel-linux-msft-wsl-${PV}

LICENSE="GPL-2"
KEYWORDS="~amd64 ~arm64"
RESTRICT="mirror"
IUSE="debug hardened"

BDEPEND="
	debug? ( dev-util/pahole )
	sys-devel/bc
"
PDEPEND="
	=virtual/dist-kernel-${PV}
"

QA_FLAGS_IGNORED="
	usr/src/linux-.*/scripts/gcc-plugins/.*.so
	usr/src/linux-.*/vmlinux
	usr/src/linux-.*/arch/powerpc/kernel/vdso.*/vdso.*.so.dbg
"

src_prepare() {
	default

	# prepare the default config
	case ${ARCH} in
		amd64)
			cp ./Microsoft/config-wsl .config || die
			# echo "CONFIG_X86_X32=n" > "${T}"/disable-x32.config || die
			# merge_configs+=(
			# 	"${T}"/disable-x32.config
			# )
			;;
		arm64)
			cp ./Microsoft/config-wsl-arm64 .config || die
			;;
		*)
			die "Unsupported arch ${ARCH}"
			;;
	esac

	local myversion="-wsl2-gentoo-dist"
	use hardened && myversion+="-hardened"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${T}"/version.config || die
	local dist_conf_path="${WORKDIR}/gentoo-kernel-config-${GENTOO_CONFIG_VER}"

	local merge_configs=(
		"${T}"/version.config
		"${dist_conf_path}"/base.config
	)
	use debug || merge_configs+=(
		"${dist_conf_path}"/no-debug.config
	)
	if use hardened; then
		merge_configs+=( "${dist_conf_path}"/hardened-base.config )

		tc-is-gcc && merge_configs+=( "${dist_conf_path}"/hardened-gcc-plugins.config )

		if [[ -f "${dist_conf_path}/hardened-${ARCH}.config" ]]; then
			merge_configs+=( "${dist_conf_path}/hardened-${ARCH}.config" )
		fi
	fi

	kernel-build_merge_configs "${merge_configs[@]}"
}

pkg_postinst() {
	kernel-build_pkg_postinst

	ewarn
	ewarn "WSL2 will not automatically use this kernel."
	ewarn "You must manually copy the built kernel to the Windows drive"
	ewarn "(outside of WSL2) and inform WSL2 to use the kernel by specifying"
	ewarn "it in the .wslconfig file."
	ewarn
	ewarn "See https://docs.microsoft.com/en-us/windows/wsl/wsl-config#wslconfig"
}
