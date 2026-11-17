# mochi

A soft, rounded SDDM theme in the style of Pixel and Material 3 Expressive.

- **Center clock** with 7 type styles. Click the clock or the `Tт` chip to cycle through them: *Flex* (stacked Google Sans Flex), *Squishy* (bubbly Fredoka; digits squash, stretch and breathe), *Mono*, *Dots* (rounded dot-matrix Doto), *Serif*, *Thin* and *Wide*. Every digit animates when it changes, and the clock fades away when the login screen opens.
- **Material You colors** taken from your wallpaper when the greeter starts: the image is sampled, a seed hue is picked by chroma-weighted scoring, and a full tonal scheme (primary/secondary/tertiary/surfaces/error) is built in OKLCH. Six variants are available, plus an optional fixed accent color.
- **Date** at the top left, **session picker + sleep / restart / shut down** at the bottom right.
- **Press any key** (or click) and the whole screen becomes the login view: the wallpaper blurs and dims, the clock disappears, and the controls float directly on the blur (no window or card). The user selector sits on the left: a profile picture in a slowly rotating *cookie* shape, with other users below it (use ↑/↓ to switch). The password field is on the right; each typed character pops in as a random rounded shape. A wrong password shakes the field and turns it red, and the avatar morphs to a circle.
- Motion uses springy emphasized curves throughout: the wallpaper zooms and blurs, the two halves of the login view slide in, and buttons morph from round to rounded-square on hover and squish when pressed.

## Requirements

- SDDM ≥ 0.20 built with Qt 6 (`sddm-greeter-qt6`)
- Qt ≥ 6.7 (`qt6-declarative`; uses variable font axes, `MultiEffect`, `Shapes`)

## Install

```bash
./install.sh                                   # install + enable
./install.sh -w ~/Pictures/wall.jpg -a ~/me.png  # with your wallpaper and profile picture
./install.sh -c squishy -v vibrant --12h       # pick the clock style, color variant and 12h time
./install.sh --test -w ~/Pictures/wall.jpg     # preview in a window without installing anything
./install.sh --uninstall
```

The script copies the theme to `/usr/share/sddm/themes/mochi`, downloads the fonts into `fonts/` (all OFL, plus Apache-2.0 Material Symbols), saves your options in `theme.conf.user`, sets the avatar through AccountsService and `/usr/share/sddm/faces`, and enables the theme in `/etc/sddm.conf.d/zz-mochi-theme.conf`. Run it again any time to change something; earlier options are kept. Without the downloaded fonts, mochi falls back to installed system fonts.

To preview by hand, use `sddm-greeter-qt6 --test-mode --theme ./mochi`. The plain `sddm-greeter` binary is the Qt 5 greeter and can't load this theme (it fails with "Library import requires a version"). The real SDDM picks the Qt 6 greeter automatically because `metadata.desktop` says `QtVersion=6`.

Note: the test preview runs fullscreen and takes keyboard focus. Press Esc to go back to the lock view, and close the window with your compositor's close-window keybind.

## Configure

Edit `theme.conf` (or better, `theme.conf.user`) in the installed theme folder:

| key | values |
|---|---|
| `background` | path relative to the theme, or absolute (must be readable by the `sddm` user) |
| `accentColor` | empty = from the wallpaper, or `#rrggbb` |
| `colorVariant` | `tonalspot` `vibrant` `expressive` `fidelity` `neutral` `monochrome` |
| `colorMode` | `dark` `light` |
| `clockStyle` | `flex` `squishy` `mono` `dots` `serif` `thin` `wide` |
| `clockStyles` | comma list limiting which styles the clock cycles through |
| `clockFormat` | `24h` `12h` |
| `dateFormat` | Qt date format; keep the quotes if it contains a comma |
| `avatarShape` | `cookie` `flower` `circle` `squircle` |
| `idleTimeout` | seconds until an empty login screen goes back to the lock view (0 = never) |
| `dimLevel`, `blur` | wallpaper dimming, and blur strength on the login screen, 0–1 |
| `animationSpeed` | 1.0 = normal, 2.0 = twice as fast |
| `font` | override the UI font family |
| `showHostname`, `showStyleButton` | `true` / `false` |

The clock style you pick by clicking only lasts for that session, because the greeter can't write to its config. Use `clockStyle` to set the default.

## Layout

```
Main.qml                  screen, states, wallpaper sampling, key handling
components/Theme.qml      color roles, fonts, motion tokens (singleton)
components/Colors.js      OKLCH tonal scheme + wallpaper seed extraction
components/Clock.qml      styles + layout;  Digit.qml animates one glyph
components/LoginPanel.qml user selector + password;  Avatar.qml, PasswordField.qml
components/PowerBar.qml   session chip/menu + power buttons
```
