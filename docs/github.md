# Publishing on GitHub

`git` is not currently available in this terminal. You can publish this project in either of these ways.

## Clean file set

The public repository should contain only:

```text
.gitignore
README.md
build.cmd
build.ps1
flash.cmd
flash.ps1
menu_map.html
electrical_schematic.html
docs\
firmware\README.md
firmware\jm_nixieclock_v2_custom_firmware.asm
firmware\jm_nixieclock_v2_custom_firmware.s19
```

Do not publish the local reverse-engineering files:

```text
reference\
tube_pin_selector.html
firmware\test_*
firmware\make_*_test.ps1
firmware\clock_hhmmss_real_pins.*
firmware\*.obj
firmware\*.cod
firmware\*.lsr
firmware\*.map
firmware\*.sym
firmware\*.err
```

## Option A: GitHub web upload

1. Create a new empty repository on GitHub.
2. Upload the contents of:

```text
C:\Users\OTIS\Documents\Nixie\github_upload
```

This folder is a clean copy prepared for upload.

## Option B: Install Git and push from terminal

After installing Git for Windows, run from the repository root:

```powershell
git init
git add .
git commit -m "Initial JM NixieClock V2.0 custom firmware"
git branch -M main
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

Replace `YOUR_USER` and `YOUR_REPO` with your GitHub account and repository name.
