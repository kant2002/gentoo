# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8,9,10} )

inherit cmake python-single-r1

DESCRIPTION="Library for the efficient manipulation of volumetric data"
HOMEPAGE="https://www.openvdb.org"
SRC_URI="https://github.com/AcademySoftwareFoundation/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MPL-2.0"
SLOT="0/8"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~x86"
IUSE="cpu_flags_x86_avx cpu_flags_x86_sse4_2 +blosc doc numpy python static-libs test utils zlib abi6-compat abi7-compat +abi8-compat"
RESTRICT="!test? ( test )"

REQUIRED_USE="
	numpy? ( python )
	^^ ( abi6-compat abi7-compat abi8-compat )
	python? ( ${PYTHON_REQUIRED_USE} )
"
# 8.2.0 should support OpenEXR 3 / imath but it's going to cause issues with Blender AFAIK
# so let's avoid it for now.
RDEPEND="
	dev-cpp/tbb:=
	dev-libs/boost:=
	dev-libs/jemalloc:=
	dev-libs/log4cplus:=
	media-libs/glfw
	media-libs/glu
	media-libs/ilmbase:=
	media-libs/openexr:0=
	sys-libs/zlib:=
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	blosc? ( dev-libs/c-blosc:= )
	python? (
		${PYTHON_DEPS}
		$(python_gen_cond_dep '
			dev-libs/boost:=[numpy?,python?,${PYTHON_USEDEP}]
			numpy? ( dev-python/numpy[${PYTHON_USEDEP}] )
		')
	)
	zlib? ( sys-libs/zlib )
"

DEPEND="${RDEPEND}"

BDEPEND="
	>=dev-util/cmake-3.16.2-r1
	virtual/pkgconfig
	doc? (
		app-doc/doxygen
		dev-texlive/texlive-bibtexextra
		dev-texlive/texlive-fontsextra
		dev-texlive/texlive-fontutils
		dev-texlive/texlive-latex
		dev-texlive/texlive-latexextra
	)
	test? ( dev-util/cppunit dev-cpp/gtest )
"

PATCHES=(
	"${FILESDIR}/${PN}-7.1.0-0001-Fix-multilib-header-source.patch"
	"${FILESDIR}/${PN}-8.0.1-add-consistency-for-NumPy-find_package-call.patch"
	"${FILESDIR}/${PN}-8.1.0-glfw-libdir.patch"
	#"${FILESDIR}/${PN}-9.0.0-unconditionally-search-Python-interpreter.patch"
)

pkg_setup() {
	use python && python-single-r1_pkg_setup
}

src_configure() {
	local myprefix="${EPREFIX}/usr/"

	local version
	if use abi6-compat; then
		version=6
	elif use abi7-compat; then
		version=7
	elif use abi8-compat; then
		version=8
	else
		die "OpenVDB ABI version is not compatible"
	fi

	local mycmakeargs=(
		-DCMAKE_INSTALL_DOCDIR="share/doc/${PF}/"
		-DOPENVDB_ABI_VERSION_NUMBER="${version}"
		-DOPENVDB_BUILD_DOCS=$(usex doc)
		-DOPENVDB_BUILD_UNITTESTS=$(usex test)
		-DOPENVDB_BUILD_VDB_LOD=$(usex utils)
		-DOPENVDB_BUILD_VDB_RENDER=$(usex utils)
		-DOPENVDB_BUILD_VDB_VIEW=$(usex utils)
		-DOPENVDB_CORE_SHARED=ON
		-DOPENVDB_CORE_STATIC=$(usex static-libs)
		-DOPENVDB_ENABLE_RPATH=OFF
		-DUSE_BLOSC=$(usex blosc)
		-DUSE_ZLIB=$(usex zlib)
		-DUSE_CCACHE=OFF
		-DUSE_COLORED_OUTPUT=ON
		# Off for now until 9.0.0 for OpenEXR 3 support
		-DUSE_IMATH_HALF=OFF
		-DUSE_LOG4CPLUS=ON
	)

	if use python; then
		mycmakeargs+=(
			-DOPENVDB_BUILD_PYTHON_MODULE=ON
			-DUSE_NUMPY=$(usex numpy)
			-DOPENVDB_BUILD_PYTHON_UNITTESTS=$(usex test)
			-DPython_EXECUTABLE="${PYTHON}"
			-DPython_INCLUDE_DIR="$(python_get_includedir)"
		)
	fi

	if use cpu_flags_x86_avx; then
		mycmakeargs+=( -DOPENVDB_SIMD=AVX )
	elif use cpu_flags_x86_sse4_2; then
		mycmakeargs+=( -DOPENVDB_SIMD=SSE42 )
	fi

	cmake_src_configure
}
