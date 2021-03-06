namespace Videos2.Constants {
    public const string APP_NAME = "io.elementary.videos2";
    public const string PULSE_CLASS = "pulse";
    public const string PULSE_TYPE = "attention";

    public const string MPRIS_NAME = "org.mpris.MediaPlayer2.Videos2";
    public const string MPRIS_PATH = "/org/mpris/MediaPlayer2";

    public const string SCREENSAVER_IFACE = "org.freedesktop.ScreenSaver";
    public const string SCREENSAVER_PATH = "/ScreenSaver";

    public const string THUMBNAILER_IFACE = "org.freedesktop.thumbnails.Thumbnailer1";
    public const string THUMBNAILER_SERVICE = "/org/freedesktop/thumbnails/Thumbnailer1";

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
    public const string ACTION_SPEED = "action-speed";
    public const string ACTION_SHORTCUTS = "action-shortcuts";
    public const string ACTION_PREFERENCES = "action-preferences";

    public const int POSTER_WIDTH = 256;
    public const int POSTER_HEIGHT = 256;

    // 204/255 = 80% opacity
    public const uint GLOBAL_OPACITY = 204;

    public const int DISCOVERER_TIMEOUT = 5;

    public const int64 SEC_INV = 1;
    public const int64 NANO_INV = 1000000000;

    public const double[] speeds_array = {
        0.5,
        0.75,
        1,
        1.25,
        1.5,
        2,
        3,
        4
    };

    public const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PLAYLIST_ITEM", Gtk.TargetFlags.SAME_APP, 0}
    };
}
