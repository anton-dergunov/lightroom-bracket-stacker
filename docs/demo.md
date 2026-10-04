# Reshooting the demo

The demo at the top of the README is a slideshow of stills taken from a screen recording: a few keyframes, each shown
for about three seconds. Because only the keyframes are used, the recording needs no editing. If a step goes wrong
while recording, do it again and carry on.

The script needs `ffmpeg`, ImageMagick, `img2webp` and `gifski` (`brew install ffmpeg imagemagick webp gifski`).

## 1. Prepare Lightroom Classic

- Use a catalog without the demo photos, and a folder of photos that can be shown publicly. `sh tests/photos/fetch.sh`
  downloads such a folder.
- Make the Lightroom window 1536 x 960 points and put it at the top left of the screen. On a Retina display that
  records as 3072 x 1920 pixels, which is 16:10:

  ```sh
  osascript -e 'tell application "System Events" to tell process "Adobe Lightroom Classic" to tell window 1
      set position to {0, 25}
      set size to {1536, 960}
  end tell'
  ```

  The first time, macOS asks to let the terminal control the computer (System Settings > Privacy & Security >
  Accessibility).
- Dialogs open in the middle of the screen, not of the window. On a wide monitor, drag each dialog over the Lightroom
  window before going on; only the frame after the move is used.

## 2. Record

Press Cmd+Shift+5, choose **Record Selected Portion**, and drag the selection over the Lightroom window including the
menu bar above it. Then go through the steps, pausing for a second after each one:

1. Open **Library > Plug-in Extras** and point at the import command.
2. Choose the folder.
3. The confirmation dialog showing what the plugin found.
4. The summary after the import.
5. The grid with the imported stacks expanded.
6. **Photo > Stacking > Collapse All Stacks**.
7. Select the stacks and open **Photo > Photo Merge > HDR**.
8. The grid with the HDR images on their stacks.

## 3. Choose the keyframes

```sh
sh tools/make-demo.sh --sheet recording.mov          # one frame per second
sh tools/make-demo.sh --sheet recording.mov 20 24    # four per second, between 0:20 and 0:24
```

This writes contact sheets, every frame labelled with its time in the recording. Pick the time of one frame per step
and list them in [assets/demo-frames.txt](../assets/demo-frames.txt), each with the number of seconds to show it.
The same file sets the crop, when the recording is larger than the window, and the areas to blur.

## 4. Build

```sh
sh tools/make-demo.sh recording.mov
```

It writes `assets/demo.webp`, which the README shows, and `assets/demo.gif` for sites that do not accept animated
WebP, such as Medium. To change the timing, a keyframe or a blurred area, edit `assets/demo-frames.txt` and run it
again.
