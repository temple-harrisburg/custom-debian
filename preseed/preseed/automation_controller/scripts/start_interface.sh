#!/usr/bin/env bash
# 
# /usr/bin/start_interface --> $HOME/start_interface.sh
# 
# Load Kramer variables from setup script and start Chromium in kiosk mode

if [ -f "${CONFIG_FILE:-"$HOME/.kramer_config"}" ]; then
    # shellcheck disable=SC1090
    . "$CONFIG_FILE"
else
    echo "WARNING: missing \"${CONFIG_FILE}\". The interface may not start correctly"
fi

chromium --kiosk --disable-gpu --noerrdialogs --disable-infobars --disable-features=TranslateUI \
    --disable-session-crashed-bubble --no-sandbox --disable-notifications --disable-sync-preferences \
    --disable-background-mode --disable-popup-blocking --no-first-run --password-store=basic \
    --enable-gpu-rasterization --disable-translate --disable-logging --disable-default-apps \
    --disable-extensions --disable-crash-reporter --disable-pdf-extension --disable-new-tab-first-run \
    --disable-dev-shm-usage --start-maximized --mute-audio --disable-crashpad --hide-scrollbars \
    --ash-hide-cursor --memory-pressure-off --force-device-scale-factor=1 --window-position=0,0 \
    "http://${KRAMER_IP}?immersive=${KRAMER_IMMERSIVE}" &