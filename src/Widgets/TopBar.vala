namespace Videos2 {
    public class Widgets.TopBar : Gtk.Revealer {
        public signal void unfullscreen ();

        public TopBar () {
            Object (transition_type: Gtk.RevealerTransitionType.SLIDE_DOWN,
                    halign: Gtk.Align.END,
                    valign: Gtk.Align.START);
        }

        construct {
            var unfullscreen_button = new Gtk.Button.from_icon_name ("view-restore-symbolic", Gtk.IconSize.BUTTON);
            unfullscreen_button.halign = Gtk.Align.END;
            unfullscreen_button.tooltip_text = _("Unfullscreen");
            unfullscreen_button.clicked.connect (() => {
                unfullscreen ();
            });

            add (unfullscreen_button);
        }
    }
}
