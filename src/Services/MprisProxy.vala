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
