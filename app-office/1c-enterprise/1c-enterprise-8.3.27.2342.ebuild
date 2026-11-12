# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="1C:Enterprise 8.3 server (common, server, ws, crs) from the official deb64 distribution"
HOMEPAGE="https://releases.1c.ru"
# zip как есть в DISTDIR: deb64_8_3_27_2342.zip
SRC_URI="deb64_$(ver_cut 1)_$(ver_cut 2)_$(ver_cut 3)_$(ver_cut 4).zip"

# версия в именах deb: 8.3.27-2342
MY_DEBPV="$(ver_cut 1-3)-$(ver_cut 4)"
# каталог бинарников: /opt/1cv8/x86_64/${PV}
MY_VER="${PV}"

LICENSE="all-rights-reserved"
SLOT="8.3"
KEYWORDS="~amd64"
IUSE="crs nls +server +ws"
REQUIRED_USE="crs? ( server ws )"

# дистрибутив скачивается вручную с releases.1c.ru (нужна учётка ИТС);
# strip запрещён: фирменные prebuilt-бинарники
RESTRICT="fetch mirror strip"

# debs не декларируют системных зависимостей — 1C бандлит почти всё (core83.so,
# libtcmalloc, icu, openssl, libstdc++). Из системного нужны только:
#   glibc (сама система) и kerberos — exclusively для ibcmd (libgssapi_krb5 и пр.)
RDEPEND="
	acct-group/grp1cv8
	acct-user/usr1cv8
	server? ( app-crypt/mit-krb5 )
"

QA_PREBUILT="opt/1cv8/x86_64/${MY_VER}/*"

S="${WORKDIR}"

pkg_nofetch() {
	einfo "Скачайте дистрибутив «Технологическая платформа 8.3», версия ${MY_DEBPV}, вариант deb64"
	einfo "с https://releases.1c.ru (Требуется учётная запись ИТС) и скопируйте в DISTDIR:"
	einfo "  cp deb64_$(ver_cut 1)_$(ver_cut 2)_$(ver_cut 3)_$(ver_cut 4).zip ${DISTDIR}/"
}

src_unpack() {
	unpack ${A}   # zip кладёт deb-файлы прямо в ${WORKDIR}

	local comps=( common )
	use server && comps+=( server )
	use ws && comps+=( ws )
	use crs && comps+=( crs )
	if use nls; then
		comps+=( common-nls )
		use server && comps+=( server-nls )
		use ws && comps+=( ws-nls )
	fi

	local c deb ardir
	for c in "${comps[@]}"; do
		deb="1c-enterprise-${PV}-${c}_${MY_DEBPV}_amd64.deb"
		[[ -f ${WORKDIR}/${deb} ]] || die "deb не найден: ${deb}"
		ardir="${T}/ar-${c}"
		mkdir -p "${ardir}" "${WORKDIR}/pkg-${c}" || die
		# dpkg недоступен — разбираем deb вручную: ar + tar (control.tar.gz игнорируем)
		( cd "${ardir}" && ar x "${WORKDIR}/${deb}" ) || die "ar x ${deb}"
		if [[ -f ${ardir}/data.tar.xz ]]; then
			tar -xJf "${ardir}/data.tar.xz" -C "${WORKDIR}/pkg-${c}" || die
		elif [[ -f ${ardir}/data.tar.gz ]]; then
			tar -xzf "${ardir}/data.tar.gz" -C "${WORKDIR}/pkg-${c}" || die
		else
			die "data.tar.{xz,gz} не найден в ${deb}"
		fi
	done
}

src_install() {
	# сливаем /opt всех выбранных пакетов (все кладут в /opt/1cv8/x86_64/${MY_VER})
	local d
	for d in "${WORKDIR}"/pkg-*/; do
		if [[ -d ${d}opt ]]; then
			cp -a "${d}"opt "${D}/" || die
		fi
	done

	# общий каталог конфигурации сервера (logcfg.xml, conf.cfg) — как создаёт
	# postinst deb; SystemLanguage=RU — то, что postinst вычислил бы для ru_RU.UTF-8
	keepdir /opt/1cv8/conf
	echo 'SystemLanguage=RU' > "${D}"/opt/1cv8/conf/conf.cfg || die

	# алиас версии: run-скрипты и администрирование используют .../current/...
	dosym "${MY_VER}" /opt/1cv8/x86_64/current

	# служебные каталоги (в контейнере — точки монтирования томов):
	#   /var/1C/licenses — софт-лицензии (создаёт preinst deb, g+rws)
	#   /home/usr1cv8    — домен usr1cv8, данные кластера в ${HOME}/.1cv8
	# владелец — числовой 999:999: uid/gid зафиксированы acct-{user,group}/usr1cv8,
	# а fowners по имени резолвится через NSS хоста сборки, где usr1cv8 отсутствует
	keepdir /var/1C/licenses /home/usr1cv8
	fowners 999:999 /var/1C /var/1C/licenses /home/usr1cv8
	fperms 2775 /var/1C /var/1C/licenses
}

pkg_postinst() {
	elog "Софт-лицензии 1С кладутся в /var/1C/licenses (в контейнере — том)."
	elog "Администрирование: rac <host>:1545 cluster list (ras должен быть запущен)."
	elog "Порты: ragent 1540, rmngr/кластер 1541, ras 1545, rphost 1560-1591."
}
