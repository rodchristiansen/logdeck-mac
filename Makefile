#!/usr/bin/make -f
#
# LogDeck Build System
# Builds, signs, notarizes, and packages LogDeck for Munki deployment
#

# Load environment variables from .env file if it exists
-include .env
export

# Strip surrounding quotes if values were quoted in .env (Make doesn't do this like bash)
SIGNING_IDENTITY_APP  := $(subst ",,$(SIGNING_IDENTITY_APP))
SIGNING_IDENTITY_PKG  := $(subst ",,$(SIGNING_IDENTITY_PKG))
NOTARIZATION_PROFILE  := $(subst ",,$(NOTARIZATION_PROFILE))
NOTARIZATION_TEAM_ID  := $(subst ",,$(NOTARIZATION_TEAM_ID))

# Version from environment or generate timestamp
VERSION ?= $(shell date '+%Y.%m.%d.%H%M')

# Directories
BUILD_DIR     = build
DIST_DIR      = dist
PKG_ROOT      = $(BUILD_DIR)/pkg-root
PACKAGING_DIR = packaging
SCRIPTS_DIR   = $(BUILD_DIR)/scripts

# Swift build outputs (per-arch, then lipo'd)
ARM64_BUILD_DIR  = .build/arm64-apple-macosx/release
X86_64_BUILD_DIR = .build/x86_64-apple-macosx/release
UNIVERSAL_DIR    = $(BUILD_DIR)/universal
GUI_BINARY       = $(UNIVERSAL_DIR)/LogDeck
CLI_BINARY       = $(UNIVERSAL_DIR)/logdeck

# Icon source (Icon Composer .icon bundle)
ICON_SOURCE    = $(BUILD_DIR)/resources/LogDeck.icon
ICON_BUILD_DIR = $(BUILD_DIR)/actool-out

# Package root layout (installed locations)
APP_INSTALL_PATH  = Applications/Utilities/LogDeck.app
CLI_INSTALL_PATH  = usr/local/bin
APP_BUNDLE        = $(PKG_ROOT)/$(APP_INSTALL_PATH)
APP_MACOS_DIR     = $(APP_BUNDLE)/Contents/MacOS
APP_RESOURCES_DIR = $(APP_BUNDLE)/Contents/Resources

# Package configuration
PKG_ID     = ca.ecuad.macadmin.LogDeck
PKG_NAME   = LogDeck-$(VERSION).pkg
PKG_OUTPUT = $(DIST_DIR)/$(PKG_NAME)

# Bundle identifiers
BUNDLE_ID_APP = ca.ecuad.macadmin.LogDeck
BUNDLE_ID_CLI = ca.ecuad.macadmin.logdeck

# Signing / notarization (set via .env or environment)
# SIGNING_IDENTITY_APP  - Developer ID Application certificate
# SIGNING_IDENTITY_PKG  - Developer ID Installer certificate
# NOTARIZATION_PROFILE  - Notarytool keychain profile name
# NOTARIZATION_TEAM_ID  - Apple Developer Team ID

# Colors
RED    = \033[0;31m
GREEN  = \033[0;32m
YELLOW = \033[1;33m
BLUE   = \033[0;34m
NC     = \033[0m

.PHONY: all build test swift-build assemble compile-icon sign-binaries build-pkg sign-pkg \
        notarize-pkg verify install check-signing-config list-identities clean help

# ---------------------------------------------------------------------------
# Default: full pipeline → signed, notarized Munki-ready .pkg
# ---------------------------------------------------------------------------

all: build

# ---------------------------------------------------------------------------
# Signing validation
# ---------------------------------------------------------------------------

check-signing-config:
	@if [ -z "$(SIGNING_IDENTITY_APP)" ]; then \
		echo "$(RED)✗ Error: SIGNING_IDENTITY_APP not set$(NC)"; \
		echo "$(YELLOW)  Create a .env file (see .env.example) or set environment variables$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(SIGNING_IDENTITY_PKG)" ]; then \
		echo "$(RED)✗ Error: SIGNING_IDENTITY_PKG not set$(NC)"; \
		echo "$(YELLOW)  Create a .env file (see .env.example) or set environment variables$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(NOTARIZATION_PROFILE)" ]; then \
		echo "$(RED)✗ Error: NOTARIZATION_PROFILE not set$(NC)"; \
		echo "$(YELLOW)  Create a .env file (see .env.example) or set environment variables$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(NOTARIZATION_TEAM_ID)" ]; then \
		echo "$(RED)✗ Error: NOTARIZATION_TEAM_ID not set$(NC)"; \
		echo "$(YELLOW)  Create a .env file (see .env.example) or set environment variables$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Signing configuration validated$(NC)"

# ---------------------------------------------------------------------------
# Full pipeline (make default)
# ---------------------------------------------------------------------------

build: check-signing-config swift-build assemble sign-binaries build-pkg sign-pkg notarize-pkg verify
	@echo ""
	@echo "$(GREEN)✓ LogDeck $(VERSION) ready: $(PKG_OUTPUT)$(NC)"
	@echo "$(BLUE)  Deploy via Munki or run: sudo make install$(NC)"

# ---------------------------------------------------------------------------
# Build steps
# ---------------------------------------------------------------------------

swift-build:
	@echo "$(BLUE)Building release (arm64)...$(NC)"
	@swift build -c release --arch arm64
	@echo "$(BLUE)Building release (x86_64)...$(NC)"
	@swift build -c release --arch x86_64
	@echo "$(BLUE)Creating universal binaries...$(NC)"
	@mkdir -p "$(UNIVERSAL_DIR)"
	@lipo -create \
		"$(ARM64_BUILD_DIR)/LogDeck" \
		"$(X86_64_BUILD_DIR)/LogDeck" \
		-output "$(GUI_BINARY)"
	@lipo -create \
		"$(ARM64_BUILD_DIR)/logdeck" \
		"$(X86_64_BUILD_DIR)/logdeck" \
		-output "$(CLI_BINARY)"
	@echo "$(GREEN)✓ Universal binaries ready$(NC)"

assemble: swift-build
	@echo "$(BLUE)Assembling package root...$(NC)"
	@rm -rf "$(PKG_ROOT)"
	@mkdir -p "$(APP_MACOS_DIR)" "$(APP_RESOURCES_DIR)" "$(PKG_ROOT)/$(CLI_INSTALL_PATH)"
	@cp "$(GUI_BINARY)" "$(APP_MACOS_DIR)/LogDeck"
	@chmod 755 "$(APP_MACOS_DIR)/LogDeck"
	@cp "$(CLI_BINARY)" "$(PKG_ROOT)/$(CLI_INSTALL_PATH)/logdeck"
	@chmod 755 "$(PKG_ROOT)/$(CLI_INSTALL_PATH)/logdeck"
	@sed 's/{{VERSION}}/$(VERSION)/g' \
		"$(PACKAGING_DIR)/Info.plist.template" \
		> "$(APP_BUNDLE)/Contents/Info.plist"
	@printf 'APPL????' > "$(APP_BUNDLE)/Contents/PkgInfo"
	@echo "$(GREEN)✓ Package root assembled: $(PKG_ROOT)/$(NC)"

compile-icon: assemble
	@if [ -d "$(ICON_SOURCE)" ]; then \
		echo "$(BLUE)Compiling icon bundle with actool...$(NC)"; \
		mkdir -p "$(ICON_BUILD_DIR)"; \
		xcrun actool \
			--compile "$(ICON_BUILD_DIR)" \
			--platform macosx \
			--minimum-deployment-target 14.0 \
			--app-icon "LogDeck" \
			--output-partial-info-plist "$(ICON_BUILD_DIR)/partial-info.plist" \
			--warnings --errors \
			"$(ICON_SOURCE)" > /dev/null; \
		if [ -f "$(ICON_BUILD_DIR)/Assets.car" ]; then \
			cp "$(ICON_BUILD_DIR)/Assets.car" "$(APP_RESOURCES_DIR)/Assets.car"; \
			echo "$(GREEN)✓ Icon compiled: Assets.car$(NC)"; \
		else \
			echo "$(RED)✗ actool did not produce Assets.car$(NC)"; \
			exit 1; \
		fi; \
		if [ -f "$(ICON_BUILD_DIR)/LogDeck.icns" ]; then \
			cp "$(ICON_BUILD_DIR)/LogDeck.icns" "$(APP_RESOURCES_DIR)/LogDeck.icns"; \
			echo "$(GREEN)✓ Icon compiled: LogDeck.icns (legacy fallback)$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)⚠ Icon bundle not found at: $(ICON_SOURCE)$(NC)"; \
		echo "$(YELLOW)  Build will continue without an app icon$(NC)"; \
	fi

sign-binaries: compile-icon
	@echo "$(BLUE)Signing CLI binary...$(NC)"
	@codesign --force --sign "$(SIGNING_IDENTITY_APP)" \
		--options runtime \
		--timestamp \
		--entitlements "$(PACKAGING_DIR)/entitlements/cli.entitlements" \
		--identifier "$(BUNDLE_ID_CLI)" \
		"$(PKG_ROOT)/$(CLI_INSTALL_PATH)/logdeck"
	@echo "$(GREEN)✓ CLI binary signed$(NC)"
	@echo "$(BLUE)Signing app bundle...$(NC)"
	@codesign --force --sign "$(SIGNING_IDENTITY_APP)" \
		--options runtime \
		--timestamp \
		--deep \
		--entitlements "$(PACKAGING_DIR)/entitlements/app.entitlements" \
		--identifier "$(BUNDLE_ID_APP)" \
		"$(APP_BUNDLE)"
	@codesign --verify --deep --strict "$(APP_BUNDLE)"
	@echo "$(GREEN)✓ App bundle signed$(NC)"

build-pkg: sign-binaries
	@echo "$(BLUE)Building installer package...$(NC)"
	@mkdir -p "$(DIST_DIR)" "$(SCRIPTS_DIR)"
	@if [ -f "$(PACKAGING_DIR)/scripts/postinstall" ]; then \
		cp "$(PACKAGING_DIR)/scripts/postinstall" "$(SCRIPTS_DIR)/postinstall"; \
		chmod +x "$(SCRIPTS_DIR)/postinstall"; \
		pkgbuild \
			--root "$(PKG_ROOT)" \
			--identifier "$(PKG_ID)" \
			--version "$(VERSION)" \
			--install-location "/" \
			--component-plist "$(PACKAGING_DIR)/component.plist" \
			--scripts "$(SCRIPTS_DIR)" \
			"$(PKG_OUTPUT)"; \
	else \
		pkgbuild \
			--root "$(PKG_ROOT)" \
			--identifier "$(PKG_ID)" \
			--version "$(VERSION)" \
			--install-location "/" \
			--component-plist "$(PACKAGING_DIR)/component.plist" \
			"$(PKG_OUTPUT)"; \
	fi
	@echo "$(GREEN)✓ Package built: $(PKG_OUTPUT)$(NC)"

sign-pkg: build-pkg
	@echo "$(BLUE)Signing installer package...$(NC)"
	@productsign \
		--sign "$(SIGNING_IDENTITY_PKG)" \
		--timestamp \
		"$(PKG_OUTPUT)" \
		"$(PKG_OUTPUT).signed"
	@mv "$(PKG_OUTPUT).signed" "$(PKG_OUTPUT)"
	@echo "$(GREEN)✓ Package signed$(NC)"

notarize-pkg: sign-pkg
	@echo "$(BLUE)Notarizing package (this may take several minutes)...$(NC)"
	@xcrun notarytool submit "$(PKG_OUTPUT)" \
		--keychain-profile "$(NOTARIZATION_PROFILE)" \
		--wait
	@echo "$(BLUE)Stapling notarization ticket...$(NC)"
	@xcrun stapler staple "$(PKG_OUTPUT)"
	@echo "$(GREEN)✓ Package notarized and stapled$(NC)"

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

verify:
	@echo "$(BLUE)Verifying package security...$(NC)"
	@echo ""
	@echo "Signature verification:"
	@pkgutil --check-signature "$(PKG_OUTPUT)" || (echo "$(RED)✗ Package is not signed$(NC)" && exit 1)
	@echo ""
	@echo "Notarization verification:"
	@xcrun stapler validate "$(PKG_OUTPUT)" || (echo "$(RED)✗ Package is not notarized$(NC)" && exit 1)
	@echo ""
	@echo "Gatekeeper assessment:"
	@spctl --assess --type install "$(PKG_OUTPUT)" || (echo "$(RED)✗ Package will not pass Gatekeeper$(NC)" && exit 1)
	@echo ""
	@echo "$(GREEN)✓ All security checks passed$(NC)"

# ---------------------------------------------------------------------------
# Local install
# ---------------------------------------------------------------------------

install:
	@echo "$(BLUE)Installing LogDeck $(VERSION) to /Applications/Utilities...$(NC)"
	@sudo installer -pkg "$(PKG_OUTPUT)" -target /
	@echo "$(GREEN)✓ LogDeck installed$(NC)"

# ---------------------------------------------------------------------------
# Development
# ---------------------------------------------------------------------------

dev:
	@echo "$(BLUE)Building (debug)...$(NC)"
	@swift build
	@echo "$(GREEN)✓ Build complete$(NC)"

test:
	@echo "$(BLUE)Running tests (clean build)...$(NC)"
	@swift package clean
	@swift test
	@echo "$(GREEN)✓ Tests passed$(NC)"

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

list-identities:
	@echo "Developer ID Application certificates:"
	@security find-identity -v -p codesigning | grep "Developer ID Application" || echo "  None found"
	@echo ""
	@echo "Developer ID Installer certificates:"
	@security find-identity -v -p basic | grep "Developer ID Installer" || echo "  None found"
	@echo ""
	@echo "Notarytool keychain profiles:"
	@xcrun notarytool store-credentials --list 2>/dev/null || \
		echo "  Use: xcrun notarytool store-credentials <name> --apple-id ... --team-id ..."

clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf "$(BUILD_DIR)" "$(DIST_DIR)" || true
	@chmod -R u+w .build 2>/dev/null || true
	@rm -rf .build || true
	@echo "$(GREEN)✓ Clean complete$(NC)"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

help:
	@echo "LogDeck Build System"
	@echo ""
	@echo "Targets:"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "make (default)" "Full pipeline: compile → sign → notarize → .pkg"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "swift-build"    "Universal release compile only"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "assemble"       "Assemble package root filesystem layout"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "sign-binaries"  "Sign app bundle and CLI binary"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "build-pkg"      "Build unsigned installer package"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "sign-pkg"       "Sign installer package"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "notarize-pkg"   "Notarize and staple package"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "verify"         "Verify signatures and notarization"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "install"        "Install .pkg locally (sudo installer)"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "dev"            "Debug build (development)"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "test"           "Run test suite (clean build)"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "list-identities" "Show available signing certificates"
	@printf "  $(BLUE)%-20s$(NC) %s\n" "clean"          "Remove all build artifacts"
	@echo ""
	@echo "Configuration (set in .env or environment):"
	@printf "  %-24s %s\n" "SIGNING_IDENTITY_APP" "$(or $(SIGNING_IDENTITY_APP),<not set>)"
	@printf "  %-24s %s\n" "SIGNING_IDENTITY_PKG" "$(or $(SIGNING_IDENTITY_PKG),<not set>)"
	@printf "  %-24s %s\n" "NOTARIZATION_PROFILE" "$(or $(NOTARIZATION_PROFILE),<not set>)"
	@printf "  %-24s %s\n" "NOTARIZATION_TEAM_ID" "$(or $(NOTARIZATION_TEAM_ID),<not set>)"
	@printf "  %-24s %s\n" "VERSION"              "$(VERSION)"
	@echo ""
	@echo "Workflow:"
	@echo "  1. cp .env.example .env  # fill in signing credentials"
	@echo "  2. make                  # build → sign → notarize → $(PKG_NAME)"
	@echo "  3. make install          # install locally for testing"
	@echo "  4. Import $(PKG_NAME) into Munki"
