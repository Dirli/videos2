namespace Videos2 {
    public class Services.Inhibitor : GLib.Object {
        private ScreenSaverIface? screensaver_iface = null;

        private uint32 app_inhibit_cookie = 0;
        private uint32 inhibit_cookie = 0;
        private Gtk.Window window;

        public Inhibitor (Gtk.Window window) {
            this.window = window;

            try {
                screensaver_iface = Bus.get_proxy_sync (BusType.SESSION, Constants.SCREENSAVER_IFACE, Constants.SCREENSAVER_PATH, DBusProxyFlags.NONE);
            } catch (Error e) {
                warning ("Could not start screensaver interface: %s", e.message);
            }
        }

        public void inhibit () {
            if (screensaver_iface != null && inhibit_cookie == 0) {
                try {
                    inhibit_cookie = screensaver_iface.inhibit (Constants.APP_NAME, "Playing movie");
                } catch (Error e) {
                    warning ("Could not inhibit screen: %s", e.message);
                }
            }

            if (app_inhibit_cookie == 0) {
                app_inhibit_cookie = window.application.inhibit (window,
                                                                 Gtk.ApplicationInhibitFlags.SUSPEND,
                                                                 "Playing movie");
            }
        }

        public void uninhibit () {
            if (screensaver_iface != null && inhibit_cookie > 0) {
                try {
                    screensaver_iface.un_inhibit (inhibit_cookie);
                    inhibit_cookie = 0;
                } catch (Error e) {
                    warning ("Could not uninhibit screen: %s", e.message);
                }
            }

            if (app_inhibit_cookie > 0) {
                window.application.uninhibit (app_inhibit_cookie);
                app_inhibit_cookie = 0;
            }
        }
    }
}
