# Dev and release helpers for the installed Alfred workflow.

WORKFLOW_BUNDLE_ID := $(shell /usr/libexec/PlistBuddy -c 'Print :bundleid' info.plist 2>/dev/null)
WORKFLOW_NAME := $(shell /usr/libexec/PlistBuddy -c 'Print :name' info.plist 2>/dev/null)
CURRENT_VERSION := $(shell /usr/libexec/PlistBuddy -c 'Print :version' info.plist 2>/dev/null)
ALFRED_PREFS ?= $(shell /usr/bin/plutil -extract current raw -o - "$(HOME)/Library/Application Support/Alfred/prefs.json" 2>/dev/null)
DEV_WORKFLOW ?= $(shell for p in "$(ALFRED_PREFS)"/workflows/user.workflow.*; do \
	id=$$(/usr/libexec/PlistBuddy -c 'Print :bundleid' "$$p/info.plist" 2>/dev/null); \
	if [ "$$id" = "$(WORKFLOW_BUNDLE_ID)" ]; then echo "$$p"; break; fi; \
done)

# Gallery page for this workflow; used only in the release hints (see RELEASING.md).
GALLERY_URL ?= https://alfred.app/workflows/bosha/blueman/

DIST := dist
ARTIFACT := $(DIST)/$(WORKFLOW_NAME).alfredworkflow

.PHONY: dev-sync package release

# Copy the runtime files into the installed Alfred workflow for manual testing.
dev-sync:
	@test -n "$(DEV_WORKFLOW)" || { \
		echo "error: could not find the installed workflow" >&2; \
		echo "set DEV_WORKFLOW to the installed workflow directory" >&2; \
		exit 1; \
	}
	@test -d "$(DEV_WORKFLOW)" || { \
		echo "error: workflow not found: $(DEV_WORKFLOW)" >&2; \
		echo "set DEV_WORKFLOW to the installed workflow directory" >&2; \
		exit 1; \
	}
	@mkdir -p "$(DEV_WORKFLOW)/src" "$(DEV_WORKFLOW)/assets/icons"
	@cp src/bt_manager.jxa "$(DEV_WORKFLOW)/src/bt_manager.jxa"
	@cp info.plist "$(DEV_WORKFLOW)/info.plist"
	@cp icon.png "$(DEV_WORKFLOW)/icon.png"
	@cp README.md "$(DEV_WORKFLOW)/README.md"
	@cp assets/*.png "$(DEV_WORKFLOW)/assets/"
	@cp assets/icons/*.png assets/icons/map.json "$(DEV_WORKFLOW)/assets/icons/"
	@echo "Synced runtime files to $(DEV_WORKFLOW)"

# Build the distributable .alfredworkflow bundle. Mirrors the shipped layout:
# the workflow files plus README.md and its assets/readme screenshots.
package:
	@rm -rf "$(DIST)"
	@mkdir -p "$(DIST)/stage"
	@cp -R README.md info.plist icon.png assets src "$(DIST)/stage/"
	@cd "$(DIST)/stage" && zip -q -r "../$(WORKFLOW_NAME).alfredworkflow" README.md info.plist icon.png assets src
	@rm -rf "$(DIST)/stage"
	@echo "Built $(ARTIFACT)"

# Bump the version, build the bundle and tag the release. Requires a clean tree.
# Pushing, the GitHub release and the Gallery submission stay manual: see RELEASING.md.
release:
	@test -n "$(VERSION)" || { echo "usage: make release VERSION=0.2" >&2; exit 1; }
	@echo "$(VERSION)" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?$$' || { \
		echo "error: VERSION must look like 0.2 or 1.2.3" >&2; exit 1; }
	@test "$(VERSION)" != "$(CURRENT_VERSION)" || { \
		echo "error: info.plist is already at $(CURRENT_VERSION)" >&2; exit 1; }
	@test -z "$$(git tag -l "v$(VERSION)")" || { \
		echo "error: tag v$(VERSION) already exists" >&2; exit 1; }
	@test -z "$$(git status --porcelain --untracked-files=no)" || { \
		echo "error: working tree has uncommitted changes; commit them first" >&2; exit 1; }
	@/usr/libexec/PlistBuddy -c "Set :version $(VERSION)" info.plist
	@$(MAKE) --no-print-directory package
	@git commit -q -m "release: $(VERSION)" -- info.plist
	@git tag -a "v$(VERSION)" -m "$(WORKFLOW_NAME) $(VERSION)"
	@echo
	@echo "Released $(WORKFLOW_NAME) $(VERSION): bumped info.plist, committed and tagged v$(VERSION)."
	@echo
	@echo "Finish publishing (see RELEASING.md):"
	@echo "  1. git push && git push --tags"
	@echo "  2. gh release create v$(VERSION) \"$(ARTIFACT)\" --title \"$(WORKFLOW_NAME) $(VERSION)\" --notes \"<changelog>\""
	@echo "  3. Open the Gallery update issue:"
	@echo "     https://github.com/alfredapp/gallery-edits/issues/new?template=02_update_workflow.yml"
	@echo "     Gallery URL: $(GALLERY_URL)"
	@echo "     New Version: $(VERSION)"
