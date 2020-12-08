namespace Videos2 {
    public class Objects.Player : GLib.Object {
        public signal void playbin_state_changed (Gst.State playbin_state);
        public signal void duration_changed (int64 d);
        public signal void progress_changed (int64 p);
        public signal void uri_changed (string u);
        public signal void audio_changed (int index);
        public signal void ended_stream ();

        private bool terminate = false;

        private uint progress_timer = 0;
        private int err_count = 0;

        public uint* win_xid;

        private int64 duration_cache = -1;

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

        private int playback_index = 2;

        public unowned int64 position {
            private set {
                if (value >= 0) {
                    playbin.seek_simple (fmt, Gst.SeekFlags.FLUSH, value);

                    if (playback_index != 2) {
                        set_playback_rate (null);
                    }
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

        public Player () {
            playbin = Gst.ElementFactory.make ("playbin", "bin");
            playbin.notify["uri"].connect (() => {
                uri_changed (playbin.uri);
            });
            playbin.set_property ("subtitle-font-desc", "Sans 16");

            bus = playbin.get_bus ();
            bus.add_watch (0, bus_callback);
            bus.enable_sync_message_emission ();
        }

        public void set_win_xid (X.Window w) {
            win_xid = (uint*) w;
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

        public double set_playback_rate (bool? up) {
            int64 p = 0;
            terminate = false;

            // I don't really like the loop solution, but it always occurs in the examples
            do {
                if (!playbin.query_position (fmt, out p)) {
                    if (up != null) {
                        return 0;
                    }
                } else {
                    break;
                }
            } while (!terminate);

            var old_index = playback_index;

            if (up != null) {
                up ? ++playback_index : --playback_index;
            }

            if (playback_index < 0 || playback_index >= Constants.speeds_array.length) {
                playback_index = old_index;
                return 0;
            }

            var playback_speed = Constants.speeds_array[playback_index];

            var ev = new Gst.Event.seek (
                playback_speed,
                fmt,
                Gst.SeekFlags.FLUSH | Gst.SeekFlags.ACCURATE,
                Gst.SeekType.SET,
                p,
                Gst.SeekType.END,
                0);

            playbin.send_event (ev);

            return playback_speed;
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
            if (cur_state != Gst.State.PLAYING && cur_state != Gst.State.PAUSED) {
                return;
            }

            err_count = 0;

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
            if (Gst.Video.is_video_overlay_prepare_window_handle_message (message)) {
                Gst.Video.Overlay overlay = message.src as Gst.Video.Overlay;
                if (overlay != null) {
                    overlay.set_window_handle (win_xid);
                }
            }

            switch (message.type) {
                case Gst.MessageType.ERROR:
                    GLib.Error err;
                    string debug;
                    message.parse_error (out err, out debug);
                    warning ("Error: %s\n%s\n", err.message, debug);
                    // warning ("Error code: %d", err.code);

                    // Error: Decoding error
                    // this is an abstract number. I still don't understand what
                    // to do with this error, whether it is possible to restart
                    // playback without a counter
                    if (err.code == 7 && err_count++ < 50) {
                        playbin.set_state (Gst.State.PLAYING);
                        return true;
                    }

                    terminate = true;

                    ended_stream ();
                    break;
                case Gst.MessageType.EOS:
                    terminate = true;
                    playbin_state_change (Gst.State.NULL, false);
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
