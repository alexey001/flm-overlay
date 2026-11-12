# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Kubler - build minimal Docker/Podman images from Gentoo packages"
HOMEPAGE="https://github.com/edannenberg/kubler"
EGIT_REPO_URI="https://github.com/edannenberg/kubler.git"
# релизных тегов нет, фиксируем состояние master (внутренняя версия 0.9.12)
EGIT_COMMIT="ccf0e4801bb968aee26b93e1d5e85e784fc0d2dd"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

RDEPEND="
	app-shells/bash
	app-misc/jq
	dev-vcs/git
	app-containers/podman
"

src_install() {
	# дерево репозитория должно оставаться цельным: bin/kubler
	# резолвит lib/ относительно своего расположения (симлинк поддержан)
	insinto /usr/lib/kubler
	doins -r bin cmd engine lib template kubler.conf kubler.sh COPYING README.md
	fperms 0755 /usr/lib/kubler/bin/kubler /usr/lib/kubler/kubler.sh
	# в git-репозитории скрипты bob-core без exec-бита; без него crun
	# не может запустить их в builder-контейнере (EPERM на chmod)
	fperms 0755 /usr/lib/kubler/engine/docker/bob-core/build-root.sh \
		/usr/lib/kubler/engine/docker/bob-core/sed-or-die.sh \
		/usr/lib/kubler/engine/docker/bob-core/portage-git-sync.sh
	dosym -r /usr/lib/kubler/bin/kubler /usr/bin/kubler
	einstalldocs
}
