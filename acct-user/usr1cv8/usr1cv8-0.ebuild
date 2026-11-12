# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for the 1C:Enterprise 8.3 server cluster (usr1cv8)"

# как useradd в preinst официального deb (system-аккаунт, домашний каталог
# = каталог данных кластера), но с фиксированным uid для томов Nomad
ACCT_USER_ID=999
ACCT_USER_HOME=/home/usr1cv8
ACCT_USER_SHELL=/bin/bash
ACCT_USER_GROUPS=( grp1cv8 )

acct-user_add_deps
