#!/bin/bash
# Builds the LogDeck installer package.
#
# Layout:
#   /Applications/Utilities/LogDeck.app            the window, with the logdeck
#                                                  tool in Contents/Helpers
#   /usr/local/bin/logdeck                         a symlink to that tool, for the PATH
# LogDeck only reads logs; it installs no daemon and writes nothing outside its bundle.
#
# The app is built by the Makefile (make app). Set SIGNING_IDENTITY_APP to have
# it sign the app and tool.
#
# Usage: packaging/build-pkg.sh <version> <output-dir> [installer-signing-identity]
set -euo pipefail

VERSION="${1:?version}"
OUT="${2:?output directory}"
SIGN="${3:-}"
IDENTIFIER="com.github.rodchristiansen.logdeck"
APP_REL="Applications/Utilities/LogDeck.app"

cd "$(dirname "$0")/.."
REPO="$(pwd)"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

# The app bundle, stamped with the package version (YYYY.MM.DD.HHMM, split
# into 2026.10.07 and 1530).
make -C "$REPO" app VERSION="$VERSION"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ROOT="$WORK/root"
mkdir -p "$ROOT/Applications/Utilities" "$ROOT/usr/local/bin"
ditto "$REPO/build/pkg-root/$APP_REL" "$ROOT/$APP_REL"
ln -s "/$APP_REL/Contents/Helpers/logdeck" "$ROOT/usr/local/bin/logdeck"

# Clear extended attributes where possible so the payload carries none.
find "$ROOT" -exec xattr -s -c {} + 2>/dev/null || true

# Install the app where the payload says, never over a copy found elsewhere, and
# whatever version is already there: the package version is the one that counts.
pkgbuild --analyze --root "$ROOT" "$WORK/component.plist"
i=0
while /usr/libexec/PlistBuddy -c "Print :$i" "$WORK/component.plist" >/dev/null 2>&1; do
    for key in BundleIsRelocatable BundleIsVersionChecked; do
        /usr/libexec/PlistBuddy -c "Set :$i:$key false" "$WORK/component.plist" 2>/dev/null \
            || /usr/libexec/PlistBuddy -c "Add :$i:$key bool false" "$WORK/component.plist"
    done
    i=$((i + 1))
done
if [[ $i -eq 0 ]]; then
    echo "pkgbuild found no bundle to configure in $ROOT" >&2
    exit 1
fi

pkgbuild --root "$ROOT" --component-plist "$WORK/component.plist" --identifier "$IDENTIFIER" \
    --version "$VERSION" --ownership recommended --install-location / \
    "$WORK/component.pkg"
if [[ -n "$SIGN" ]]; then
    productbuild --package "$WORK/component.pkg" --identifier "$IDENTIFIER" --version "$VERSION" \
        --sign "$SIGN" --timestamp "$OUT/LogDeck-${VERSION}.pkg"
else
    productbuild --package "$WORK/component.pkg" --identifier "$IDENTIFIER" --version "$VERSION" \
        "$OUT/LogDeck-${VERSION}.pkg"
fi
echo "Built $OUT/LogDeck-${VERSION}.pkg"
