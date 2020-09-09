namespace Videos2.Constants {
    public const string APP_NAME = "io.elementary.videos2";
    public const string PULSE_CLASS = "pulse";
    public const string PULSE_TYPE = "attention";

    public const string SCREENSAVER_IFACE = "org.freedesktop.ScreenSaver";
    public const string SCREENSAVER_PATH = "/ScreenSaver";

    public const string THUMBNAILER_IFACE = "org.freedesktop.thumbnails.Thumbnailer1";
    public const string THUMBNAILER_SERVICE = "/org/freedesktop/thumbnails/Thumbnailer1";

    public const string NAV_BUTTON_WELCOME = _("Back");
    public const string NAV_BUTTON_BACK = _("Continue");
    public const string NAV_BUTTON_LIBRARY = _("Library");

    // actions
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_ADD = "action-add";
    public const string ACTION_BACK = "action-back";
    public const string ACTION_CLEAR = "action-clear";
    public const string ACTION_MEDIAINFO = "action-mediainfo";
    public const string ACTION_OPEN = "action-open";
    public const string ACTION_PLAYLIST_VISIBLE = "action-playlist-visible";
    public const string ACTION_QUIT = "action-quit";
    public const string ACTION_SEARCH = "action-search";
    public const string ACTION_VOLUME = "action-volume";

    public const int POSTER_WIDTH = 256;
    public const int POSTER_HEIGHT = 256;

    // 204/255 = 80% opacity
    public const uint GLOBAL_OPACITY = 204;

    public const int DISCOVERER_TIMEOUT = 5;

    public const int64 SEC_INV = 1;
    public const int64 NANO_INV = 1000000000;

    public const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PLAYLIST_ITEM", Gtk.TargetFlags.SAME_APP, 0}
    };
}
