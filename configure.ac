AC_INIT(daily-catchup, 0.1)
AC_CONFIG_MACRO_DIR([build/autotools])

m4_pattern_allow([^AS_])

AM_INIT_AUTOMAKE(AC_PACKAGE_NAME, AC_PACKAGE_VERSION)
AM_MAINTAINER_MODE

AC_ISC_POSIX
AC_PROG_CC
AM_PROG_CC_STDC
AC_HEADER_STDC
AM_PROG_CC_C_O

AC_CHECK_PROG(PKG_CONFIG, pkg-config, pkg-config, no)

PKG_CHECK_MODULES(introspection, gobject-introspection-1.0 >= 0.6.3)
PKG_CHECK_MODULES(vala, vala-1.0 >= 0.7.4)
PKG_CHECK_MODULES(gobject, gobject-2.0)
PKG_CHECK_MODULES(clutter, clutter-1.0)
PKG_CHECK_MODULES(model, model)
PKG_CHECK_MODULES(nbtk, nbtk-1.0)
PKG_CHECK_MODULES(pixbuf, gdk-pixbuf-2.0)
PKG_CHECK_MODULES(gdk, gdk-2.0)

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(girdir,
	 `pkg-config --variable=girdir gobject-introspection-1.0`)
AC_SUBST(typelibdir,
	  `pkg-config --variable=typelibdir gobject-introspection-1.0`)
AC_SUBST(pkgconfigdir, ${libdir}/pkgconfig)
AC_SUBST(dctkincludedir, ${includedir}/dctk)
AC_SUBST(vapidir,
	  `pkg-config --variable=vapidir vala-1.0`)

AS_AC_EXPAND(DBUS_SERVICES_DIR, "$datadir/dbus-1/services")
AC_SUBST(DBUS_SERVICES_DIR)

AM_PROG_LIBTOOL

AC_OUTPUT([
Makefile
widget/Makefile
widget/dctk.pc
tools/session.conf
])


