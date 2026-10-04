#!/bin/sh
# Build the demo animation from a screen recording: assets/demo.webp for the README and assets/demo.gif for sites
# that only take GIF. Both are slideshows of the keyframes listed in assets/demo-frames.txt, so the recording needs
# no editing. See docs/demo.md. Needs ffmpeg, ImageMagick, img2webp and gifski.
# Usage: make-demo.sh recording.mov                      build the animations
#        make-demo.sh --sheet recording.mov [FROM TO]    contact sheets for picking keyframes: one frame per
#                                                        second, or four per second between FROM and TO (seconds)
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
spec="$root/assets/demo-frames.txt"
font=/System/Library/Fonts/Helvetica.ttc

if [ "${1:-}" = "--sheet" ]; then
    recording="$2"
    from="${3:-0}"
    to="${4:-}"
    rate=1
    [ -z "$to" ] || rate=4
    out=$(mktemp -d)
    ffmpeg -v error -ss "$from" ${to:+-to "$to"} -i "$recording" -vf "fps=$rate,scale=480:-2" "$out/frame-%04d.png"

    # Label every frame with its time in the recording, then tile 20 to a sheet.
    set --
    index=0
    for frame in "$out"/frame-*.png; do
        label=$(awk -v from="$from" -v i="$index" -v rate="$rate" \
            'BEGIN { t = from + i / rate; printf "%d:%05.2f", t / 60, t % 60 }')
        set -- "$@" -label "$label" "$frame"
        index=$((index + 1))
    done
    magick montage -font "$font" -pointsize 22 "$@" -tile 4x5 -geometry +6+6 "$out/sheet-%02d.png"
    rm "$out"/frame-*.png
    echo "Contact sheets are in $out"
    exit 0
fi

recording="$1"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

crop=
width=1920
quality=90
count=0
webp_args=
gif_frames=
gif_delays=
while read -r time hold blurs; do
    case "$time" in
        ''|'#'*) continue ;;
        crop=*) crop=${time#crop=}; continue ;;
        width=*) width=${time#width=}; continue ;;
        quality=*) quality=${time#quality=}; continue ;;
    esac
    count=$((count + 1))
    frame="$work/frame-$(printf %02d "$count").png"

    # crop is WxH+X+Y in the recording's pixels; ffmpeg wants W:H:X:Y.
    filter="scale=$width:-2:flags=lanczos"
    [ -z "$crop" ] || filter="crop=$(echo "$crop" | tr 'x+' '::'),$filter"
    ffmpeg -nostdin -v error -ss "$time" -i "$recording" -frames:v 1 -vf "$filter" "$frame"
    [ -f "$frame" ] || { echo "No frame at $time: is it past the end of the recording?" >&2; exit 1; }

    for blur in ${blurs%%#*}; do
        region=$(echo "${blur#blur=}" | awk -F, '{ printf "%dx%d+%d+%d", $3, $4, $1, $2 }')
        magick "$frame" \( +clone -crop "$region" +repage -blur 0x14 \) -geometry "+${region#*+}" -composite "$frame"
    done

    webp_args="$webp_args -d $(awk -v hold="$hold" 'BEGIN { printf "%d", hold * 1000 }') $frame"
    gif_frames="$gif_frames $frame"
    # GIF delays are in hundredths of a second.
    gif_delays="$gif_delays ( -clone $((count - 1)) -set delay $(awk -v hold="$hold" 'BEGIN { printf "%d", hold * 100 }') )"
done < "$spec"
[ "$count" -gt 0 ] || { echo "$spec lists no keyframes" >&2; exit 1; }

# gifski gives every frame the same duration, so ImageMagick sets the hold times afterwards; it copies the frames
# as they are.
# shellcheck disable=SC2086
img2webp -loop 0 -lossy -q "$quality" -m 6 $webp_args -o "$root/assets/demo.webp" > /dev/null 2>&1
# shellcheck disable=SC2086
gifski --quiet --fps 1 --quality "$quality" --width "$width" -o "$work/demo.gif" $gif_frames
# shellcheck disable=SC2086
magick "$work/demo.gif" $gif_delays -delete "0-$((count - 1))" "$root/assets/demo.gif"

echo "Built from $count keyframes:"
ls -lh "$root/assets/demo.webp" "$root/assets/demo.gif" | awk '{ print "  " $NF " (" $5 ")" }'
