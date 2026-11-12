# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

# ВАЖНО: патч общий с aspia-router и привязан к v3.2.2 (см. комментарий в
# net-misc/aspia-router). Добавляет ASPIA_SERVER_ONLY — сборка только
# router/relay с системными библиотеками вместо vcpkg.
DESCRIPTION="Aspia Relay - proxies user traffic to bypass NAT"
HOMEPAGE="https://aspia.org/"
SRC_URI="https://github.com/dchapyshev/aspia/archive/refs/tags/v${PV}.tar.gz -> aspia-${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
# lto: LTO-сборка демона (бинарник заметно меньше — relay -42%, router -26%;
# выигрыш в рантайме для I/O-bound демонов в пределах шума, линковка дольше)
IUSE="lto"
RESTRICT="test"

RDEPEND="
	acct-group/aspia
	acct-user/aspia
	dev-db/sqlite:3
	dev-libs/icu:=
	dev-libs/openssl:=
	dev-libs/protobuf:=
	dev-qt/qtbase:6[dbus,network]
	net-misc/curl
	sys-apps/dbus
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-build/cmake-3.30
	dev-cpp/asio
	virtual/pkgconfig
"

PATCHES=( "${FILESDIR}/aspia-3.2.2-gentoo-system-libs.patch" )

S="${WORKDIR}/aspia-${PV}"

src_configure() {
	local mycmakeargs=(
		-DASPIA_SERVER_ONLY=ON
		-DBUILD_TESTING=OFF
		-DCMAKE_SKIP_RPATH=ON
		-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=$(usex lto ON OFF)
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile aspia_relay
}

src_install() {
	dobin "${BUILD_DIR}"/aspia_relay

	# /etc/aspia: relay.conf; каталог общий с aspia-router, владелец числовой
	# 340:340 (acct-user/aspia). Файловые логи демона — /var/log/aspia/relay.
	keepdir /etc/aspia /var/log/aspia/relay
	fowners 340:340 /etc/aspia /var/log/aspia /var/log/aspia/relay
	fperms 0750 /etc/aspia /var/log/aspia /var/log/aspia/relay

	newinitd "${FILESDIR}"/aspia-relay.initd aspia-relay
	newconfd "${FILESDIR}"/aspia-relay.confd aspia-relay

	einstalldocs
}

pkg_config() {
	if [[ -f ${EROOT}/etc/aspia/relay.conf ]]; then
		einfo "Конфигурация уже существует: ${EROOT}/etc/aspia/relay.conf"
		return 0
	fi
	/usr/bin/aspia_relay --create-config || die "aspia_relay --create-config failed"
	chown 340:340 "${EROOT}"/etc/aspia/relay.conf
	einfo "Готово: ${EROOT}/etc/aspia/relay.conf"
}

pkg_postinst() {
	elog "Создание начальной конфигурации:"
	elog "  emerge --config net-misc/aspia-relay"
	elog
	elog "Конфиг: /etc/aspia/relay.conf — укажите адрес router'а (порт 8063)."
	elog "Логи релея пишутся в /etc/aspia/logs (или stdout при ASPIA_LOG_TO_STDOUT=1)."
	elog
	elog "OpenRC: rc-update add aspia-relay default && rc-service aspia-relay start"
	elog "Порты: 8070 (peer, входящий), 8063 -> router (исходящий)."
	elog
	elog "В контейнере демон запускается напрямую в foreground (/usr/bin/aspia_relay)."
}
