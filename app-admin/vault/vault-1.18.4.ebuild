# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# HashiCorp-стек по паттерну app-admin/nomad (локальный overlay): deps в
# vendor-тарболле, OpenRC initd (systemd-юниты апстрима не используются),
# лицензия BUSL-1.1 — см. /etc/portage/package.license
inherit go-module

DESCRIPTION="HashiCorp Vault - tool for managing access to secrets"
HOMEPAGE="https://www.vaultproject.io"
SRC_URI="https://github.com/hashicorp/vault/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${P}-deps.tar.xz"

LICENSE="BUSL-1.1"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

BDEPEND=">=dev-lang/go-1.23.0"

src_compile() {
	# основной пакет в корне репозитория; встроенный UI собирается отдельно
	# (ember) и в бинарник не вшивается — веб-интерфейс vault доступен и так
	ego build -trimpath -o bin/vault . || die
}

src_install() {
	dobin bin/vault
	keepdir /etc/vault.d /var/lib/vault
	newinitd "${FILESDIR}/vault.initd" vault
	newconfd "${FILESDIR}/vault.confd" vault
	einstalldocs
}
