#!/bin/sh
# Called by luci-app-picoclaw's postinst.
#
# The canonical registration lives in /usr/share/linkease/apps.d and is shipped
# as a symlink inside the package. This hook only maintains the legacy
# /usr/share/linkeasefull/desktop-apps.d entry during the transition period.
# The compatibility link is deliberately NOT part of the package file list so
# it can never conflict with an older metadata package that still owns it.
set -e

root="${IPKG_INSTROOT:-}"
manifest="/usr/share/picoclaw/picoclaw-plugin.json"
legacy="${root}/usr/share/linkeasefull/desktop-apps.d/40-picoclaw.json"

[ -f "${root}${manifest}" ] || exit 0

if [ ! -e "${legacy}" ] && [ ! -L "${legacy}" ]; then
    mkdir -p "${legacy%/*}"
    ln -s "${manifest}" "${legacy}"
fi

exit 0
