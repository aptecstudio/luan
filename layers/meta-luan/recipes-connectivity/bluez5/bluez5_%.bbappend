# Luán — BlueZ without the dependencies of its Python test scripts (D-061).
# The bluez5-testtools package is never installed, but its run-time dependencies make
# the build compile Python, PyGObject and GObject introspection for the target.
RDEPENDS:${PN}-testtools:luan = ""
