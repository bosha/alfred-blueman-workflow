# Copy the runtime files into the installed Alfred workflow for manual testing.

WORKFLOW_BUNDLE_ID := $(shell /usr/libexec/PlistBuddy -c 'Print :bundleid' info.plist 2>/dev/null)
ALFRED_PREFS ?= $(shell /usr/bin/plutil -extract current raw -o - "$(HOME)/Library/Application Support/Alfred/prefs.json" 2>/dev/null)
DEV_WORKFLOW ?= $(shell for p in "$(ALFRED_PREFS)"/workflows/user.workflow.*; do \
	id=$$(/usr/libexec/PlistBuddy -c 'Print :bundleid' "$$p/info.plist" 2>/dev/null); \
	if [ "$$id" = "$(WORKFLOW_BUNDLE_ID)" ]; then echo "$$p"; break; fi; \
done)

.PHONY: dev-sync

# Older workflow objects still call ./bt_manager.jxa; keep that entry point in
# sync when the installed workflow already has one.
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
	@if [ -f "$(DEV_WORKFLOW)/bt_manager.jxa" ]; then \
		cp src/bt_manager.jxa "$(DEV_WORKFLOW)/bt_manager.jxa"; \
	fi
	@cp info.plist "$(DEV_WORKFLOW)/info.plist"
	@cp icon.png "$(DEV_WORKFLOW)/icon.png"
	@cp assets/icons/*.png assets/icons/map.json "$(DEV_WORKFLOW)/assets/icons/"
	@echo "Synced runtime files to $(DEV_WORKFLOW)"
