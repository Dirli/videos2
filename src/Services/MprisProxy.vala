namespace Videos2 {
    public class Services.MprisProxy : GLib.Object {
        public signal void play ();
        public signal void stop ();
        public signal void pause ();
        public signal bool next ();
        public signal bool prev ();
        public signal void toggle_playing ();

        public string title {
            get; set; default = "";
        }

        public bool can_next {
            get; set;
        }

        public bool can_previous {
            get; set;
        }

        public string playback_status {
            get; set; default = "Stopped";
        }

        private Gst.State _state;
        public Gst.State state {
            get {
                return _state;
            }
            set {
                playback_status = value == Gst.State.PLAYING ? "Playing" :
                                  value == Gst.State.PAUSED ? "Paused" :
                                  "Stopped";

                _state = value;
            }
        }

        public MprisProxy () {

        }
    }
}
