/*
 * Static launcher for the XStreamingDesktop Flatpak when started from a
 * non-Steam shortcut in Gaming Mode (gamescope) on this NixOS host.
 *
 * Why this exists
 * ---------------
 * Steam's Gaming Mode force-injects
 *     LD_PRELOAD=<steam>/ubuntu12_32/gameoverlayrenderer.so:<steam>/ubuntu12_64/...
 * into every shortcut it launches, regardless of the per-app "Enable the
 * Steam Overlay" checkbox. The 64-bit overlay library has an unmet
 * dependency on libGL.so.1. On SteamOS that resolves from /usr/lib; on
 * NixOS there is no libGL.so.1 on any default loader path (no /usr/lib, no
 * ld.so.cache, and /run/opengl-driver/lib ships only the vendor libs, not
 * glvnd's dispatch libGL.so.1). The dynamically linked `flatpak` binary
 * therefore aborts at exec:
 *     flatpak: error while loading shared libraries: libGL.so.1
 * and the shortcut hangs forever on the Steam spinner.
 *
 * Every wrapper that runs through a dynamically linked shell (sh -c,
 * bash scripts, steam-run) fails the same way: the overlay is preloaded
 * into the shell itself before it can adjust the environment.
 *
 * A *statically* linked binary has no PT_INTERP, so ld.so never runs and
 * LD_PRELOAD is ignored entirely. This launcher always starts, puts
 * libglvnd on LD_LIBRARY_PATH (so the overlay resolves once `flatpak`
 * re-execs), and hands off to `flatpak run`.
 *
 * Point the Steam shortcut's Target at this binary
 * (/run/current-system/sw/bin/xstreaming-launch) with empty launch options.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef GLVND_LIBDIR
#define GLVND_LIBDIR "/run/opengl-driver/lib"
#endif
#ifndef FLATPAK_BIN
#define FLATPAK_BIN "/run/current-system/sw/bin/flatpak"
#endif
#ifndef FLATPAK_APP_ID
#define FLATPAK_APP_ID "io.github.Geocld.XStreamingDesktop"
#endif

int main(int argc, char **argv)
{
    const char *cur = getenv("LD_LIBRARY_PATH");
    char buf[8192];

    if (cur && *cur)
        snprintf(buf, sizeof buf, "%s:%s", GLVND_LIBDIR, cur);
    else
        snprintf(buf, sizeof buf, "%s", GLVND_LIBDIR);
    setenv("LD_LIBRARY_PATH", buf, 1);

    char *nargv[64];
    int n = 0;
    nargv[n++] = (char *)FLATPAK_BIN;
    nargv[n++] = "run";
    nargv[n++] = (char *)FLATPAK_APP_ID;
    for (int i = 1; i < argc && n < 62; i++)
        nargv[n++] = argv[i];
    nargv[n] = NULL;

    execv(FLATPAK_BIN, nargv);
    perror("xstreaming-launch: execv flatpak");
    return 127;
}
