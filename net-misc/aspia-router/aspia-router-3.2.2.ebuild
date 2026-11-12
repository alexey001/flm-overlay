# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

# ВАЖНО: патч привязан к v3.2.2 (CMake-структура апстрима меняется между
# версиями). При bump PV проверять применимость и состав зависимостей заново:
# патч добавляет ASPIA_SERVER_ONLY — сборка только router/relay с системными
# библиотеками вместо vcpkg (QtCore+QtNetwork, openssl, protobuf-lite, sqlite,
# curl, asio; enet/vpx/opus/webm/yuv/jpeg/zstd/miniupnpc/QtGui не нужны).
DESCRIPTION="Aspia Router - assigns identifiers to peers and routes traffic to bypass NAT"
HOMEPAGE="https://aspia.org/"
SRC_URI="https://github.com/dchapyshev/aspia/archive/refs/tags/v${PV}.tar.gz -> aspia-${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
# lto: LTO-сборка демона (бинарник заметно меньше — relay -42%, router -26%;
# выигрыш в рантайме для I/O-bound демонов в пределах шума, линковка дольше)
IUSE="lto"
RESTRICT="test"

# server-only: демоны используют QtCore/QtNetwork/QtDBus и системные библиотеки
# напрямую (asio и cmake — только сборка; icu нужна коду sql-коллации в base/sql,
# dbus — вызовам QDBusConnection в sys_info_linux.cc, попадающим в бинарь через
# peer-аутентификаторы)
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
	# ASPIA_SERVER_ONLY: без client/host/common/codec/desktop, тесты выключены
	# (BUILD_TESTING=OFF) — GTest не требуется.
	local mycmakeargs=(
		-DASPIA_SERVER_ONLY=ON
		-DBUILD_TESTING=OFF
		-DCMAKE_SKIP_RPATH=ON
		-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=$(usex lto ON OFF)
	)
	cmake_src_configure
}

src_compile() {
	# собираем только целевой демон (с его зависимостями: base, proto, qtprotoc)
	cmake_src_compile aspia_router
}

src_install() {
	dobin "${BUILD_DIR}"/aspia_router

	# /etc/aspia: router.conf, host.pub, relay.pub (общий каталог с aspia-relay);
	# владелец числовой 340:340 (acct-user/aspia): NSS хоста сборки пользователя
	# из ROOT не видит
	keepdir /etc/aspia
	fowners 340:340 /etc/aspia
	fperms 0750 /etc/aspia

	# /var/lib/aspia: база router.db3; дефолтный файловый лог демона —
	# /var/log/aspia/router (logging_file.cc, платформенно-независимый путь)
	keepdir /var/lib/aspia /var/log/aspia/router
	fowners 340:340 /var/lib/aspia /var/log/aspia /var/log/aspia/router
	fperms 0750 /var/lib/aspia /var/log/aspia /var/log/aspia/router

	newinitd "${FILESDIR}"/aspia-router.initd aspia-router
	newconfd "${FILESDIR}"/aspia-router.confd aspia-router

	einstalldocs
}

pkg_config() {
	if [[ -f ${EROOT}/etc/aspia/router.conf ]]; then
		einfo "Конфигурация уже существует: ${EROOT}/etc/aspia/router.conf"
		return 0
	fi
	/usr/bin/aspia_router --create-config || die "aspia_router --create-config failed"
	# файлы созданы от root с правами 0600 — отдаем их сервисному пользователю
	chown 340:340 "${EROOT}"/etc/aspia/router.conf "${EROOT}"/etc/aspia/*.pub \
		"${EROOT}"/var/lib/aspia/router.db3 2>/dev/null
	einfo "Готово. Пароль пользователя admin выведен выше."
}

pkg_postinst() {
	elog "Создание начальной конфигурации (админ-пользователь + ключи):"
	elog "  emerge --config net-misc/aspia-router"
	elog "  # или вручную: aspia_router --create-config && chown aspia:aspia /etc/aspia/router.conf*"
	elog
	elog "Конфиг: /etc/aspia/router.conf (перечитывается при старте демона)."
	elog "База пользователей: /var/lib/aspia/router.db3."
	elog
	elog "OpenRC: rc-update add aspia-router default && rc-service aspia-router start"
	elog "Порты: 8061 (host), 8062 (client), 8063 (relay), 8065 (stun) — см. router.conf."
	elog
	elog "В контейнере демон запускается напрямую в foreground (/usr/bin/aspia_router)."
}
