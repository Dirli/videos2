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
    [DBus (name = "org.mpris.MediaPlayer2")]
    public class Objects.MprisRoot : GLib.Object {
        public bool can_quit {
            get {return false;}
        }
        public bool can_raise {
            get {return false;}
        }
        public bool has_track_list {
            get {return false;}
        }
        public string identity {
            owned get {return _("Videos2");}
        }
        public string[] supported_mime_types {
            owned get {
                return {
                    "video/mpeg",
                    "video/mp4",
                    "video/x-flv",
                    "video/x-ms-wmv",
                    "video/x-msvideo",
                    "video/x-matroska"
                };
            }
        }
        public string[] supported_uri_schemes {
            owned get {return {"http", "file", "https", "ftp"};}
        }
        public string desktop_entry {
            get {return Constants.APP_NAME;}
        }

        public MprisRoot () {

        }

        public void quit () throws GLib.Error {
            //
        }
        public void raise () throws GLib.Error {
            //
        }
    }
}
