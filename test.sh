# Installing the stage file (desktop profile openrc)
BASE_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds"
STAGE3_PATH=$(wget -qO- "$BASE_URL/latest-stage3-amd64-desktop-openrc.txt" \
    | grep -m1 -oE '^[^ ]+\.tar\.xz')

if [ -z "$STAGE3_PATH" ]; then
    echo "Failed to determine latest stage3 URL. Exiting..."
    exit 1
fi