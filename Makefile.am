NULL = 

SUBDIRS = widget

catchupdir=$(pkgdatadir)
catchup_DATA = \
	src/default.css \
	src/sample-picview.js \
	src/sample-tweetview.js \
	src/main.js \
	src/test-script.json \
	$(NULL)

bin_SCRIPTS = \
	src/daily-catchup \
	tools/run.sh \
	tools/setup-my-tracker.py \
	$(NULL)

dbusconfdir=$(datadir)/dbus-1/services
dbusconf_DATA = tools/session.conf

EXTRA_DIST = \
	$(catchup_DATA) \
	$(bin_SCRIPTS) \
	tools/build/daily-catchup.modules \
	tools/build/jhbuildrc \
	$(NULL)

vapi_DATA = \
	vapi/nbtk-1.0.vapi \
	vapi/nbtk-1.0.deps

vapidir="`$(PKG_CONFIG) --variable=vapidir vala-1.0`"
