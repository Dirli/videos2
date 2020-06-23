project(
    'io.elementary.videos2',
    'vala', 'c',
    version: '0.1.0'
)

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language:'c'
)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/Constants.vala',
    'src/MainWindow.vala',
    'src/Services/Utils.vala',
    'src/Views/WelcomePage.vala',
    'src/Widgets/BottomBar.vala',
    'src/Widgets/Player.vala',
    dependencies: [
        dependency ('glib-2.0'),
        dependency ('gobject-2.0'),
        dependency ('granite'),
        dependency ('gtk+-3.0', version: '>=3.22'),
        dependency ('gstreamer-1.0'),
        dependency ('gstreamer-video-1.0'),
        dependency ('gstreamer-tag-1.0'),
        dependency ('gstreamer-pbutils-1.0'),
    ],
    install : true
)

subdir ('data')

meson.add_install_script ('meson_post_install.py')
