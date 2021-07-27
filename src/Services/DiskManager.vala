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
    public class Services.DiskManager : GLib.Object {
        public signal void found_media ();
        public signal void deleted_media ();

        private GLib.VolumeMonitor monitor;
        private string mount_uuid = "";
        public string mount_uri {
            get;
            private set;
        }

        public bool has_media_mounts {
            get {
                return mount_uuid != "";
            }
        }

        construct {
            monitor = GLib.VolumeMonitor.get ();
            monitor.get_mounts ().foreach ((mount) => {
                check_mount_media (mount);
            });

            monitor.mount_added.connect ((mount) => {
                if (check_mount_media (mount)) {
                    found_media ();
                }
            });

            monitor.mount_removed.connect ((mount) => {
                if (mount.get_uuid () == mount_uuid) {
                    mount_uri = "";
                    mount_uuid = "";
                    deleted_media ();
                }
            });
        }

        private bool check_mount_media (GLib.Mount mount) {
            if (mount.can_eject () && mount.get_icon ().to_string ().contains ("optical")) {
                var root = mount.get_default_location ();
                if (root != null) {
                    var video = root.get_child ("VIDEO_TS");
                    if (video.query_exists ()) {
                        mount_uri = root.get_uri ();
                        mount_uuid = mount.get_uuid ();

                        return true;
                    }
                }
            }

            return false;
        }
    }
}
