# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-group

DESCRIPTION="Group for Aspia Router and Relay daemons"

# Фиксированный gid: на него завязаны /etc/aspia и /var/lib/aspia
# (тома контейнера, права в OpenRC-скриптах); fowners в ebuild'ах — числовой.
ACCT_GROUP_ID=340
