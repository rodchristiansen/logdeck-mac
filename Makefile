#!/usr/bin/make -f
#
# LogDeck Build System
# Builds, signs, notarizes LogDeck.app and the logdeck CLI binary
#

# Load environment variables from .env file if it exists
-include .env
export

# Version from environment or generate timestamp
VERSION ?= $(shell date '+%Y.%m.%d.%H%M')

# Directories
BUILD_DIR     = build
DIST_DIR      = dist
PACKAGING_DIR = packaging
DMG_STAGING   = $(BUILD_DIR)/dmg-staging

# Swift build outputs (xcodebuild-style universal path)
SWIFT_BUILD_DIR = .build/apple/Products/Release
GUI_BINARY      = $(SWIFT_BUILD_DIR)/LogDeck
CLI_BINARY      = $(SWIFT_BUILD_DIR)/logdeck

# App bundle paths
APP_BUNDLE       = $(BUILD_DIR)/LogDeck.app
APP_MACOS_DIR    = $(APP_BUNDLE)/Contents/MacOS
APP_RESOURCES_DIR = $(APP_BUNDLE)/Contents/Resources

# Output artifacts
DMG_NAME   = LogDeck-$(VERSION).dmg
DMG_OUTPUT = $(DIST_DIR)/$(DMG_NAME)

# Signing / notarization (set via .env or environment)
# APP_SIGNING_CERT  - Developer ID Application certificate
# NOTARY_PROFILE    - Notarytool keychain profile name
# TEAM_ID           - Apple Developer Team ID

# Bundle identifiers
BUNDLE_ID_APP = ca.ecuad.macadmin.LogDeck
BUNDLE_ID_CLI = ca.ecuad.macadmin.logdeck

