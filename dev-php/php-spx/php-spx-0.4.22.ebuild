# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PHP_EXT_NAME="spx"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"
USE_PHP="php8-3 php8-4 php8-5"

inherit php-ext-source-r3

DESCRIPTION="SPX - a simple & fast profiler for PHP (wall time, CPU, memory, I/O)"
HOMEPAGE="https://github.com/NoiseByNorthwest/php-spx"
SRC_URI="https://github.com/NoiseByNorthwest/php-spx/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="sys-libs/zlib"
RDEPEND="${DEPEND}"

DOCS=( README.md CHANGELOG.md THIRD-PARTY-LICENSES.md )
# Явный путь ассетов: дефолт config.m4 ($prefix/share/misc/php-spx/assets) при phpize
# на Gentoo даёт per-slot /usr/lib64/php8.X/share/misc/... (3 копии одного и того же).
# Без --enable-spx: phpize включает опции расширений по умолчанию, а регистрирует их
# в регистре как в config.m4 (--enable-SPX), поэтому наш флаг даёт лишь WARNING.
PHP_EXT_ECONF_ARGS=( --with-spx-assets-dir=/usr/share/misc/php-spx/assets )

# php-ext-source-r3_src_install ставит только modules/spx.so и no-op install-headers;
# веб-UI (assets/web-ui) при этом теряется. Ставим руками строго туда, куда указывает
# --with-spx-assets-dir (он же вшит в .so как SPX_HTTP_UI_ASSETS_DIR).
src_install() {
	php-ext-source-r3_src_install
	insinto /usr/share/misc/php-spx/assets
	doins -r assets/web-ui
}

pkg_postinst() {
	elog "SPX по умолчанию инертен (spx.enabled=0): профилирование включается"
	elog "явно, например для CLI:"
	elog "  SPX_ENABLED=1 php script.php   # flat profile в STDERR"
	elog "Веб-UI (dev-окружение): spx.http_enabled=1, spx.http_key=\"dev\","
	elog "spx.http_ip_whitelist=\"127.0.0.1\", затем откройте"
	elog "http://<host>/?SPX_KEY=dev&SPX_UI_URI=/"
}
