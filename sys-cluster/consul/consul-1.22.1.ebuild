# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# HashiCorp-стек по паттерну sys-cluster/nomad (локальный overlay): deps в
# vendor-тарболле, OpenRC initd (systemd-юниты апстрима не используются),
# лицензия BUSL-1.1 — см. /etc/portage/package.license
inherit go-module

DESCRIPTION="HashiCorp Consul - service discovery, monitoring and configuration"
HOMEPAGE="https://www.consul.io"
SRC_URI="https://github.com/hashicorp/consul/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${P}-deps.tar.xz"

LICENSE="BUSL-1.1"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

BDEPEND=">=dev-lang/go-1.25.4"

src_compile() {
	# основной пакет в корне репозитория; встроенный UI (ui/) требует node — не собираем
	ego build -trimpath -o bin/consul . || die
}

src_install() {
	dobin bin/consul
	keepdir /etc/consul.d /var/lib/consul
	newinitd "${FILESDIR}/consul.initd" consul
	newconfd "${FILESDIR}/consul.confd" consul
	einstalldocs
}
