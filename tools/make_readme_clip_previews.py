"""Make the animated previews the root README shows for the clips in docs/readme/clips/.

Usage: python tools/make_readme_clip_previews.py [--ffmpeg PATH] [--width 640] [--fps 20] [--quality 60]
For every docs/readme/clips/*.mp4 it writes an animated .webp with the same name next to it: the
whole clip, scaled down, looping, no sound (a GIF of the same clip is five to ten times larger). The .mp4 files are not changed.
ffmpeg is looked up on PATH, then in winget's install folder (winget install Gyan.FFmpeg).
"""
import argparse
import glob
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIPS = os.path.join(ROOT, "docs", "readme", "clips")
WINGET = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Microsoft", "WinGet", "Packages",
                      "Gyan.FFmpeg_*", "*", "bin", "ffmpeg.exe")


def find_ffmpeg():
    found = shutil.which("ffmpeg")
    if found:
        return found
    matches = sorted(glob.glob(WINGET))
    return matches[-1] if matches else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ffmpeg")
    parser.add_argument("--width", type=int, default=640)
    parser.add_argument("--fps", type=int, default=20)
    parser.add_argument("--quality", type=int, default=60)
    args = parser.parse_args()
    ffmpeg = args.ffmpeg or find_ffmpeg()
    if not ffmpeg:
        print("ffmpeg not found: install it (winget install Gyan.FFmpeg) or pass --ffmpeg PATH")
        return 1
    for clip in sorted(glob.glob(os.path.join(CLIPS, "*.mp4"))):
        preview = os.path.splitext(clip)[0] + ".webp"
        subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", clip, "-an",
                        "-vf", f"fps={args.fps},scale={args.width}:-2:flags=lanczos",
                        "-c:v", "libwebp", "-lossless", "0", "-q:v", str(args.quality),
                        "-compression_level", "6", "-loop", "0", preview], check=True)
        print(f"{os.path.basename(preview)}: {os.path.getsize(preview) / 1e6:.1f} MB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
