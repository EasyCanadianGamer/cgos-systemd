# Maintainer: canadiangamerOS <https://gitlab.com/canadiangamerOS/>
# Based on the Arch Linux systemd PKGBUILD
# Fork: cgos-systemd — systemd without birthDate/age-verification fields

pkgbase=cgos-systemd
pkgname=(
  cgos-systemd
  cgos-systemd-libs
  cgos-systemd-resolvconf
  cgos-systemd-sysvcompat
)
pkgver=261
pkgrel=1
pkgdesc="System and Service Manager (CGOS fork — no birthDate field)"
arch=(x86_64)
url="https://gitlab.com/canadiangamerOS/"
license=(
  GPL-2.0-or-later
  LGPL-2.1-or-later
)
depends=(
  acl
  audit
  bash
  cryptsetup
  curl
  dbus
  elfutils
  glib2
  gnutls
  iproute2
  kbd
  kmod
  libcap
  libgcrypt
  libidn2
  libp11-kit
  libseccomp
  libxkbcommon
  lz4
  openssl
  pam
  libarchive
  tpm2-tss
  util-linux-libs
  xz
  zlib
  zstd
)
makedepends=(
  git
  gperf
  meson
  python-jinja
  python-pyelftools
)
source=("cgos-systemd::git+https://gitlab.com/canadiangamerOS/cgos-systemd.git")
sha256sums=('SKIP')

build() {
  local meson_options=(
    -Dbpf-framework=disabled
    -Dtests=false
    -Ddefault-dnssec=no
    -Dfirstboot=false
    -Dinstall-tests=false
    -Dldconfig=false
    -Dman=disabled
    -Dsysusers=false
    -Drpmmacrosdir=no
    -Db_lto=true
    -Db_pie=true
  )

  # artix-meson is a wrapper around meson setup used on Artix/Arch
  if command -v artix-meson &>/dev/null; then
    artix-meson "$pkgbase" build "${meson_options[@]}"
  else
    meson setup "$pkgbase" build --prefix=/usr "${meson_options[@]}"
  fi
  meson compile -C build
}

check() {
  meson test -C build --print-errorlogs -q
}

package_cgos-systemd-libs() {
  pkgdesc="cgos-systemd client libraries"
  depends=(
    gcc-libs
    libcap
    libgcrypt
    lz4
    xz
    zstd
  )
  provides=(
    libsystemd
    libsystemd.so
    libudev.so
    systemd-libs="${pkgver}"
  )
  conflicts=(systemd-libs libsystemd)

  meson install -C build --destdir "$pkgdir" \
    --tags libudev,libsystemd,devel
}

package_cgos-systemd() {
  pkgdesc="$pkgdesc"
  depends=(
    "${pkgname%-libs}-libs=${pkgver}"
    acl audit bash cryptsetup curl dbus elfutils glib2 gnutls
    iproute2 kbd kmod libcap libgcrypt libidn2 libp11-kit libseccomp
    libxkbcommon lz4 openssl pam libarchive tpm2-tss util-linux-libs
    xz zlib zstd
  )
  provides=(
    nss-myhostname
    systemd="${pkgver}"
    udev
  )
  conflicts=(systemd udev)
  replaces=(udev)
  backup=(
    etc/pam.d/systemd-user
    etc/systemd/coredump.conf
    etc/systemd/homed.conf
    etc/systemd/journald.conf
    etc/systemd/logind.conf
    etc/systemd/networkd.conf
    etc/systemd/resolved.conf
    etc/systemd/sleep.conf
    etc/systemd/system.conf
    etc/systemd/timesyncd.conf
    etc/systemd/user.conf
    etc/udev/rules.d/99-default.rules
    etc/udev/udev.conf
  )

  meson install -C build --destdir "$pkgdir"

  # remove libs handled by cgos-systemd-libs
  rm -r \
    "$pkgdir"/usr/lib/libsystemd* \
    "$pkgdir"/usr/lib/libudev* \
    "$pkgdir"/usr/include

  install -Dm644 "$pkgbase/LICENSE.GPL2" -t "$pkgdir/usr/share/licenses/$pkgname/"
  install -Dm644 "$pkgbase/LICENSE.LGPL2.1" -t "$pkgdir/usr/share/licenses/$pkgname/"
}

package_cgos-systemd-resolvconf() {
  pkgdesc="cgos-systemd resolvconf replacement (passthrough to resolved)"
  depends=("cgos-systemd=${pkgver}")
  provides=(resolvconf)
  conflicts=(resolvconf)

  install -d "$pkgdir/usr/bin"
  ln -s /usr/bin/resolvectl "$pkgdir/usr/bin/resolvconf"

  install -d "$pkgdir/usr/share/licenses/$pkgname"
  ln -s /usr/share/licenses/cgos-systemd "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

package_cgos-systemd-sysvcompat() {
  pkgdesc="cgos-systemd SysV compatibility scripts"
  depends=("cgos-systemd=${pkgver}")
  conflicts=(sysvinit)

  install -d "$pkgdir/usr/bin"
  for tool in halt poweroff reboot runlevel shutdown telinit; do
    ln -s /usr/bin/systemctl "$pkgdir/usr/bin/$tool"
  done

  install -d "$pkgdir/usr/share/licenses/$pkgname"
  ln -s /usr/share/licenses/cgos-systemd "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
