# Privacy Policy for Coffee Diary

**Last Updated:** 25 June 2026

Coffee Diary ("we", "us") is committed to protecting your data. This document is the canonical privacy policy. The public version is also published at [docs/privacy-policy.md](docs/privacy-policy.md) via GitHub Pages.

## Data We Store

- **Brew entries** — values you enter in forms (dose, yield, time, notes, ratings, etc.).
- **Equipment** — beans, grinders, machines, and brewers including optional photos.
- **Photos** — images you intentionally capture or select from your library.
- **Weather snapshots** — when you use the optional weather step during brew logging, we store temperature, humidity, a location name (city/area from reverse geocoding), and the capture timestamp on the brew entry.

We do **not** collect usage analytics, advertising IDs, or sell your data.

## Location & Third-Party Weather Service

When you enable the weather step in a brew flow, Coffee Diary:

1. Requests **when-in-use** location permission.
2. Uses your approximate coordinates to request current weather from [Open-Meteo](https://open-meteo.com/) (a free weather API).
3. Saves the resulting temperature, humidity, and location label on your brew entry.

We do not operate our own servers for weather. Coordinates are sent only to Open-Meteo to fetch weather; we do not store raw GPS coordinates separately. Open-Meteo's privacy practices apply to that request. You can skip the weather step at any time.

## Storage & Sync

- Data is stored locally on your device using SwiftData.
- Optionally, CloudKit syncs data through your personal iCloud account. We do not have access to your iCloud data.
- If iCloud is disabled, all data remains on your device only.

## Sharing

We do not share your data with third parties for advertising. The only third-party data transfer is the optional Open-Meteo weather lookup described above.

## Permissions

- **Camera** — to photograph equipment and beans.
- **Photos** — to select or save images from your library.
- **Location (when in use)** — to attach weather context to brew entries when you choose that step.

## Your Rights

- View, edit, or delete your data at any time within the app.
- Delete the app or remove iCloud entries to erase synced data.

## Contact

- Support & feedback: https://github.com/Yannik2y/CoffeeDiary/issues
- Website: https://Yannik2y.github.io/CoffeeDiary/

## Changes

We may update this policy; the date above reflects the latest revision.
