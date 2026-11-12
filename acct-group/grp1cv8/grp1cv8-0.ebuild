# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-group

DESCRIPTION="Group for the 1C:Enterprise 8.3 server cluster"

# фиксированный gid: на него завязаны права томов контейнера (nomad-1c)
ACCT_GROUP_ID=999
