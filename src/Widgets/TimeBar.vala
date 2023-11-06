namespace Videos2 {
    public class Widgets.TimeBar : Gtk.Grid {
        public signal void changed_position (int64 pos);
        public signal void show_preview (int x, int64 pos);
        public signal void hide_preview ();

        public bool can_preview { get; set; }

        private int64 _playback_duration;
        private int64 _playback_progress;

        public int64 playback_duration {
            get {
                return _playback_duration;
            }
            set {
                int64 duration = value < 0 ? 0 : value;

                _playback_duration = duration;
                duration_label.label = Utils.seconds_to_time ((int) duration);
            }
        }

        public int64 playback_progress {
            get {
                return _playback_progress;
            }
            set {
                int64 progress = value < 0 ? 0 : value;


                double playback_position = playback_duration <= 0
                                           ? 0.0
                                           : (double) progress / playback_duration;

                _playback_progress = progress;
                scale.set_value (playback_position > 1.0 ? 1.0 : playback_position);
                progression_label.label = Utils.seconds_to_time ((int) progress);
            }
        }

        public bool is_grabbing { get; private set; default = false; }
        public bool is_hovering { get; private set; default = false; }

        public Gtk.Label progression_label { get; construct set; }
        public Gtk.Label duration_label { get; construct set; }

        public Gtk.Scale scale { get; construct set; }

        public TimeBar (int64 playback_duration) {
            Object (playback_duration: playback_duration,
                column_spacing: 6);
        }

        construct {
            get_style_context ().add_class (Granite.STYLE_CLASS_SEEKBAR);

            progression_label = new Gtk.Label (null);
            duration_label = new Gtk.Label (null);
            progression_label.margin_start = duration_label.margin_end = 3;

            scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 0.1);
            scale.hexpand = true;
            scale.draw_value = false;
            scale.can_focus = false;
            scale.events |= Gdk.EventMask.POINTER_MOTION_MASK;
            scale.events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
            scale.events |= Gdk.EventMask.ENTER_NOTIFY_MASK;

            /* signal property setting */
            scale.button_press_event.connect (() => {
                is_grabbing = true;
                return false;
            });

            scale.button_release_event.connect (() => {
                is_grabbing = false;
                changed_position (Utils.sec_to_nano ((int64) (scale.get_value () * playback_duration)));
                return false;
            });

            scale.enter_notify_event.connect (() => {
                is_hovering = true;
                return false;
            });

            scale.leave_notify_event.connect (() => {
                is_hovering = false;

                hide_preview ();

                return false;
            });

            scale.motion_notify_event.connect (on_motion_notify_event);

            add (progression_label);
            add (scale);
            add (duration_label);

            playback_progress = 0;
        }

        private bool on_motion_notify_event (Gdk.EventMotion event) {
            double x_pos = event.x;

            show_preview ((int) x_pos, Utils.sec_to_nano ((int64) (x_pos / scale.get_allocated_width () * playback_duration)));
    
            return false;
        }

        public override void get_preferred_width (out int minimum_width, out int natural_width) {
            base.get_preferred_width (out minimum_width, out natural_width);

            if (parent == null) {
                return;
            }

            var window = parent.get_window ();
            if (window == null) {
                return;
            }

            var width = parent.get_window ().get_width ();
            if (width > 0 && width >= minimum_width) {
                natural_width = width;
            }
        }
    }
}