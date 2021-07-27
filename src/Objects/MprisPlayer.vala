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
    [DBus (name = "org.mpris.MediaPlayer2.Player")]
    public class Objects.MprisPlayer : GLib.Object {
        public signal void seeked (int64 position);

        private DBusConnection conn;
        private Services.MprisProxy mpris_proxy;

        public bool can_go_next {
            get {return mpris_proxy.can_next;}
        }
        public bool can_go_previous {
            get {return mpris_proxy.can_previous;}
        }
        public bool can_play {
            get {return true;}
        }
        public bool can_pause {
            get {return true;}
        }
        public bool can_seek {
            get {return false;}
        }
        public bool can_control {
            get {return true;}
        }

        private GLib.HashTable<string, GLib.Variant> _metadata;
        public GLib.HashTable<string, GLib.Variant>? metadata { //a{sv}
            owned get {return _metadata;}
        }

        public int64 position {
            get {return 0;}
        }

        public string playback_status {
            owned get {
                return mpris_proxy.playback_status;
                // return "Stopped";
            }
        }

        public double rate {
            get {return 1.0;}
            set {}
        }

        public double volume {
            get {return 1.0;}
            set {}
        }

        public MprisPlayer (DBusConnection connection, Services.MprisProxy p) {
            conn = connection;
            mpris_proxy = p;

            _metadata = new GLib.HashTable<string, GLib.Variant> (str_hash, str_equal);

            mpris_proxy.notify["playback-status"].connect (() => {
                send_properties ("PlaybackStatus", mpris_proxy.playback_status);
            });
            mpris_proxy.notify["can-next"].connect (() => {
                send_properties ("CanGoNext", mpris_proxy.can_next);
            });
            mpris_proxy.notify["can-previous"].connect (() => {
                send_properties ("CanGoPrevious", mpris_proxy.can_previous);
            });
            mpris_proxy.notify["title"].connect (() => {
                _metadata = new HashTable<string, Variant> (null, null);

                _metadata.insert ("xesam:title", mpris_proxy.title);
                string[] artists_array = new string[0];
                artists_array += _("video player");

                _metadata.insert ("xesam:artist", artists_array);

                send_properties ("Metadata", _metadata);
            });
        }

        public void next () throws GLib.Error {
            mpris_proxy.next ();
        }

        public void previous () throws GLib.Error {
            mpris_proxy.prev ();
        }

        public void pause () throws GLib.Error {
            if (mpris_proxy.state == Gst.State.PLAYING) {
                mpris_proxy.pause ();
            }
        }

        public void play_pause () throws GLib.Error {
            mpris_proxy.toggle_playing ();
        }

        public void stop () throws GLib.Error {
            var state = mpris_proxy.state;
            if (state == Gst.State.PLAYING || state == Gst.State.PAUSED) {
                mpris_proxy.stop ();
            }
        }

        public void play () throws GLib.Error {
            var state = mpris_proxy.state;
            if (state == Gst.State.PAUSED || state == Gst.State.READY) {
                mpris_proxy.play ();
            }
        }

        public void seek (int64 offset) throws GLib.Error {
            //
        }

        public void set_position (uint tid, int64 pos) throws GLib.Error {
            //
        }

        public void open_uri (string uri) throws GLib.Error {
            //
        }

        private bool send_properties (string property, Variant val) {
            var property_list = new GLib.HashTable<string, GLib.Variant> (str_hash, str_equal);
            property_list.insert (property, val);

            var builder = new GLib.VariantBuilder (GLib.VariantType.ARRAY);
            var invalidated_builder = new GLib.VariantBuilder (new GLib.VariantType("as"));
            foreach (string name in property_list.get_keys ()) {
                GLib.Variant variant = property_list.lookup (name);
                builder.add ("{sv}", name, variant);
            }

            try {
                conn.emit_signal (null,
                                  "/org/mpris/MediaPlayer2",
                                  "org.freedesktop.DBus.Properties",
                                  "PropertiesChanged",
                                  new Variant ("(sa{sv}as)",
                                               "org.mpris.MediaPlayer2.Player",
                                               builder,
                                               invalidated_builder));

            } catch (Error e) {
                print ("Could not send MPRIS property change: %s\n", e.message);
            }

            return false;
        }
    }
}
