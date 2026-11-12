# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Nomad task driver plugin for Podman containers"
HOMEPAGE="https://github.com/hashicorp/nomad-driver-podman"
SRC_URI="https://github.com/hashicorp/nomad-driver-podman/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${P}-deps.tar.xz"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

BDEPEND=">=dev-lang/go-1.25.8"

RDEPEND="sys-cluster/nomad"

src_compile() {
	ego build -trimpath -o nomad-driver-podman . || die
}

src_install() {
	exeinto /opt/nomad/plugins
	doexe nomad-driver-podman
	einstalldocs
}
