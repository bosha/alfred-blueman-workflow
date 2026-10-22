# Releasing

How a new version reaches users through the [Alfred Gallery](https://alfred.app/).

## How updates work

- Alfred identifies the workflow by its **bundle id** (`com.bosha.alfred.blueman`). Any installed copy — even one side-loaded from a GitHub release — is recognised as the same workflow and tracks the Gallery.
- Alfred compares the installed **version** (the `version` field in `info.plist`, exposed as `alfred_workflow_version`) with the version the Gallery has published for that bundle id.
- When the Gallery version is higher, Alfred Preferences → Workflows shows an up arrow; the user right-clicks → **Update from the Alfred Gallery**.
- The Gallery serves its **own copy** of the workflow (from `github.com/alfredapp/gallery-workflows`), not this repository. Changing this repo alone updates nothing for users — the Gallery copy is updated through the submission process below.
- Submitted updates appear in the Gallery **after ~1–2 days** by design.
- The version inside the submitted bundle must match the version you submit, and Gallery workflows must not self-update.

## Release checklist

1. Make sure everything is committed and merged into the branch the Gallery tracks (`master`).
2. Bump, build and tag:
   ```shell
   make release VERSION=0.2
   ```
   This sets `version` in `info.plist`, builds `dist/Blueman.alfredworkflow`, commits the bump (`release: 0.2`) and creates the annotated tag `v0.2`. It refuses to run on a dirty tree, a non-semver version, an unchanged version, or an existing tag.
3. Push the commit and tag:
   ```shell
   git push && git push --tags
   ```
4. Create a GitHub release for the tag and attach the bundle:
   ```shell
   gh release create v0.2 dist/Blueman.alfredworkflow \
     --title "Blueman 0.2" --notes "<changelog>"
   ```
5. Submit the update to the Gallery by opening an issue on
   [`alfredapp/gallery-edits`](https://github.com/alfredapp/gallery-edits/issues/new?template=02_update_workflow.yml)
   using the **Update Existing Workflow** template:
   - **Gallery URL**: `https://alfred.app/workflows/bosha/blueman/`
   - **New Version**: `0.2`
   - **Changelog**: a short markdown list of changes.
6. If usage changed, also update `readme.md` and `images/` under `workflows/bosha/blueman/` in `alfredapp/gallery-edits`.
7. The Alfred team copies the bundle into the Gallery; users see the update arrow once it is published (usually within 1–2 days).

## Notes

- Keep the bundle id stable — it is the update identity.
- Gallery updates replace the workflow wholesale, so user customizations are lost (expected).
- `make package` builds the bundle without touching the version or git.
