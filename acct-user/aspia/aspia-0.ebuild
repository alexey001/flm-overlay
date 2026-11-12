# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for Aspia Router and Relay daemons (непривилегированный запуск)"

# Фиксированный uid: acct-* при установке в ROOT (rootfs контейнера) резолвится
# только численно — fowners в ebuild'ах и run-скрипты используют 340:340.
ACCT_USER_ID=340
ACCT_USER_GROUPS=( aspia )
ACCT_USER_SHELL=/sbin/nologin

acct-user_add_deps
