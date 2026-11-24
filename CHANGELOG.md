# Changelog

## Unreleased

- Setup picks the official AppImage for the computer's architecture. ARM64 (aarch64) is prepared and is offered once an official Yogurt release includes `Yogurt-linux-arm64.AppImage` and its checksum is pinned.

## 1.2.0

- Added Set up Yogurt to the disconnected panel: guided installation, tray repair and launch.
- Pinned and checksum-verified the official Linux x86-64 AppImage; no administrator access or FUSE needed.
- Preserved existing installations and backed up preferences before enabling a disabled tray icon.
- Added setup tests for downloads, existing launchers, settings preservation and concurrent changes.

## 1.1.1

- Fixed Hide meeting titles exposing upcoming calendar titles through optional native action buttons, tooltips and accessibility text.
- Kept the same native actions available under a generic Meeting action label while titles are hidden.
- Added regression coverage for calendar titles, privacy toggling and native action invocation.

## 1.1.0

- Added a labelled vector-icon toolbar for Library, Ask, Settings and Quit.
- Kept recording controls separate from an evenly spaced utility toolbar.
- Added matching icons to recording, pause, resume and stop buttons.
- Kept optional native actions accessible without a hidden More controls list.
- Added native menu translations for the new toolbar actions.
- Updated the interface preview and feature guide.

## 1.0.0

- Recording status and elapsed session time directly in the Omarchy bar.
- Start, pause, resume and finish through Yogurt's native tray controls.
- Theme-aware conversation panel with recent sessions and processing status.
- Optional meeting-title privacy mode and custom profile/launcher settings.
- Keyboard access, multi-monitor panel routing and vertical-bar support.
- Local, read-only metadata access with no additional service or network calls.
