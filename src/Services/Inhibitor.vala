/*
 * Copyright (c) 2021 Dirli <litandrej85@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace Videos2 {
    public class Services.Inhibitor : GLib.Object {
        private ScreenSaverIface? screensaver_iface = null;

        private bool _allow_block = true;
        public bool allow_block {
            get {
                return _allow_block;
            }
            set {
                _allow_block = value;
                if (playback_state >= Gst.State.PAUSED) {
                    if (value) {
                        inhibit ();
                    } else {
                        uninhibit ();
                    }
                }
            }
        }

        private Gst.State _playback_state = Gst.State.NULL;
        public Gst.State playback_state {
            get {
                return _playback_state;
            }
            set {
                _playback_state = value;
                if (value < Gst.State.PAUSED) {
                    uninhibit ();
                } else {
                    inhibit ();
                }
            }
        }

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

        private void inhibit () {
            if (!allow_block) {
                return;
            }

            if (_playback_state == Gst.State.PAUSED) {
                if (screensaver_iface != null && inhibit_cookie > 0) {
                    try {
                        screensaver_iface.un_inhibit (inhibit_cookie);
                        inhibit_cookie = 0;
                    } catch (Error e) {
                        warning ("Could not uninhibit screen: %s", e.message);
                    }
                }
            } else {
                if (screensaver_iface != null && inhibit_cookie == 0) {
                    try {
                        inhibit_cookie = screensaver_iface.inhibit (Constants.APP_NAME, "Playing movie");
                    } catch (Error e) {
                        warning ("Could not inhibit screen: %s", e.message);
                    }
                }
            }

            if (app_inhibit_cookie == 0) {
                app_inhibit_cookie = window.application.inhibit (window,
                                                                 Gtk.ApplicationInhibitFlags.SUSPEND,
                                                                 "Playing movie");
            }
        }

        private void uninhibit () {
            if (screensaver_iface != null && inhibit_cookie > 0) {
                try {
                    screensaver_iface.un_inhibit (inhibit_cookie);
                    inhibit_cookie = 0;
                } catch (Error e) {
                    warning ("Could not uninhibit screen: %s", e.message);
                }
            }

            // if (_playback_state >= Gst.State.PAUSED) {
            //     return;
            // }

            if (app_inhibit_cookie > 0) {
                window.application.uninhibit (app_inhibit_cookie);
                app_inhibit_cookie = 0;
            }
        }
    }
}
