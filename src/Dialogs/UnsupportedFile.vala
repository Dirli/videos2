namespace Videos2 {
    public class Dialogs.UnsupportedFile : Granite.MessageDialog {
        public string content_type { get; construct; }
        public string uri { get; construct; }

        public UnsupportedFile (Gtk.Window window, string uri, string filename, string content_type) {
            Object (title: "",
                    primary_text: _("Unrecognized file format"),
                    secondary_text: _("Videos might not be able to play the file '%s'.".printf (filename)),
                    buttons: Gtk.ButtonsType.CANCEL,
                    image_icon: new ThemedIcon ("dialog-error"),
                    transient_for: window,
                    window_position: Gtk.WindowPosition.CENTER,
                    content_type: content_type,
                    uri: uri);
        }

        construct {
            var play_anyway_button = add_button (_("Play Anyway"), Gtk.ResponseType.ACCEPT);
            play_anyway_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            var error_text = _("Unable to play file at: %s\nThe file is not a video (\"%s\").").printf (
                uri,
                GLib.ContentType.get_description (content_type)
            );
            show_error_details (error_text);
        }
    }
}
