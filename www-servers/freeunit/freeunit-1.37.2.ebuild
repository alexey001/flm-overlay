# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Community LTS fork of NGINX Unit application server, with PHP modules"
HOMEPAGE="https://freeunit.support/
	https://docs.freeunit.org/
	https://github.com/freeunitorg/freeunit"
SRC_URI="https://github.com/freeunitorg/freeunit/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

S="${WORKDIR}/freeunit-${PV}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="debug ssl"

IUSE="${IUSE}
	php_targets_php8-2
	php_targets_php8-3
	php_targets_php8-4
	php_targets_php8-5"

# libpcre2 обязателен: маршрутизация Unit построена на регулярных выражениях
DEPEND="
	dev-libs/libpcre2:=
	ssl? ( dev-libs/openssl:= )
	php_targets_php8-2? ( dev-lang/php:8.2[embed] )
	php_targets_php8-3? ( dev-lang/php:8.3[embed] )
	php_targets_php8-4? ( dev-lang/php:8.4[embed] )
	php_targets_php8-5? ( dev-lang/php:8.5[embed] )
"
# Бинарник unitd и пути совпадают с nginx-unit — drop-in замена,
# одновременная установка невозможна
RDEPEND="${DEPEND}
	acct-user/nginx-unit
	acct-group/nginx-unit
	!www-servers/nginx-unit
"
BDEPEND="virtual/pkgconfig"
RESTRICT="test"

PHP_SLOTS=( 8.2 8.3 8.4 8.5 )

src_configure() {
	# Пути unitd компилируются внутрь бинарника (unitd -h их показывает)
	local myconf=(
		--prefix="${EPREFIX}"/usr
		--sbindir="${EPREFIX}"/usr/sbin
		--libdir="${EPREFIX}"/usr/$(get_libdir)
		--modulesdir="${EPREFIX}"/usr/$(get_libdir)/unit/modules
		--mandir="${EPREFIX}"/usr/share/man
		--statedir="${EPREFIX}"/var/lib/nginx-unit
		--logdir="${EPREFIX}"/var/log/nginx-unit
		--log="${EPREFIX}"/var/log/nginx-unit/error.log
		--runstatedir="${EPREFIX}"/run
		--tmpdir="${EPREFIX}"/var/tmp/nginx-unit
		--control="unix:${EPREFIX}/run/nginx-unit.control.sock"
		--user=nginx-unit
		--group=nginx-unit
		--ld-opt="${LDFLAGS}"
	)
	use ssl && myconf+=( --openssl )
	use debug && myconf+=( --debug )

	# Основной configure обязан идти первым (генерирует Makefile),
	# затем по одному вызову на каждый PHP-слот.
	./configure "${myconf[@]}" || die "core configure failed"

	local slot
	for slot in "${PHP_SLOTS[@]}"; do
		use "php_targets_php${slot/./-}" || continue
		# В Gentoo (проверено на практике): php-config — /usr/lib64/php8.3/bin/php-config,
		# libphp.so — /usr/lib64/php8.3/lib64/libphp.so (php ebuild: into DESTDIR +
		# dolib.so добавляет lib64 к DESTTREE)
		./configure php \
			--module=php${slot/./} \
			--config="${EPREFIX}"/usr/$(get_libdir)/php${slot}/bin/php-config \
			--lib-path="${EPREFIX}"/usr/$(get_libdir)/php${slot}/$(get_libdir) \
			|| die "php module configure failed for slot ${slot}"
	done
}

src_install() {
	# install ставит unitd, man-страницу и все сконфигурированные
	# модули *.unit.so в $(DESTDIR)$NXT_MODULESDIR
	emake DESTDIR="${D}" install

	keepdir /var/lib/nginx-unit /var/log/nginx-unit /var/tmp/nginx-unit
	fowners nginx-unit:nginx-unit /var/lib/nginx-unit /var/log/nginx-unit /var/tmp/nginx-unit

	newinitd "${FILESDIR}"/freeunit.initd freeunit
	newconfd "${FILESDIR}"/freeunit.confd freeunit
}
