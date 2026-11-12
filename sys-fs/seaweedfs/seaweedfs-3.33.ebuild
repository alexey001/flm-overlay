# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="SeaweedFS - distributed storage system for blobs, objects and files"
HOMEPAGE="https://github.com/seaweedfs/seaweedfs"
SRC_URI="https://github.com/seaweedfs/seaweedfs/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${P}-deps.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

BDEPEND=">=dev-lang/go-1.19"

src_compile() {
	# -buildmode=exe вместо дефолтного для eclass pie: получается ET_EXEC
	# без PT_INTERP, полностью статический - годится для контейнеров FROM scratch
	CGO_ENABLED=0 go build -trimpath -buildmode=exe -o bin/weed ./weed || die
}

src_install() {
	dobin bin/weed
	einstalldocs
}
