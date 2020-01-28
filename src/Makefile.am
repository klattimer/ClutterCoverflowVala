lib_LTLIBRARIES = libdctk.la

libdctk_la_CFLAGS = $(gobject_CFLAGS) $(model_CFLAGS) $(nbtk_CFLAGS) $(pixbuf_CFLAGS) $(gdk_CFLAGS)
libdctk_la_SOURCES = $(libdctk_la_VALASOURCES:.vala=.c)
libdctk_la_LIBADD = $(gobject_LIBS) $(model_LIBS) $(nbtk_LIBS) $(pixbuf_LIBS) $(gdk_LIBS)
libdctk_la_VALASOURCES = button.vala tweetview.vala picview.vala scrollkinetic.vala window.vala ualbum.vala

BUILT_SOURCES = libdctk.la.vala.stamp
VALAC_TEST_FLAGS = --pkg gio-2.0 --pkg model --pkg nbtk-1.0 --pkg gdk-2.0 --pkg gdk-pixbuf-2.0 --vapidir=. --vapidir=${top_srcdir}/vapi 

Dctk-0.1.gir dctk.vapi libdctk.la.vala.stamp: $(libdctk_la_VALASOURCES)
	$(VALAC) -H dctk.h -C --library dctk --gir Dctk-0.1.gir --pkg model --pkg nbtk-1.0 --pkg gdk-pixbuf-2.0 --pkg gdk-2.0 --vapidir=${top_srcdir}/vapi $^
	touch libdctk.la.vala.stamp

test-picview: test-picview.vala picview.vala
	$(VALAC) $(VALAC_TEST_FLAGS) test-picview.vala picview.vala

test-tweetview: test-tweetview.vala tweetview.vala
	$(VALAC) $(VALAC_TEST_FLAGS) test-tweetview.vala tweetview.vala

test-kinetic: test-kinetic.vala scrollkinetic.vala
	$(VALAC) $(VALAC_TEST_FLAGS) test-kinetic.vala scrollkinetic.vala

test-window: test-window.vala window.vala
	$(VALAC) $(VALAC_TEST_FLAGS) test-window.vala window.vala

test-ualbum: test-ualbum.vala ualbum.vala
	$(VALAC) $(VALAC_TEST_FLAGS) test-ualbum.vala ualbum.vala



noinst_PROGRAMS = test-tweetview test-picview test-kinetic test-window
TESTS = $(noinst_PROGRAMS)

CLEANFILES = *.stamp *.c *.h *.vapi *.gir *.typelib *.tmp

%.typelib: %.gir
	g-ir-compiler --shared-library=libdctk $^ > $@.tmp
	mv $@.tmp $@

dctkinclude_HEADERS = dctk.h
gir_DATA = Dctk-0.1.gir
typelib_DATA = Dctk-0.1.typelib
pkgconfig_DATA = dctk.pc
vapi_DATA = dctk.vapi

tags: ctags
