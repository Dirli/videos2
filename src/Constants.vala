namespace Videos2.Constants {
    public const string APP_NAME = "io.elementary.videos2";
    public const string PULSE_CLASS = "pulse";
    public const string PULSE_TYPE = "attention";

    private const string SCREENSAVER_IFACE = "org.freedesktop.ScreenSaver";
    private const string SCREENSAVER_PATH = "/ScreenSaver";

    public const string NAV_BUTTON_WELCOME = _("Back");

    // actions
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_OPEN = "action-open";
    public const string ACTION_ADD = "action-add";
    public const string ACTION_QUIT = "action-quit";
    public const string ACTION_SEARCH = "action-search";

    // 204/255 = 80% opacity
    public const uint GLOBAL_OPACITY = 204;

    public const int64 SEC_INV = 1;
    public const int64 NANO_INV = 1000000000;

    public const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PLAYLIST_ITEM", Gtk.TargetFlags.SAME_APP, 0}
    };
}
