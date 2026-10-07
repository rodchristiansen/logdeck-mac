#!/usr/bin/make -f
#
# LogDeck build
# Builds LogDeck.app, with the logdeck command-line tool inside it. The installer
# package is built by packaging/build-pkg.sh, which calls `make app`. With
# SIGNING_IDENTITY_APP set the app and tool are signed; without it they stay
# unsigned, as the public release does.
#

-include .env
export

SIGNING_IDENTITY_APP := $(subst ",,$(SIGNING_IDENTITY_APP))
SIGNING_IDENTITY_PKG := $(subst ",,$(SIGNING_IDENTITY_PKG))
NOTARIZATION_PROFILE := $(subst ",,$(NOTARIZATION_PROFILE))

# One build stamp, YYYY.MM.DD.HHMM, split for the About box as 2026.10.07 (1530).
VERSION := $(or $(VERSION),$(shell date '+%Y.%m.%d.%H%M'))
MARKETING_VERSION := $(shell echo $(VERSION) | sed 's/\.[^.]*$$//')
BUILD_NUMBER := $(shell echo $(VERSION) | sed 's/.*\.//')

BUILD_DIR = build
DIST_DIR = dist
PKG_ROOT = $(BUILD_DIR)/pkg-root
APP_BUNDLE_PATH = Applications/Utilities/LogDeck.app
APP_CONTENTS = $(PKG_ROOT)/$(APP_BUNDLE_PATH)/Contents
APP_IDENTIFIER = com.github.logdeck
CLI_IDENTIFIER = com.github.logdeck.cli

# The output path differs between toolchains, so ask SwiftPM for it.
SWIFT_BUILD_DIR = $(shell swift build -c release --arch arm64 --arch x86_64 --show-bin-path)

# The app icon is the Icon Composer bundle resources/LogDeck.icon. actool
# compiles it into Assets.car, which holds the macOS 26 icon with its light and
# dark appearances, and a composited LogDeck.icns for older macOS. An actool
# older than Xcode 27's drops the appearance stacks without an error, so the
# build finds Xcode 27 and refuses to go on without it. Set XCODE_27 to the
# Xcode app to use a specific one. actool is given absolute paths: its icon
# export runs in another process and loses a relative one.
ICON_NAME = LogDeck
ICON_SOURCE = $(CURDIR)/resources/$(ICON_NAME).icon
ICON_BUILD_DIR = $(CURDIR)/$(BUILD_DIR)/actool-out

# Record the SDK the binaries are linked against. Some toolchains write the
# deployment target as the SDK version, and AppKit then keeps the pre-macOS 26
# window chrome. The version is stamped after linking with vtool.
SDK_VERSION := $(shell xcrun --show-sdk-version)
DEPLOYMENT_TARGET = 14.0

.PHONY: all build test icon app pkg notarize verify clean

all: app

build:
	swift build -c release --arch arm64 --arch x86_64

test:
	swift test

icon:
	@set -e; dev=""; \
	for xc in "$(XCODE_27)" /Applications/Xcode_27.app /Applications/Xcode_27.*.app \
		"$$(xcode-select -p 2>/dev/null | sed 's|/Contents/Developer$$||')" /Applications/Xcode.app; do \
		[ -n "$$xc" ] && [ -d "$$xc/Contents/Developer" ] || continue; \
		ver=$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$$xc/Contents/Info.plist" 2>/dev/null || true); \
		if [ "$${ver%%.*}" -ge 27 ] 2>/dev/null; then dev="$$xc/Contents/Developer"; break; fi; \
	done; \
	if [ -z "$$dev" ]; then \
		echo "error: the app icon needs actool from Xcode 27 or later; none found." >&2; \
		echo "Install Xcode 27, select it with xcode-select, or set XCODE_27=/path/to/Xcode.app." >&2; \
		exit 1; \
	fi; \
	[ -d "$(ICON_SOURCE)" ] || { echo "error: icon bundle not found at $(ICON_SOURCE)" >&2; exit 1; }; \
	rm -rf "$(ICON_BUILD_DIR)"; mkdir -p "$(ICON_BUILD_DIR)" "$(APP_CONTENTS)/Resources"; \
	echo "Compiling $(ICON_SOURCE) with actool from $$dev"; \
	DEVELOPER_DIR="$$dev" xcrun actool \
		--compile "$(ICON_BUILD_DIR)" \
		--platform macosx \
		--minimum-deployment-target $(DEPLOYMENT_TARGET) \
		--app-icon "$(ICON_NAME)" \
		--output-partial-info-plist "$(ICON_BUILD_DIR)/partial-info.plist" \
		--warnings --errors \
		"$(ICON_SOURCE)" > /dev/null; \
	for out in Assets.car "$(ICON_NAME).icns"; do \
		[ -f "$(ICON_BUILD_DIR)/$$out" ] || { echo "error: actool did not produce $$out" >&2; exit 1; }; \
		cp "$(ICON_BUILD_DIR)/$$out" "$(APP_CONTENTS)/Resources/$$out"; \
	done

app: build
	@rm -rf "$(PKG_ROOT)"
	@mkdir -p "$(APP_CONTENTS)/MacOS" "$(APP_CONTENTS)/Helpers" "$(APP_CONTENTS)/Resources"
	@# The tool goes in Helpers: beside LogDeck in MacOS, logdeck would be the
	@# same file on a case-insensitive volume.
	@cp "$(SWIFT_BUILD_DIR)/LogDeckApp" "$(APP_CONTENTS)/MacOS/LogDeck"
	@cp "$(SWIFT_BUILD_DIR)/logdeck" "$(APP_CONTENTS)/Helpers/logdeck"
	@chmod 755 "$(APP_CONTENTS)/MacOS/LogDeck" "$(APP_CONTENTS)/Helpers/logdeck"
	@for bin in "$(APP_CONTENTS)/MacOS/LogDeck" "$(APP_CONTENTS)/Helpers/logdeck"; do \
		vtool -set-build-version macos $(DEPLOYMENT_TARGET) $(SDK_VERSION) -replace -output "$$bin.stamped" "$$bin" && \
		mv "$$bin.stamped" "$$bin" && codesign --force --sign - "$$bin" 2>/dev/null; \
	done
	@sed -e 's/{{MARKETING_VERSION}}/$(MARKETING_VERSION)/g' \
	     -e 's/{{BUILD_NUMBER}}/$(BUILD_NUMBER)/g' \
	     packaging/Info.plist.template > "$(APP_CONTENTS)/Info.plist"
	@printf 'APPL????' > "$(APP_CONTENTS)/PkgInfo"
	@$(MAKE) --no-print-directory icon
ifneq ($(SIGNING_IDENTITY_APP),)
	@codesign --force --sign "$(SIGNING_IDENTITY_APP)" --options runtime --timestamp \
		--entitlements packaging/entitlements/cli.entitlements \
		--identifier $(CLI_IDENTIFIER) "$(APP_CONTENTS)/Helpers/logdeck"
	@codesign --force --sign "$(SIGNING_IDENTITY_APP)" --options runtime --timestamp \
		--entitlements packaging/entitlements/app.entitlements \
		--identifier $(APP_IDENTIFIER) "$(PKG_ROOT)/$(APP_BUNDLE_PATH)"
	@echo "Signed app bundle"
else
	@echo "SIGNING_IDENTITY_APP not set: app bundle left unsigned"
endif

# The installer package, signed when SIGNING_IDENTITY_PKG is set.
pkg:
	packaging/build-pkg.sh "$(VERSION)" "$(DIST_DIR)" "$(SIGNING_IDENTITY_PKG)"

notarize: pkg
	@[ -n "$(NOTARIZATION_PROFILE)" ] || { echo "error: NOTARIZATION_PROFILE not set" >&2; exit 1; }
	xcrun notarytool submit "$(DIST_DIR)/LogDeck-$(VERSION).pkg" --keychain-profile "$(NOTARIZATION_PROFILE)" --wait
	xcrun stapler staple "$(DIST_DIR)/LogDeck-$(VERSION).pkg"

verify:
	@codesign --verify --strict --verbose=2 "$(PKG_ROOT)/$(APP_BUNDLE_PATH)"

clean:
	@rm -rf $(BUILD_DIR) $(DIST_DIR) .build
