#!/usr/bin/env python3
"""Publish a StatusNotifierItem (system tray icon) for Mac-Duo.

Left click / activate -> `qs ipc ... call macduo toggleSettings`.
Runs only while the macduo shell keeps this process alive.
"""
import os
import signal
import subprocess
import sys

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

SHELL = "/home/revo/.config/quickshell/macduo"
ICON_DIR = os.path.join(SHELL, "icons")

IFACE = "org.kde.StatusNotifierItem"
PROPS_IFACE = "org.freedesktop.DBus.Properties"


def argb_from_png(path):
    """Return (w, h, bytes) with each pixel as big-endian ARGB."""
    png = subprocess.run(
        ["magick", path, "-depth", "8", "rgba:-"],
        capture_output=True, check=True,
    ).stdout
    ident = subprocess.run(
        ["magick", path, "-format", "%w %h", "info:"],
        capture_output=True, check=True,
    ).stdout.decode().split()
    w, h = int(ident[0]), int(ident[1])
    out = bytearray()
    for i in range(0, w * h * 4, 4):
        r, g, b, a = png[i], png[i + 1], png[i + 2], png[i + 3]
        out += bytes((a, r, g, b))
    return w, h, bytes(out)


class StatusNotifierItem(dbus.service.Object):
    def __init__(self, bus, name):
        self._bus = bus
        self._name = name
        self._w22 = argb_from_png(os.path.join(ICON_DIR, "macduo-22.png"))
        self._w48 = argb_from_png(os.path.join(ICON_DIR, "macduo-48.png"))
        super().__init__(bus, "/StatusNotifierItem")
        bus.request_name(name)

    # ---- org.freedesktop.DBus.Properties ----
    @dbus.service.method(PROPS_IFACE, in_signature="ss", out_signature="v")
    def Get(self, iface, prop):
        return self.GetAll(iface)[prop]

    @dbus.service.method(PROPS_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, iface):
        if iface not in (IFACE, "org.freedesktop.DBus.Properties"):
            raise dbus.exceptions.DBusException(
                "unknown interface", name="org.freedesktop.DBus.Error.UnknownInterface")
        w, h, pix = self._w22
        pixmap22 = dbus.Array(
            [dbus.Struct([dbus.Int32(w), dbus.Int32(h),
                          dbus.ByteArray(pix)], signature="iiay")],
            signature="(iiay)")
        return {
            "Category": dbus.String("ApplicationStatus"),
            "Id": dbus.String("macduo"),
            "Title": dbus.String("Mac-Duo"),
            "Status": dbus.String("Active"),
            "IconName": dbus.String("/home/revo/.config/quickshell/macduo/icons/macduo-22.png"),
            
            "IconPixmap": pixmap22,
            "OverlayIconName": dbus.String(""),
            "OverlayIconPixmap": dbus.Array([], signature="(iiay)"),
            "AttentionIconName": dbus.String(""),
            "AttentionIconPixmap": dbus.Array([], signature="(iiay)"),
            "WindowId": dbus.UInt32(0),
            "ItemIsMenu": dbus.Boolean(False),
            "Menu": dbus.ObjectPath("/NO_MENU"),
            "XAyatanaLabel": dbus.String(""),
            "XAyatanaLabelIconName": dbus.String(""),
            "XAyatanaLabelActionGroup": dbus.String(""),
        }

    @dbus.service.method(PROPS_IFACE, in_signature="ssv")
    def Set(self, iface, prop, value):
        pass

    @dbus.service.signal(PROPS_IFACE, signature="ssv")
    def PropertiesChanged(self, iface, changed, invalidated):
        pass

    # ---- StatusNotifierItem methods ----
    @dbus.service.method(IFACE, in_signature="ii")
    def Activate(self, x, y):
        subprocess.Popen(
            ["qs", "ipc", "-p", SHELL, "call", "macduo", "toggleSettings"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )

    @dbus.service.method(IFACE, in_signature="i")
    def SecondaryActivate(self, x):
        pass

    @dbus.service.method(IFACE, in_signature="ii")
    def Scroll(self, delta, orientation):
        pass

    @dbus.service.method(IFACE, in_signature="ii")
    def ContextMenu(self, x, y):
        pass

    # ---- Introspection (minimal) ----
    @dbus.service.method("org.freedesktop.DBus.Introspectable",
                         in_signature="", out_signature="s")
    def Introspect(self):
        return (
            f'<node><interface name="{IFACE}">'
            '<method name="Activate">'
            '<arg type="i" direction="in"/>'
            '<arg type="i" direction="in"/>'
            '</method>'
            '<method name="ContextMenu">'
            '<arg type="i" direction="in"/>'
            '<arg type="i" direction="in"/>'
            '</method>'
            '<property name="Id" type="s" access="read"/>'
            '<property name="Title" type="s" access="read"/>'
            '<property name="Category" type="s" access="read"/>'
            '<property name="Status" type="s" access="read"/>'
            '<property name="IconPixmap" type="a(iiay)" access="read"/>'
            '</interface></node>'
        )


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    name = f"org.kde.StatusNotifierItem-{os.getpid()}"
    item = StatusNotifierItem(bus, name)
    try:
        watcher = bus.get_object("org.kde.StatusNotifierWatcher",
                                 "/StatusNotifierWatcher")
        watcher.RegisterStatusNotifierItem(name)
    except dbus.exceptions.DBusException:
        pass

    loop = GLib.MainLoop()
    signal.signal(signal.SIGTERM, lambda *a: loop.quit())
    signal.signal(signal.SIGINT, lambda *a: loop.quit())
    loop.run()


if __name__ == "__main__":
    main()
