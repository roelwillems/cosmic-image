# COSMIC + NVIDIA — my own Fedora Atomic image

Two custom images built with [BlueBuild](https://blue-build.org), rebuilt daily by GitHub Actions:

| Image | Recipe | What's in it |
|---|---|---|
| `cosmic-nvidia` | `recipes/recipe-clean.yml` | COSMIC desktop + NVIDIA-open driver. Fallback / test image. |
| `cosmic-roel` | `recipes/recipe-roel.yml` | The clean image + Tailscale, Homebrew and my Flatpak apps. Daily driver. |

Both start from `ghcr.io/ublue-os/base-nvidia`: Universal Blue's minimal Fedora Atomic image with the NVIDIA-open driver already built in and kept in sync with the kernel. COSMIC comes from Fedora's own repositories.

## Repository layout

```
recipes/
  recipe-clean.yml     # image 1: just includes common-base.yml
  recipe-roel.yml      # image 2: common-base.yml + common-apps.yml
  common-base.yml      # COSMIC, login screen, signing (shared)
  common-apps.yml      # Tailscale, Homebrew, Flatpaks (personal)
files/
  scripts/set-graphical-target.sh
  system/              # files copied into the image root (add your own later)
.github/workflows/build.yml   # builds both recipes every day at 06:00 UTC
```

## One-time setup

1. **Create the repository** at <https://workshop.blue-build.org> → *Log in with GitHub* → *New custom image repository*. Name it e.g. `cosmic-image`, keep it **public** (free builds, and your PC can pull the image without a login). Choose **automatic** container signing. This creates the repo, the `cosign.pub` key and the `SIGNING_SECRET`.
2. **Add these files** to that repository:
   - delete `recipes/recipe.yml`;
   - copy in `recipes/`, `files/scripts/`, and `.github/workflows/build.yml` from this folder;
   - **keep** the `cosign.pub` the Workshop created — don't replace it.
3. **Commit and push.** Open the *Actions* tab: two builds start (`recipe-clean.yml`, `recipe-roel.yml`). The first run takes roughly 20–40 minutes.
4. **Check the result.** Both builds green → the images appear under *Packages* on your GitHub profile. If a rebase later fails with "unauthorized", open each package → *Package settings* → set visibility to **Public**.

## Install on the PC (from Bazzite)

```bash
# keep Bazzite as a fallback in the boot menu
rpm-ostree status          # no pending update? otherwise reboot first
sudo ostree admin pin 0

# 1st rebase: unsigned, to install the signing keys
rpm-ostree rebase ostree-unverified-registry:ghcr.io/roelwillems/cosmic-roel:latest
systemctl reboot

# 2nd rebase: signed
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/roelwillems/cosmic-roel:latest
systemctl reboot
```

After logging in to COSMIC:

- **Apps** install in the background on first login (you get a notification). Run `bluebuild-flatpak-manager` to see status.
- **NVIDIA:** `nvidia-smi` should show your RTX 2060. If it doesn't (`lsmod | grep nvidia` is empty), add the boot options once and reboot:
  ```bash
  rpm-ostree kargs --append-if-missing=rd.driver.blacklist=nouveau \
    --append-if-missing=modprobe.blacklist=nouveau \
    --append-if-missing=nvidia-drm.modeset=1
  ```
- **Secure Boot:** the driver is signed with Universal Blue's key. Coming from Bazzite it is normally already enrolled. If the driver won't load with Secure Boot on, enroll it: `sudo mokutil --import` with Universal Blue's [public key](https://github.com/ublue-os/akmods/raw/main/certs/public_key.der) (password `universalblue` at the blue boot screen).
- **Tailscale:** `sudo tailscale up`
- **Homebrew:** open a new terminal, then e.g. `brew install fastfetch`.

## Daily workflow

1. Edit a recipe (e.g. remove a `#` in `common-apps.yml`), commit, push.
2. GitHub builds a new image (also automatically every morning with Fedora updates).
3. On the PC: `rpm-ostree upgrade && systemctl reboot` — or let automatic updates pick it up.
4. Something wrong? Choose the previous entry in the boot menu, or `rpm-ostree rollback`.

A failed build never touches your PC — you simply stay on the last good image. Read the build log in the *Actions* tab to see what broke.

## Switching between the two images

`rpm-ostree rebase ostree-image-signed:docker://ghcr.io/roelwillems/cosmic-nvidia:latest` (and back). Note: Flatpaks and Homebrew live in your home/`/var`, so they stay installed when you switch to the clean image.
