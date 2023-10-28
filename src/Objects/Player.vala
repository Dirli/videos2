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
    public class Objects.Player : GLib.Object {
        public signal void playbin_state_changed (Gst.State playbin_state, string e, string d);
        public signal void duration_changed (int64 d);
        public signal void progress_changed (int64 p);
        public signal void uri_changed (string u);
        public signal void audio_changed (int index);
        public signal void ended_stream ();

        private bool terminate = false;
        private bool _waiting = false;

        private uint progress_timer = 0;
        private int err_count = 0;

        private int64 duration_cache = -1;

        private Gst.Format fmt = Gst.Format.TIME;
        private dynamic Gst.Element playbin;
        private Gst.Bus bus;

        public Gtk.Widget video_area;

        public unowned int64 duration {
            get {
                int64 d = 0;
                return playbin.query_duration (fmt, out d) ? d : -1;
            }
        }

        public int playback_index {
            get;
            private set;
            default = 2;
        }

        public unowned int64 position {
            private set {
                if (value >= 0) {
                    playbin.seek_simple (fmt, Gst.SeekFlags.FLUSH, value);

                    if (playback_index != 2) {
                        set_playback_rate (-1);
                    }
                }
            }
            get {
                int64 p = 0;
                return playbin.query_position (fmt, out p) ? p : 0;
            }
        }

        private double _volume;
        public double volume {
            get {
                return _volume;
            }
            set {
                _volume = value < 0.0 ? 0.0 :
                          value > 1.0 ? 1.0 :
                          value;

                if (get_playbin_state () == Gst.State.PLAYING || get_playbin_state () == Gst.State.PAUSED) {
                    playbin.set_property ("volume", _volume);
                }
            }
        }

        public Player () {
            playbin = Gst.ElementFactory.make ("playbin", "bin");
            playbin.notify["uri"].connect (() => {
                uri_changed (playbin.uri);
            });
            playbin.set_property ("subtitle-font-desc", "Sans 16");

            var videosink = Gst.ElementFactory.make ("glsinkbin", "glsinkbin");
            var gtkglsink = Gst.ElementFactory.make ("gtkglsink", "gtkglsink");

            if (gtkglsink != null && videosink != null) {
                debug ("Successfully created GTK GL Sink");
                videosink.set ("sink", gtkglsink, null);

                /* The gtkglsink creates the gtk widget for us. This is accessible through a property.
                 * So we get it and use it later to add it to our gui. */
                gtkglsink.get ("widget", out video_area);
            } else {
                debug ("Could not create gtkglsink, falling back to gtksink.\n");
                videosink = Gst.ElementFactory.make ("gtksink", "gtksink");
                videosink.get ("widget", out video_area);
            }

            video_area.draw.connect (on_draw_video);
            playbin["video-sink"] = videosink;

            bus = playbin.get_bus ();
            bus.add_watch (0, bus_callback);
            bus.enable_sync_message_emission ();

            unowned Gst.Registry registry = Gst.Registry.@get ();
            var vaapi_plugin = registry.find_plugin ("vaapi");
            if (vaapi_plugin != null && !vaapi_plugin.is_loaded ()) {
                debug ("Vaapi plugin loaded");
                vaapi_plugin.load ();
            }
        }

        private bool on_draw_video (Cairo.Context ctx) {
            if (get_playbin_state () < Gst.State.PAUSED) {
                Gtk.Allocation allocation;
                video_area.get_allocation (out allocation);

                ctx.set_source_rgb (0, 0, 0);
                ctx.rectangle (0, 0, allocation.width, allocation.height);
                ctx.fill ();
            }

            return false;
        }

        public void set_uri (string uri) {
            err_count = 0;

            duration_cache = -1;
            playbin_state_change (Gst.State.READY, false);
            playbin.uri = uri;

            if (uri != "") {
                playbin_state_change (Gst.State.PAUSED, false);
                playbin.set_property ("volume", volume);

                if (!uri.has_prefix ("dvd:///")) {
                    int counter = 0;
                    GLib.Timeout.add (500, () => {
                        if (++counter > 10) {
                            return false;
                        }

                        int64 d = duration;
                        if (d > -1) {
                            if (d != duration_cache) {
                                duration_changed (d);
                                duration_cache = d;
                            }
                            audio_changed (playbin.current_audio);
                            return false;
                        }

                        return true;
                    });
                }
            }
        }

        public void set_playback_rate (int new_index) {
            int64 p = 0;
            terminate = false;

            // I don't really like the loop solution, but it always occurs in the examples
            do {
                if (!playbin.query_position (fmt, out p)) {
                    if (new_index >= 0) {
                        return;
                    }
                } else {
                    break;
                }
            } while (!terminate);

            if (new_index >= 0 && new_index < Constants.speeds_array.length) {
                playback_index = new_index;
            }

            var ev = new Gst.Event.seek (
                Constants.speeds_array[playback_index],
                fmt,
                Gst.SeekFlags.FLUSH | Gst.SeekFlags.ACCURATE,
                Gst.SeekType.SET,
                p,
                Gst.SeekType.END,
                0);

            playbin.send_event (ev);
        }

        public void set_active_audio (int index) {
            if (index >= (int) playbin.n_audio) {
                return;
            }

            if ((int) playbin.current_audio != index) {
                playbin.set_property ("current-audio", index);
            }
        }

        public void set_active_subtitle (int index) {
            if (index >= (int) playbin.n_text) {
                return;
            }

            int flags;
            playbin.get ("flags", out flags);
            flags &= ~(1 << 2);

            playbin.set_property ("current-text", index);

            if (index >= 0) {
                flags |= (1 << 2);
            }

            playbin.set ("flags", flags);
        }

        public bool toggle_mute () {
            playbin.mute = !((bool) playbin.mute);
            return playbin.mute;
        }

        public void play () {
            playbin_state_change (Gst.State.PLAYING, true);
        }

        public void pause () {
            playbin_state_change (Gst.State.PAUSED, true);
        }

        public void toggle_playing () {
            var state = get_playbin_state ();
            if (state == Gst.State.PLAYING) {
                pause ();
            } else if (state == Gst.State.PAUSED || state == Gst.State.READY) {
                play ();
            }
        }

        public void stop (bool force = false) {
            playbin_state_change (force ? Gst.State.NULL : Gst.State.READY, !force);
        }

        public void seek_jump_value (int64 val) {
            if (val > duration) {
                return;
            }

            err_count = 0;

            stop_timer ();
            position = val;
            start_timer ();
        }

        public void seek_jump_seconds (int seconds) {
            var cur_state = get_playbin_state ();

            if (_waiting || (cur_state != Gst.State.PLAYING && cur_state != Gst.State.PAUSED)) {
                return;
            }

            err_count = 0;

            if (cur_state != Gst.State.PAUSED) {
                playbin.set_state (Gst.State.PAUSED);
            }

            _waiting = true;

            int64 new_position = position + Utils.sec_to_nano ((int64) seconds);
            position = new_position < 0 ? 0 :
                       duration_cache < new_position ? duration_cache - 1 :
                       new_position;

            playbin.set_state (cur_state);
        }

        private void playbin_state_change (Gst.State state, bool emit, string err = "", string d = "") {
            playbin.set_state (state);

            if (state == Gst.State.PLAYING) {
                start_timer ();
            } else {
                stop_timer ();
            }

            if (emit) {
                playbin_state_changed (state, err, d);
            }
        }

        public unowned Gst.State get_playbin_state () {
            Gst.State state = Gst.State.NULL;
            Gst.State pending;
            playbin.get_state (out state, out pending, (Gst.ClockTime) (Gst.SECOND));
            return state;
        }

        private void start_timer () {
            stop_timer ();

            progress_timer = GLib.Timeout.add (500, () => {
                if (position > 0) {
                    progress_changed (position);
                }
                return true;
            });
        }

        private void stop_timer () {
            if (progress_timer > 0) {
                GLib.Source.remove (progress_timer);
                progress_timer = 0;
            }
        }

        private bool bus_callback (Gst.Bus bus, Gst.Message message) {
            switch (message.type) {
                case Gst.MessageType.ERROR:
                    GLib.Error err;
                    string debug;
                    message.parse_error (out err, out debug);
                    warning ("Error: %s\n%s\n", err.message, debug);
                    warning ("Error code: %d", err.code);

                    // Error: Decoding error
                    // this is an abstract number. I still don't understand what
                    // to do with this error, whether it is possible to restart
                    // playback without a counter
                    if (err.code == 7 && err_count++ < 50) {
                        playbin.set_state (Gst.State.PLAYING);
                        return true;
                    }

                    terminate = true;

                    playbin_state_change (Gst.State.NULL, true, @"$(err.message) ($(err.code))", debug);

                    break;
                case Gst.MessageType.EOS:
                    terminate = true;
                    playbin_state_change (Gst.State.NULL, false);
                    ended_stream ();
                    break;
                case Gst.MessageType.DURATION_CHANGED:
                    // works correctly with DVDs, but not with regular videos
                    var d = duration;
                    if (d > 0 && d != duration_cache) {
                        duration_changed (d);
                        duration_cache = d;
                    }

                    break;
                case Gst.MessageType.STATE_CHANGED:
                    Gst.State old_state;
                    Gst.State new_state;
                    message.parse_state_changed (out old_state, out new_state, null);

                    if (_waiting && old_state == Gst.State.PAUSED && new_state == Gst.State.PLAYING) {
                        if (position > 0) {
                            progress_changed (position);
                        }

                        _waiting = false;
                    }

                    break;
                default:
                    break;
            }

            return true;
        }
    }
}
