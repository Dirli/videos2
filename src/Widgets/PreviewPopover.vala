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
    public class Widgets.PreviewPopover : Gtk.Popover {

        private bool terminate = false;

        public string uri {
            get; construct set;
        }

        private Gst.Format fmt = Gst.Format.TIME;
        private dynamic Gst.Element playbin;
        private Gst.Bus bus;

        ~PreviewPopover () {
            playbin.set_state (Gst.State.NULL);
        }

        public PreviewPopover (string uri) {
            Object (can_focus: false,
                    sensitive: false,
                    modal: false,
                    uri: uri);
        }

        construct {
            var gtksink = Gst.ElementFactory.make ("gtksink", null);

            Gtk.Widget video_area;
            gtksink.get ("widget", out video_area);

            video_area.vexpand = false;
            video_area.valign = Gtk.Align.CENTER;

            playbin = Gst.ElementFactory.make ("playbin", "bin");
            playbin["video-sink"] = gtksink;

            bus = playbin.get_bus ();
            bus.add_watch (0, bus_callback);
            bus.enable_sync_message_emission ();

            int flags;
            playbin.get ("flags", out flags);
            flags &= ~(1 << 1);
            flags &= ~(1 << 2);
            playbin.set ("flags", flags);


            playbin.set_state (Gst.State.READY);
            playbin.uri = uri;

            add (video_area);
        }


        public void stop_watch () {
            bus.remove_watch ();
        }

        public void update_view (double x, int w) {
            if (x > w || uri == null) {
                return;
            }

            playbin.set_state (Gst.State.PLAYING);
            unowned int64 d = 0;
            do {
                if (playbin.query_duration (fmt, out d)) {
                    terminate = true;
                }
            } while (!terminate);

            if (d <= 0) {
                return;
            }

            // position
            var pos = (int64) ((x / (double) w) * d);
            if (pos >= 0) {
                playbin.seek_simple (fmt, Gst.SeekFlags.FLUSH, pos);
            }

            playbin.set_state (Gst.State.PAUSED);

            var pointing = pointing_to;
            pointing.x = (int) x;

            // changing the width properly updates arrow position when popover hits the edge
            if (pointing.width == 0) {
                pointing.width = 2;
                pointing.x -= 1;
            } else {
                pointing.width = 0;
            }

            set_pointing_to (pointing);

            show_all ();
        }

        private bool bus_callback (Gst.Bus bus, Gst.Message message) {
            switch (message.type) {
                case Gst.MessageType.ERROR:
                    GLib.Error err;
                    string debug;
                    message.parse_error (out err, out debug);
                    warning ("Error: %s\n%s\n", err.message, debug);
                    // warning ("Error code: %d", err.code);

                    terminate = true;
                    break;
                case Gst.MessageType.EOS:
                    terminate = true;
                    break;
                default:
                    break;
            }

            return true;
        }

        public override void get_preferred_width (out int minimum_width, out int natural_width) {
            minimum_width = 200;
            natural_width = 200;
        }

        public override void get_preferred_height (out int minimum_height, out int natural_height) {
            minimum_height = 123;
            natural_height = 123;
        }
    }
}
