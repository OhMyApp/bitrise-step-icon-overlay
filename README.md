# Icon Overlay

This step allows printing any text on top of the app's icon in order to distinguish between different builds.

Works with both **iOS** (`.appiconset`) and **tvOS** (`.brandassets`) icons. For a tvOS
layered icon, the caption is stamped on the top-most (`Front`) layer of each `.imagestack`,
so it appears above the composited parallax icon.

Before | After
-|-
![Before](./assets/icon_no_overlay.svg) | ![After](./assets/icon_overlay.svg)

## How to use this Step

Add this step in your `bitrise.yml` and customize those values:

| Attribute | Description | Default value |
|---|---|---|
| `iconsbundle_name` | The name of your icon bundle: `.appiconset` (iOS) or `.brandassets` (tvOS) | `AppIcon.appiconset` |
| `project_location` | Folder where the project and the asset files are stored in the repository. | `.` |
| `overlay_text` | The text to print over the app icon (6 characters maximum). | `$BITRISE_GIT_COMMIT` |
| `font` | The font used for the text. | `/System/Library/Fonts/Supplemental/Arial.ttf` |

You can find an example in the `bitrise.yml` of this repository.

## How to contribute to this Step

- Open an issue
- Fork this repository and send a merge request