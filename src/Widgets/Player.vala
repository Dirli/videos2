namespace Videos2 {
    public class Widgets.Player : Gtk.EventBox {
        public signal void playbin_state_changed (Gst.State playbin_state);
        public signal void duration_changed (int64 d);
        public signal void progress_changed (int64 p);
        public signal void toggled_fullscreen ();
        public signal void uri_changed (string u);
        public signal void audio_changed (int index);
        public signal void ended_stream ();

        private uint progress_timer = 0;

        private int64 duration_cache = -1;

        Gtk.Widget video_area;

        public Gst.State playback_state {
            get;
            private set;
            default = Gst.State.NULL;
        }

        private Gst.Format fmt = Gst.Format.TIME;
        private dynamic Gst.Element playbin;
        private Gst.Bus bus;

        public unowned int64 duration {
            get {
                int64 d = 0;
                playbin.query_duration (fmt, out d);
                return d;
            }
        }

        public unowned int64 position {
            private set {
                if (value >= 0) {
                    playbin.seek_simple (fmt, Gst.SeekFlags.FLUSH, value);
                }
            }
            get {
                int64 p = 0;
                playbin.query_position (fmt, out p);
                return p;
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

        public Player () {}

        construct {
            playbin = Gst.ElementFactory.make ("playbin", "bin");
            playbin.notify["uri"].connect (() => {
                uri_changed (playbin.uri);
            });
            playbin.set_property ("subtitle-font-desc", "Sans 16");

            unowned Gst.Registry registry = Gst.Registry.@get ();
            // var gst_plugin = registry.find_plugin ("vaapi");
            if (registry.find_plugin ("vaapi") != null) {
                video_area = new Gtk.DrawingArea ();
                video_area.realize.connect (on_realize);
                video_area.draw.connect (on_draw);
                video_area.events |= Gdk.EventMask.POINTER_MOTION_MASK;

                video_area.motion_notify_event.connect ((event) => {
                    return false;
                });
            } else {
                var gtksink = Gst.ElementFactory.make ("gtksink", null);
                gtksink.get ("widget", out video_area);

                playbin["video-sink"] = gtksink;
            }

            add (video_area);

            bus = playbin.get_bus ();
            bus.add_watch (0, bus_callback);
            bus.enable_sync_message_emission ();

            button_press_event.connect ((event) => {
                if (event.button == Gdk.BUTTON_SECONDARY) {
                    toggle_playing ();
                    return true;
                }

                if (event.button == Gdk.BUTTON_PRIMARY && event.type == Gdk.EventType.2BUTTON_PRESS) {
                    toggled_fullscreen ();
                    return true;
                }

                return base.button_press_event (event);
            });
        }

        private bool on_draw (Cairo.Context ctx) {
            if (playback_state < Gst.State.PAUSED) {
                Gtk.Allocation allocation;
                video_area.get_allocation (out allocation);

                ctx.set_source_rgb (0, 0, 0);
                ctx.rectangle (0, 0, allocation.width, allocation.height);
                ctx.fill ();
            }

            return false;
        }

        public void on_realize () {
            var win = video_area.get_window ();
            if (!win.ensure_native ()) {
                return;
            }

            var win_xid  = (uint*) ((Gdk.X11.Window) win).get_xid ();
            ((Gst.Video.Overlay) playbin).set_window_handle (win_xid);
        }

        public void set_uri (string uri) {
            duration_cache = -1;
            playbin_state_change (Gst.State.NULL, false);
            playbin.uri = uri;

            if (uri != "") {
                play ();
                playbin.set_property ("volume", volume);

                if (!uri.has_prefix ("dvd:///")) {
                    int counter = 0;
                    GLib.Timeout.add (500, () => {
                        if (++counter > 10) {
                            return false;
                        }

                        if (duration > -1) {
                            if (duration != duration_cache) {
                                duration_changed (duration);
                                duration_cache = duration;
                            }
                            audio_changed (playbin.current_audio);
                            return false;
                        }

                        return true;
                    });
                }
            }
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

        public void stop () {
            playbin_state_change (Gst.State.READY, true);
        }

        public void seek_jump_value (int64 val) {
            stop_timer ();
            position = val;
            start_timer ();
        }

        public void seek_jump_seconds (int seconds) {
            var cur_state = get_playbin_state ();
            if (cur_state != Gst.State.PLAYING && cur_state != Gst.State.PAUSED) {
                return;
            }

            var offset = Utils.sec_to_nano ((int64) seconds);

            if (cur_state != Gst.State.PAUSED) {
                playbin.set_state (Gst.State.PAUSED);
            }
            if (duration > position + offset && position + offset > 0) {
                position = position + offset;
            }

            playbin.set_state (cur_state);
        }

        private void playbin_state_change (Gst.State state, bool emit) {
            playbin.set_state (state);

            playback_state = state;

            if (state == Gst.State.PLAYING) {
                start_timer ();
            } else {
                stop_timer ();
            }

            if (state != Gst.State.NULL && emit) {
                playbin_state_changed (state);
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
                    ended_stream ();
                    break;
                case Gst.MessageType.EOS:
                    ended_stream ();
                    break;
                case Gst.MessageType.DURATION_CHANGED:
                    // works correctly with DVDs, but not with regular videos
                    if (duration > 0 && duration != duration_cache) {
                        duration_changed (duration);
                        duration_cache = duration;
                    }

                    break;
                default:
                    break;
            }

            return true;
        }
    }
}
