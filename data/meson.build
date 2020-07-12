install_data (
    meson.project_name () + '.gschema.xml',
    install_dir: join_paths (get_option ('datadir'), 'glib-2.0', 'schemas')
)

install_data (
    meson.project_name () + '.desktop',
    install_dir: join_paths (get_option ('datadir'), 'applications'),
)

gresource = gnome.compile_resources (
    'as-resources',
    join_paths (meson.project_name () + '.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)
