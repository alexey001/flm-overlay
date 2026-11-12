# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="HashiCorp Nomad - flexible workload orchestrator"
HOMEPAGE="https://www.nomadproject.io"
SRC_URI="https://github.com/hashicorp/nomad/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${P}-deps.tar.xz"

LICENSE="BUSL-1.1"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

BDEPEND=">=dev-lang/go-1.26.7"

src_compile() {
	# основной пакет - в корне репозитория; тег `ui` требует node-сборки встроенного UI
	ego build -trimpath -o bin/nomad . || die
}

src_install() {
	dobin bin/nomad
	keepdir /etc/nomad.d /var/lib/nomad
	newinitd "${FILESDIR}/nomad.initd" nomad
	newconfd "${FILESDIR}/nomad.confd" nomad
	einstalldocs
}
