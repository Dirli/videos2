# Videos2

<p align="left">
    <a href="https://paypal.me/Dirli85">
        <img src="https://img.shields.io/badge/Donate-PayPal-green.svg">
    </a>
</p>

<img src="data/screenshot.png" title="Videos2 screenshot" width="720"> </img>

A new vision for the EOS video player. I don't want to position this app as new or unique. This is an attempt to rid the native video player of existing bugs and add in demand functionality
* Player plays video, perhaps even better than the original
* Added some features (such as volume control) that had no place in the original.
* Added vaapi supports (install 'gstreamer1.0-vaapi' plugin)
* Added saving playback position and ability to continue viewing from the same place
* Added the ability to change the playback speed
* Implemented preview (on the timeline)
* I gave up the library completely, it seems to me that this is a little wrong way

## Building and Installation

You'll need the following dependencies:
* libgtk-3-dev
* libgee-0.8-dev
* libgranite-dev
* gstreamer1.0-gtk3
* gstreamer1.0-libav
* gstreamer1.0-plugins-base
* libgstreamer1.0-dev
* libgstreamer-plugins-base1.0-dev
* meson
* valac

How to build

    meson build --prefix=/usr
    ninja -C build
    sudo ninja -C build install

## TODO

* failed to achieve transparency of auxiliary windows
* custom HeaderBar breaks video output
