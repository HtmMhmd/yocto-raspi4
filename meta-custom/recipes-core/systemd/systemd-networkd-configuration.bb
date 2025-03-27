SUMMARY = "Systemd network configuration for Raspberry Pi"
DESCRIPTION = "Basic network configuration for Raspberry Pi using systemd-networkd"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://20-wired.network \
    file://25-wireless.network \
    file://wpa_supplicant-wlan0.conf \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${S}/20-wired.network ${D}${sysconfdir}/systemd/network/
    install -m 0644 ${S}/25-wireless.network ${D}${sysconfdir}/systemd/network/
    
    # Install WPA supplicant configuration
    install -d ${D}${sysconfdir}/wpa_supplicant
    install -m 0644 ${S}/wpa_supplicant-wlan0.conf ${D}${sysconfdir}/wpa_supplicant/
    
    # Create symlink for automatic wpa_supplicant startup
    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf /lib/systemd/system/wpa_supplicant@.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/wpa_supplicant@wlan0.service
}

FILES_${PN} += " \
    ${sysconfdir}/systemd/network/* \
    ${sysconfdir}/wpa_supplicant/* \
    ${sysconfdir}/systemd/system/multi-user.target.wants/* \
"

RDEPENDS_${PN} += "systemd wpa-supplicant"
