# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson

DESCRIPTION="Reliable, scalable PostgreSQL backup and restore (pgBackRest)"
HOMEPAGE="https://pgbackrest.org/"
# теги апстрима имеют форму release/<pv>
SRC_URI="https://github.com/pgbackrest/pgbackrest/archive/refs/tags/release/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+libssh2 +systemd +zstd"
# тесты требуют живого postgres и perl-окружения апстрима
RESTRICT="test"

# libpq идёт из dev-db/postgresql; для контейнера (kubler pg/postgres-backrest)
# он нужен только в builder'е на этапе компиляции — unprovide_package в build.sh,
# в рантайме libpq.so.5 берётся из родительского слоя pg/postgres
RDEPEND="
	dev-db/postgresql
	dev-libs/libxml2
	dev-libs/openssl:=
	sys-libs/zlib
	app-arch/lz4
	zstd? ( app-arch/zstd )
	libssh2? ( net-libs/libssh2 )
"

S="${WORKDIR}/pgbackrest-release-${PV}"

src_configure() {
	# В kubler-сборках compile-deps (libpq, openssl, lz4, zstd, libxml2)
	# устанавливаются в builder-контейнер хуком configure_builder() образа
	# (emerge без ROOT) — pkg-config находит их в дефолтных каталогах.
	local emesonargs=(
		-Dconfigdir=/etc/pgbackrest
		-Dfatal-errors=false
		-Dlibsystemd=$(usex systemd enabled disabled)
		-Dlibssh2=$(usex libssh2 enabled disabled)
		-Dlibzstd=$(usex zstd enabled disabled)
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	keepdir /etc/pgbackrest
	einstalldocs
}

pkg_postinst() {
	elog "Конфиг: /etc/pgbackrest/pgbackrest.conf (stanza + repo1-*)."
	elog "В контейнере pg/postgres-backrest конфиг и s6-сервис уже настроены:"
	elog "archive_command и ежедневный backup в 02:00, repo на томе /var/lib/pgbackrest."
}