# Colors
RED    = \033[0;31m
GREEN  = \033[0;32m
YELLOW = \033[1;33m
BLUE   = \033[0;34m
NC     = \033[0m

.PHONY: all build release test app-bundle sign dmg notarize staple verify \
        install-cli install-cli-unsigned package check-signing-env \
        list-identities clean help

# ---------------------------------------------------------------------------
# Default
# ---------------------------------------------------------------------------

all: help

# ---------------------------------------------------------------------------
# Development
# ---------------------------------------------------------------------------

build:
	@echo "$(BLUE)Building (debug)...$(NC)"
	@swift build
	@echo "$(GREEN)✓ Build complete$(NC)"

test:
	@echo "$(BLUE)Running tests (clean build)...$(NC)"
	@swift package clean
	@swift test
	@echo "$(GREEN)✓ Tests passed$(NC)"

release:
	@echo "$(BLUE)Building universal release binaries (arm64 + x86_64)...$(NC)"
	@swift build -c release --arch arm64 --arch x86_64
	@echo "$(GREEN)✓ Release build complete$(NC)"

# ---------------------------------------------------------------------------
# App bundle
# ---------------------------------------------------------------------------

app-bundle: release
	@echo "$(BLUE)Assembling LogDeck.app bundle...$(NC)"
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_MACOS_DIR)" "$(APP_RESOURCES_DIR)"
	@cp "$(GUI_BINARY)" "$(APP_MACOS_DIR)/LogDeck"
	@chmod 755 "$(APP_MACOS_DIR)/LogDeck"
	@sed 's/{{VERSION}}/$(VERSION)/g' \
		$(PACKAGING_DIR)/Info.plist.template \
		> "$(APP_BUNDLE)/Contents/Info.plist"
	@printf 'APPL????' > "$(APP_BUNDLE)/Contents/PkgInfo"
	@echo "$(GREEN)✓ App bundle assembled: $(APP_BUNDLE)$(NC)"

# ---------------------------------------------------------------------------
# Signing
# ---------------------------------------------------------------------------

check-signing-env:
	@if [ -z "$(APP_SIGNING_CERT)" ]; then \
		echo "$(RED)✗ APP_SIGNING_CERT not set$(NC)"; \
		echo "$(YELLOW)  Create a .env file (see .env.example) or export the variable$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(NOTARY_PROFILE)" ]; then \
		echo "$(RED)✗ NOTARY_PROFILE not set$(NC)"; \
		echo "$(YELLOW)  Create a .env file (see .env.example) or export the variable$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(TEAM_ID)" ]; then \
		echo "$(RED)✗ TEAM_ID not set$(NC)"; \
		echo "$(YELLOW)  Create a .env file (see .env.example) or export the variable$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Signing configuration validated$(NC)"

sign: check-signing-env app-bundle
	@echo "$(BLUE)Signing CLI binary...$(NC)"
	@codesign --force --sign "$(APP_SIGNING_CERT)" \
		--options runtime \
		--timestamp \
		--entitlements "$(PACKAGING_DIR)/entitlements/cli.entitlements" \
		--identifier "$(BUNDLE_ID_CLI)" \
		"$(CLI_BINARY)"
	@echo "$(GREEN)✓ CLI binary signed$(NC)"

	@echo "$(BLUE)Signing app bundle...$(NC)"
	@codesign --force --sign "$(APP_SIGNING_CERT)" \
		--options runtime \
		--timestamp \
		--entitlements "$(PACKAGING_DIR)/entitlements/app.entitlements" \
		--identifier "$(BUNDLE_ID_APP)" \
		"$(APP_BUNDLE)"
	@codesign --verify --deep --strict "$(APP_BUNDLE)"
	@echo "$(GREEN)✓ App bundle signed$(NC)"

# ---------------------------------------------------------------------------
# DMG
# ---------------------------------------------------------------------------

dmg: sign
	@echo "$(BLUE)Creating DMG...$(NC)"
	@rm -rf "$(DMG_STAGING)"
	@mkdir -p "$(DMG_STAGING)" "$(DIST_DIR)"
	@cp -R "$(APP_BUNDLE)" "$(DMG_STAGING)/"
	@cp "$(CLI_BINARY)" "$(DMG_STAGING)/logdeck"
	@ln -s /Applications "$(DMG_STAGING)/Applications"
	@hdiutil create \
		-volname "LogDeck $(VERSION)" \
		-srcfolder "$(DMG_STAGING)" \
		-ov \
		-format UDZO \
		"$(DMG_OUTPUT)"
	@codesign --force --sign "$(APP_SIGNING_CERT)" \
		--timestamp \
		"$(DMG_OUTPUT)"
	@echo "$(GREEN)✓ DMG created and signed: $(DMG_OUTPUT)$(NC)"

# ---------------------------------------------------------------------------
# Notarize
# ---------------------------------------------------------------------------

notarize: dmg
	@echo "$(BLUE)Submitting DMG to notarization service (may take a few minutes)...$(NC)"
	@xcrun notarytool submit "$(DMG_OUTPUT)" \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	@echo "$(BLUE)Stapling notarization ticket...$(NC)"
	@xcrun stapler staple "$(DMG_OUTPUT)"
	@echo "$(GREEN)✓ DMG notarized and stapled$(NC)"

# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

verify:
	@echo "$(BLUE)Verifying signatures and notarization...$(NC)"
	@echo ""
	@if [ -d "$(APP_BUNDLE)" ]; then \
		echo "App bundle:"; \
		codesign -dvvv "$(APP_BUNDLE)" 2>&1 | grep -E "Authority|Identifier|Runtime|flags"; \
		spctl --assess --type exec "$(APP_BUNDLE)" \
			&& echo "$(GREEN)  ✓ Passes Gatekeeper$(NC)" \
			|| echo "$(RED)  ✗ Fails Gatekeeper$(NC)"; \
		echo ""; \
	fi
	@if [ -f "$(CLI_BINARY)" ]; then \
		echo "CLI binary:"; \
		codesign -dvvv "$(CLI_BINARY)" 2>&1 | grep -E "Authority|Identifier|Runtime|flags"; \
		echo ""; \
	fi
	@if [ -f "$(DMG_OUTPUT)" ]; then \
		echo "DMG:"; \
		xcrun stapler validate "$(DMG_OUTPUT)" \
			&& echo "$(GREEN)  ✓ Notarization stapled$(NC)" \
			|| echo "$(RED)  ✗ Not notarized$(NC)"; \
	fi

# ---------------------------------------------------------------------------
# Full release pipeline
# ---------------------------------------------------------------------------

package: check-signing-env notarize verify
	@echo ""
	@echo "$(GREEN)✓ Release ready: $(DMG_OUTPUT)$(NC)"

# ---------------------------------------------------------------------------
# Local install helpers
# ---------------------------------------------------------------------------

install-cli: release sign
	@echo "$(BLUE)Installing logdeck to /usr/local/bin...$(NC)"
	@sudo cp "$(CLI_BINARY)" /usr/local/bin/logdeck
	@echo "$(GREEN)✓ logdeck installed$(NC)"
	@logdeck --help

install-cli-unsigned: release
	@echo "$(BLUE)Installing logdeck (unsigned) to /usr/local/bin...$(NC)"
	@sudo cp "$(CLI_BINARY)" /usr/local/bin/logdeck
	@sudo xattr -d com.apple.quarantine /usr/local/bin/logdeck 2>/dev/null || true
	@echo "$(GREEN)✓ logdeck installed (unsigned)$(NC)"

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

list-identities:
	@echo "Developer ID Application certificates:"
	@security find-identity -v -p codesigning | grep "Developer ID Application" || echo "  None found"
	@echo ""
	@echo "Notarytool profiles (stored credentials):"
	@xcrun notarytool store-credentials --list 2>/dev/null || echo "  Use: xcrun notarytool store-credentials"

clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR) $(DIST_DIR) || true
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
	@printf "  $(BLUE)%-24s$(NC) %s\n" "build"                "Debug build (all targets)"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "release"              "Universal release build (arm64 + x86_64)"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "test"                 "Run tests (clean build)"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "app-bundle"           "Assemble LogDeck.app from release binary"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "sign"                 "Sign app bundle + CLI binary"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "dmg"                  "Create and sign DMG"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "notarize"             "Notarize and staple DMG"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "package"              "Full pipeline: sign → dmg → notarize → verify"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "verify"               "Verify signatures and notarization"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "install-cli"          "Install logdeck to /usr/local/bin (signed)"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "install-cli-unsigned" "Install logdeck to /usr/local/bin (dev)"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "list-identities"      "Show available signing certificates"
	@printf "  $(BLUE)%-24s$(NC) %s\n" "clean"                "Remove all build artifacts"
	@echo ""
	@echo "Configuration (set in .env or environment):"
	@printf "  %-22s %s\n" "APP_SIGNING_CERT"  "$(or $(APP_SIGNING_CERT),<not set>)"
	@printf "  %-22s %s\n" "NOTARY_PROFILE"    "$(or $(NOTARY_PROFILE),<not set>)"
	@printf "  %-22s %s\n" "TEAM_ID"           "$(or $(TEAM_ID),<not set>)"
	@printf "  %-22s %s\n" "VERSION"           "$(VERSION)"
	@echo ""
	@echo "Examples:"
	@echo "  make build                   # Local development"
	@echo "  make test                    # Run test suite"
	@echo "  make install-cli-unsigned    # Quick install for testing"
	@echo "  make package                 # Full signed + notarized release"
