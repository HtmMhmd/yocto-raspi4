# meta-custom/recipes-multimedia/libcamera-tools/libcamera-tools_%.bb

SUMMARY = "Libcamera tools"
LICENSE = "GPL-2.0-only"

SRC_URI = = "git://github.com/libcamera/libcamera.git;protocol=https;branch=main \ "


inherit cmake pkgconfig

# Ensure that we depend on libcamera itself
DEPENDS += "libcamera"

# Specify any additional configurations or options needed during compilation.
EXTRA_OEMAKE += ""

do_configure_prepend() {
    # Any pre-configure steps can be added here if needed.
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/tools/* ${D}${bindir}/
}