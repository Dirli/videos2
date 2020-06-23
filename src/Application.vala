namespace Videos2 {
    public class App : Gtk.Application {
        private MainWindow main_window;

        construct {
            flags |= ApplicationFlags.HANDLES_OPEN;
            application_id = Constants.APP_NAME;
        }

        public override void open (GLib.File[] files, string hint) {
            activate ();
            main_window.open_files (files);
        }

        protected override void activate () {
            if (main_window == null) {
                main_window = new MainWindow (this);
            }

            main_window.present ();
        }
    }
}

public static int main (string[] args) {
    try {
        Gst.init_check (ref args);
    } catch (Error err) {
        error ("Could not init GStreamer: %s", err.message);
    }

    var app = new Videos2.App ();
    return app.run (args);
}
