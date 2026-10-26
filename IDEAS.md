# Ideas / backlog

One item per commit, ordered by value/effort. Check items off as they land.

## Quick wins

- [x] **Actionable `btl` when Bluetooth is off**
  Today `btl` lists cached paired devices with everything looking disconnected. Return a
  single item — `Bluetooth is off — press ⏎ to turn it on` — with `arg: "turn-on"`.
  The plist already has a dormant conditional for `turn-on` → `TurnBtOnCommand`, so this
  is mainly `ListBtDevicesCommand` (check `isBluetoothOn()` before enumerating).

- [x] **Subtitle fallback**
  With MAC addresses hidden by default, devices without a battery render an empty
  subtitle. Fall back to `Connected` / `Disconnected` (optionally device type, see below).

- [x] **Live refresh of the list**
  Add `"rerun": 2` to the Script Filter response so connection states update while the
  list is open (e.g. after connecting a device from System Settings). Extend
  `returnResult(items, rerun)`.

## Quality of life

- [x] **Filter by MAC address**
  `btl <address>` should match a device even when addresses are hidden.

- [x] **Stale item handling**
  If the selected device no longer exists, `toggle` returns Script Filter JSON from a Run
  Script action, which is invisible. Send a notification instead (respecting the
  notification setting).

- [x] **Diagnostics keyword**
  `btdiag`: copies the workflow/Alfred/macOS versions, permission, power state, current
  settings and paired devices (Classic/BLE, connected state, battery). Hold `⌥` to copy
  a redacted version without device names.

- [x] **Configurable keyword**
  Text settings for the list, turn-on, turn-off and toggle keywords (defaults
  `btl`/`bton`/`btoff`/`btt`), so users can resolve keyword conflicts without editing
  the workflow.

- [x] **`btt` toggle-power keyword**
  `btt` toggles Bluetooth power, backed by a `toggle-power` external trigger (URL/AppleScript)
  documented in the README.

## Personalization

- [x] **Favorites**
  Star devices and surface them in the list.
  - Indicator: a star (⭐) prefixed to the device name in `btl`.
  - Sorter: new `Favorites first` option in the Sorting dropdown.
  - Storage: the `favorites` workflow configuration item (a textarea, one device
    name per line), written with Alfred's `set configuration`. Users can unstar by
    deleting a line in Configure Workflow; names are matched case-insensitively.
  - Toggle: `⌥⏎` on a list item adds/removes a favorite.
  - Note: an ignore list could use the same mechanism with its own config variable.

- [ ] **Ignore list**
  Hide specific devices from the `btl` output.
  - Modifier key on a list item (e.g. `⌘⏎`) adds the device to the ignore list; ignored
    devices are filtered out before sorting and battery work.
  - Un-hide path is required: another modifier to toggle, a `Show ignored devices`
    pseudo-item, or a config field listing ignored addresses.
  - Storage: shared with favorites, e.g. `settings.json` with
    `{ "<address>": { "favorite": true, "ignored": false } }`.
  - Precedence: ignored wins over favorite (hidden anyway).
  - Note: actions currently travel as the item `arg` (device name) and are dispatched by
    the `turn-on` / permission magic strings in `info.plist`. Modifier actions should
    introduce a small explicit action protocol (e.g. an arg object or Alfred variables)
    instead of adding more magic prefixes.

## Bigger bets

- [ ] **BLE battery levels**
  macOS shows battery for the MX Master 3S / Keychron K3 Max, but IOBluetooth battery
  getters return 0 and `system_profiler` has no battery entry for them. Research paths:
  private `bluetoothd` XPC, CoreBluetooth Battery service (`0x180F`) via a personal
  connection, Logitech HID++, or whatever apps like Battery/Stats use.

- [x] **Device-type icons**
  Type-specific SF Symbol icons (keyboard, mouse, trackpad, headphones, etc.) plus
  dedicated AirPods, Magic device, MX Master and Keychron icons. Device-specific
  overrides live in `assets/icons/map.json`, keyed by vendor/product ID; connection
  state moved to the subtitle. Icons are generated with `tools/generate_icons.swift`.

- [x] **Pair unpaired devices**
  `btpair` runs one Classic inquiry, lists the unpaired devices it found and pairs
  the selected one with `IOBluetoothDevicePair` (the same approach as
  `blueutil --pair`), then connects it. Secure Simple Pairing confirmation and
  passkey prompts are shown with `displayDialog`. Scan results are cached for a
  few seconds because a Script Filter invocation cannot keep an inquiry alive and
  restarting it on every keystroke never lets devices answer. Not supported:
  Bluetooth LE peripherals (no public pairing API; CoreBluetooth exposes per-Mac
  UUIDs, not addresses) and legacy PIN pairing (the reply needs a pointer to a
  `BluetoothPINCode` struct, which JXA cannot build).

- [x] **Unpair device**
  Modifier key + confirmation, using the private `remove` selector (same approach as
  blueutil). Destructive, so the UX needs care. Landed as `⌃⏎` on a `btl` item: routes
  to a confirmation Script Filter, then the `unpair` command verifies the device left
  the paired list.

## Explicitly skipped

- **Disconnect all**: risky with a Bluetooth keyboard/mouse, and BLE devices cannot be
  disconnected by third-party apps anyway.
