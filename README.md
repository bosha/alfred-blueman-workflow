# Alfred Workflow for Controlling Bluetooth Connection

This workflow enables you to manage your Bluetooth device connections and Bluetooth state directly from Alfred.

## Features

- Lists every paired Bluetooth device with a type-specific icon (keyboard, mouse, trackpad, headphones, speaker, phone, tablet, watch, game controller, computer) and dedicated icons for AirPods, Magic devices, the Logitech MX Master lineup and Keychron.
- Shows connection state and battery levels, including separate AirPods left/right/case levels. Battery glyphs use [SF Symbols](https://developer.apple.com/sf-symbols/) when Apple's SF Pro font is installed, with an emoji fallback (configurable).
- Connects and disconnects devices, and unpairs them behind a confirmation (experimental).
- Stars favorites and hides ignored devices with modifier actions, stored in editable configuration fields.
- Sorts by Alfred's learned order, favorites, connection state, alphabetically, or the macOS order.
- Filters by device name, and by MAC address when addresses are shown; ignored devices reappear in search so they can be un-ignored.
- Refreshes the list while it is open, so connection and battery states stay current.
- Turns Bluetooth on, off or toggles it, with configurable keywords and a `toggle-power` external trigger for other apps.
- Handles the edge cases visibly: a single actionable item when Bluetooth is off, a notification when a selected device has disappeared, and guidance when the Bluetooth permission is missing.
- Copies a diagnostics report (`btdiag`), optionally redacted with `⌥`.
- Requires no third-party dependencies — only built-in macOS tools (JXA plus `system_profiler`).

Compared to other workflows such as [alfred_bluetooth_controller](https://github.com/vegardinho/alfred_bluetooth_controller/), this one:

- Utilizes only built-in macOS tools: JavaScript for Automation (JXA) plus `system_profiler` for Bluetooth LE device type detection. No third-party dependencies, additional interpreters or external libraries.
- Does not require third-party external programs like 'blueutil'.
- Leverages native JXA bridges and MacOS APIs. The built-in `system_profiler` is invoked only when the device list contains LE devices.

## Compatibility

I initially developed this workflow for Alfred 4 and it should work seamlessly with both versions 4 and 5. I don't currently have access to Alfred 4, so cannot ensure full compatibility.

Regarding MacOS version and devices: This workflow functions perfectly on my MacBook Air (M1 chip), the latest MacOS versions, and should operate without issue on any M-based Mac. Compatibility with older non-M chips is unverified. Feel free to report bugs or submit pull requests.

## Screenshots

![List bluetooth devices](assets/readme/screenshot_list.png)
![Filter bluetooth devices by name](assets/readme/screenshot_list_filter.png)
![Turn bluetooth on](assets/readme/screenshot_turn_on.png)
![Turn bluetooth off](assets/readme/screenshot_turn_off.png)

## Installation

1. Download the latest workflow from the 'Releases' page.
2. Double-click the downloaded file to install it.
3. When you first try to use the workflow, you will be prompted for access to the scripting engine. Grant permission to allow the workflow to function properly.
4. Set up your desired keyboard shortcuts (if any).
5. Begin using it.

## Development

To copy the runtime script, workflow metadata and icons into the installed Alfred workflow for manual testing:

```shell
make dev-sync
```

The target finds the installed workflow from Alfred's current preferences by bundle ID. If the workflow is installed elsewhere, override the destination:

```shell
make dev-sync DEV_WORKFLOW="/path/to/user.workflow..."
```

To build a distributable bundle and cut a release (`make package` / `make release`), see [RELEASING.md](RELEASING.md).

## Commands

- **btl**: Displays a list of all paired Bluetooth devices and their connection status. The keyword is configurable in the workflow settings.
  - Type to filter by device name, or by MAC address when addresses are shown.
  - The list refreshes every two seconds while it is open.
  - If Bluetooth is off, the list shows a single item that turns it on.
  - Hold `⌥` (Option) and press `⏎` to star a favorite.
  - Hold `⌘` (Command) and press `⏎` to ignore or unignore a device.
  - Hold `⌃` (Control) and press `⏎` to unpair a device (**experimental**).
- **bton**: Turns on Bluetooth on your device.
- **btoff**: Turns off Bluetooth on your device.
- **btt**: Toggles Bluetooth on or off.
- **btdiag**: Copies a diagnostics report for issue reports. Hold Option (`⌥`) to copy a redacted version without device names.

### External trigger

`toggle-power` toggles Bluetooth and can be called from other apps or workflows:

```shell
open -b "com.runningwithcrayons.Alfred" "alfred://runtrigger/com.bosha.alfred.blueman/toggle-power"
```

or from AppleScript:

```applescript
tell application "Alfred 5" to run trigger "toggle-power" in workflow "com.bosha.alfred.blueman"
```

## Troubleshooting

If you are reporting an issue, run `btdiag` first and paste the copied report into the issue. It includes the workflow, Alfred and macOS versions, Bluetooth permission and power state, current settings, and paired devices.

### Bluetooth permission (macOS Sonoma 14 and newer)

Starting with macOS Sonoma (14), access to the IOBluetooth framework is gated by the Bluetooth privacy permission (TCC). The permission is attributed to the app that runs the workflow — Alfred — and because Alfred does not declare Bluetooth usage in its bundle, **macOS will never show a permission prompt**: the workflow just silently misbehaves (device connection status missing in the list, power toggle and connect/disconnect doing nothing).

Grant the permission manually:

1. Open `System Settings -> Privacy & Security -> Bluetooth`
2. Press the ➕ button and add the Alfred you are using (e.g. `Alfred 5.app` from `/Applications`)
3. Make sure the toggle next to Alfred is enabled

If the workflow worked before and broke right after a macOS upgrade, the grant may have been scrambled by the upgrade. Reset it and grant again:

```shell
tccutil reset All com.runningwithcrayons.Alfred
```

When the permission is missing the workflow detects it and points you to these settings — either with an actionable item in the `btl` list or with a notification for `bton`/`btoff`/toggle — instead of silently showing an empty device list.

### Disconnecting devices

Disconnecting works for devices connected over Bluetooth Classic — most keyboards, trackpads, mice, headphones and speakers.

It does not work for Bluetooth LE devices, for example the Logitech MX Master 3S or Keychron K3 Max (shown as `HID BLE` in System Information). Such devices are connected and kept connected by the system's HID stack, and there is no public API for a third-party app to drop that link: [`IOBluetoothDevice.closeConnection()`](<https://developer.apple.com/documentation/iobluetooth/iobluetoothdevice/closeconnection()>) only closes Classic baseband connections, while [`CBCentralManager.cancelPeripheralConnection()`](<https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/cancelperipheralconnection(_:)>) only cancels the app's own local connection — Apple notes that the physical link may stay up because other apps are connected.

The same limitation affects other tools: [blueutil #110](https://github.com/toy/blueutil/issues/110) reports the same MX Master 3S being invisible to its Classic-only scan, [#79](https://github.com/toy/blueutil/issues/79) reports a BLE keyboard missing from its device list, and the long-running disconnect thread [#58](https://github.com/toy/blueutil/issues/58) contains the failing Logitech reports. Use Control Center -> Bluetooth -> device -> Disconnect instead.

The workflow detects LE devices and reports that disconnecting them is not supported, instead of failing silently. For Classic devices it verifies that the connection actually dropped and reports an error when it did not.

### Unpairing devices (experimental)

Hold `⌃` (Control) and press `⏎` on a device in the `btl` list, then confirm. Unpairing removes the device from the system's paired list, so you will have to pair it again to use it.

This is a destructive, best-effort operation:

- It requires Bluetooth to be on and uses the private `IOBluetoothDevice` `remove` selector — the same approach as [blueutil](https://github.com/toy/blueutil), which marks its own `--unpair` as experimental. Not every device responds to it; when it does not, the workflow reports that unpairing is not supported for that device.
- Because the call is asynchronous, the workflow verifies that the device actually disappeared from the paired list and reports an error when it did not.
- Bluetooth LE devices (for example the Logitech MX Master 3S or Keychron K3 Max) may not support removal at all. If you cannot unpair a device from the list, use `System Settings -> Bluetooth -> device -> Forget This Device`.

### Favorites

Hold `⌥` (Option) and press `⏎` on a device in the `btl` list to star or unstar it. Starred devices show a `⭐` next to their name; pick a favorites sorting option (see Settings) to bring them to the top.

Favorites are stored in the workflow's **Favorites** configuration field (Workflow -> Configure Workflow...), one device name per line. To unstar a device without using the list, delete its line there.

### Ignoring devices

Hold `⌘` (Command) and press `⏎` on a device in the `btl` list to hide it. Ignored devices are filtered out before sorting, so they disappear from `btl` (and from any favorites sorting).

To bring one back, type part of its name in `btl`: ignored devices reappear with a `🚫` next to their name, and `⌘⏎` un-ignores them. Ignored devices are stored in the workflow's **Ignored devices** configuration field (Workflow -> Configure Workflow...), one device name per line — delete a line there to un-ignore without the list.

A device that is both starred and ignored stays hidden (ignoring wins); if you reveal it through a search it shows both the `⭐` and `🚫` markers.

## Settings

The workflow exposes eleven configuration parameters in Alfred (Workflow -> Configure Workflow...):

- **List keyword** — keyword used to open the device list (default `btl`).
- **On keyword** — keyword used to turn Bluetooth on (default `bton`).
- **Off keyword** — keyword used to turn Bluetooth off (default `btoff`).
- **Toggle keyword** — keyword used to toggle Bluetooth on or off (default `btt`).
- **Favorites** — starred devices, one name per line (see above).
- **Ignored devices** — devices hidden from the `btl` list, one name per line (see above). Type in `btl` to reveal one and un-ignore it.
- **Sorting** — order of devices in the `btl` list. The order within each group is preserved.
  - `Alfred's order` (default) — no sorting; Alfred orders devices by the ones you use most.
  - `Favorites, then connected` — starred devices first, then connected devices, then the rest.
  - `Favorites first` — starred devices at the top.
  - `Connected first` — connected devices at the top.
  - `Alphabetical` — sorted by device name.
  - `Default` — keeps the macOS order.
- **MAC addresses** — show device addresses in the `btl` list (off by default). When enabled, the list can also be filtered by address; when disabled, only device names are matched.
- **Battery icons** — `Auto` (default), `SF Symbols`, or `Emoji`. AirPods left/right/case levels and other battery readings use SF Symbols glyphs when available; `Auto` uses them only when Apple's SF Pro font is installed, otherwise it falls back to emoji.
- **Notifications** — `On` (default), `Only errors`, or `Off`.
- **Logging Level** — defaults to `Info`. Useful only for development purposes.

### Battery icons

Battery levels are shown either with emoji or with [SF Symbols](https://developer.apple.com/sf-symbols/) glyphs. The glyphs live in Apple's **SF Pro** font, which is not installed by default: install it from [developer.apple.com/fonts](https://developer.apple.com/fonts/) and the **Battery icons** setting set to `Auto` starts using the SF Symbols variants for AirPods left/right/case and for level-based battery readings. Without the font the workflow falls back to emoji; set the setting to `Emoji` to force the fallback or `SF Symbols` to force the glyphs.

## Device icons

Device rows use type-specific icons for keyboards, mice, trackpads, headphones, speakers, phones, tablets, watches, game controllers and computers. AirPods, Magic Mouse/Keyboard/Trackpad, the Logitech MX Master lineup and Keychron devices have dedicated icons. Connected devices use the blue icon; disconnected devices use a muted gray `_off` variant so the connection state is visible at a glance.

Every icon is drawn with a dark rim around the glyph. Alfred has no per-state icon and draws the same PNG on the theme background and on the selected row: the rim disappears on dark themes, and on light backgrounds or a saturated selection colour (the blue highlight most themes use) it keeps the glyph readable without borrowing the colour of the row text. Icons are generated at 256×256 px, four times the size Alfred draws them at.

Specific-device overrides are data-driven, so adding an icon does not require code changes:

1. Add a 512×512 PNG to `assets/icons/` (transparent background). The base name is used for connected devices; disconnected devices use `<name>_off.png` when it exists, otherwise the base icon.
2. Add a mapping entry to `assets/icons/map.json`.

Mapping keys are `vendor_id:product_id` in four-digit lowercase hexadecimal, without `0x`. A `vendor_id:*` entry applies to every product from that vendor. Icon names may contain lowercase letters, digits and underscores.

```json
{
  "004c:0269": "magic_mouse",
  "046d:b034": "mx_master",
  "3434:*": "keychron"
}
```

The value is the base icon file name without `.png`. The workflow checks the specific product first, then the vendor wildcard. Device IDs are shown in System Information -> Bluetooth. If no mapping matches, the icon is selected from the device type (Classic Class of Device or `system_profiler` minor type), with a device-name fallback.

The bundled generator creates both the blue base icon and the gray `_off` variant for every entry in `specs`. For a manually added icon, include both `<name>.png` and `<name>_off.png` to keep the state distinction.

To regenerate the bundled icons from SF Symbols, run:

```shell
xcrun swift tools/generate_icons.swift
```

Add or change entries in the `specs` array at the top of that script. BLE device types are read from the built-in `system_profiler` only when the list contains LE devices; Classic devices use their Class of Device.
