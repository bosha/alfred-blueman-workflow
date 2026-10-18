# Alfred Workflow for Controlling Bluetooth Connection

This workflow enables you to manage your Bluetooth device connections and Bluetooth state directly from Alfred. It offers the following functionalities:

* Displays a list of all paired devices along with their connection status (connected or disconnected).
* Connects or disconnects from a paired Bluetooth device.
* Turns Bluetooth on or off for your device.

Compared to other workflows such as [alfred_bluetooth_controller](https://github.com/vegardinho/alfred_bluetooth_controller/), this one:

* Utilizes only JavaScript (JXA - JavaScript for Automations), which is included with every modern MacOS and proven to be stable enough (you all probably remember the pain when apple moved from python2 to python3, right? 😬 ). No need for additional interpreters or external libraries.
* Does not require any external programs like 'blueutil'.
* Leverages native JXA bridges and MacOS APIs, resulting in faster performance compared to workflows relying on external programs.

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

## Commands

* **btl**: Displays a list of all paired Bluetooth devices and their connection status.
* **bton**: Turns on Bluetooth on your device.
* **btoff**: Turns off Bluetooth on your device.

## Troubleshooting

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

It does not work for Bluetooth LE devices, for example the Logitech MX Master 3S or Keychron K3 Max (shown as `HID BLE` in System Information). Such devices are connected and kept connected by the system's HID stack, and there is no public API for a third-party app to drop that link: [`IOBluetoothDevice.closeConnection()`](https://developer.apple.com/documentation/iobluetooth/iobluetoothdevice/closeconnection()) only closes Classic baseband connections, while [`CBCentralManager.cancelPeripheralConnection()`](<https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/cancelperipheralconnection(_:)>) only cancels the app's own local connection — Apple notes that the physical link may stay up because other apps are connected.

The same limitation affects other tools: [blueutil #110](https://github.com/toy/blueutil/issues/110) reports the same MX Master 3S being invisible to its Classic-only scan, [#79](https://github.com/toy/blueutil/issues/79) reports a BLE keyboard missing from its device list, and the long-running disconnect thread [#58](https://github.com/toy/blueutil/issues/58) contains the failing Logitech reports. Use Control Center -> Bluetooth -> device -> Disconnect instead.

The workflow detects LE devices and reports that disconnecting them is not supported, instead of failing silently. For Classic devices it verifies that the connection actually dropped and reports an error when it did not.

## Settings

The workflow exposes two configuration parameters in Alfred (Workflow -> Configure Workflow...):

* **Sorting** — `Connected first` (default) shows connected devices at the top of the `btl` list, `Alphabetical` sorts devices by name, `Default` keeps the macOS order. The order within each group is preserved.
* **Logging Level** — defaults to `Info`. Useful only for development purposes.