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
