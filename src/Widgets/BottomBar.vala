namespace Videos2 {
    public class Widgets.BottomBar : Gtk.Revealer {
        public signal void play_toggled ();
        public signal void seeked (double val);

        private uint hiding_timer = 0;

        private Gtk.Button play_button;
        private Granite.SeekBar time_bar;

        private bool _hovered = false;
        private bool hovered {
            get {
                return _hovered;
            }
            set {
                _hovered = value;
                if (value) {
                    if (hiding_timer != 0) {
                        GLib.Source.remove (hiding_timer);
                        hiding_timer = 0;
                    }
                } else {
                    reveal_control ();
                }
            }
        }

        private bool _playing = false;
        public bool playing {
            get {
                return _playing;
            }
            set {
                _playing = value;

                play_button.tooltip_text = value ? _("Pause") : _("Play");
                ((Gtk.Image) play_button.image).icon_name = value ? "media-playback-pause-symbolic" : "media-playback-start-symbolic";

                if (value) {
                    reveal_control ();
                } else {
                    set_reveal_child (true);
                }
            }
        }

        public BottomBar () {
            Object (valign: Gtk.Align.END);

            events |= Gdk.EventMask.POINTER_MOTION_MASK;
            events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
            events |= Gdk.EventMask.ENTER_NOTIFY_MASK;

            transition_type = Gtk.RevealerTransitionType.SLIDE_UP;

            enter_notify_event.connect ((event) => {
                if (event.window == get_window ()) {
                    hovered = true;
                }

                return false;
            });

            leave_notify_event.connect ((event) => {
                if (event.window == get_window ()) {
                    hovered = false;
                }

                return false;
            });

            play_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.BUTTON);
            play_button.tooltip_text = _("Play");
            play_button.clicked.connect (() => {
                play_toggled ();
            });

            time_bar = new Granite.SeekBar (0.0);
            time_bar.scale.vexpand = true;
            time_bar.button_release_event.connect ((event) => {
                seeked (event.x / time_bar.scale.get_range_rect ().width);
                return false;
            });

            var main_actionbar = new Gtk.ActionBar ();

            main_actionbar.pack_start (play_button);
            main_actionbar.set_center_widget (time_bar);

            add (main_actionbar);

            show_all ();
        }

        public void change_duration (double dur, double prog = 0.0) {
            time_bar.playback_duration = dur / Gst.SECOND;
            change_progress (prog);
        }

        public void change_progress (double prog) {
            if (!time_bar.is_grabbing) {
                time_bar.playback_progress = (prog / Gst.SECOND) / time_bar.playback_duration;
            }
        }

        public void reveal_control () {
            if (child_revealed == false) {
                set_reveal_child (true);
            }

            if (hiding_timer != 0) {
                GLib.Source.remove (hiding_timer);
            }

            hiding_timer = GLib.Timeout.add (2000, () => {
                // if (hovered || playlist_popover.visible || !playing) {
                if (hovered || !playing) {
                    hiding_timer = 0;

                    return false;
                }
                set_reveal_child (false);
                hiding_timer = 0;

                return false;
            });
        }
    }
}
