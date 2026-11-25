# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Let's Encrypt/ACME client (lego) and library written in Go"
HOMEPAGE="https://github.com/go-acme/lego"
SRC_URI="https://github.com/go-acme/lego/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	${P}-deps.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

BDEPEND=">=dev-lang/go-1.26"

src_compile() {
	# CGO_ENABLED=0: lego чисто на Go, статический бинарник без libc-зависимостей;
	# build tags как у апстрима в goreleaser - отключают шаблоны/валидацию в
	# рантайме, бинарник заметно меньше; версия инжектится как в официальных сборках
	CGO_ENABLED=0 ego build -trimpath \
		-tags "urfave_cli_no_template,ozzo_validation_no_template,grpcnotrace,validator_novalidatefn" \
		-ldflags "-s -w -X main.version=${PV}" \
		-o bin/lego . || die
}

src_install() {
	dobin bin/lego
	einstalldocs
}
