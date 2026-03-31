#!/bin/sh
# 
# /cdrom/preseed/late_command.sh
# 
# This script is run by the Debian installer after the base system is installed, but before
# booting into the installed system. 
# 
# SUMMARY:
#   1. Set custom GRUB theme
#   2. Set up auto-login for $USER with LightDM
#   3. Set File Manager (pcmanfm) to start with window manager (X11)
#   4. Copy openbox configuration files for the given profile (`automation_controller` or `digital_signage`)
#   5. Copy scripts for given profile
# 
# TIPS:
#   1. '/cdrom/' is the root of installer files
#   2. '/target/' is the root of the target system
#   3. 'in-target' runs commands as if 'chroot'd into the target system. 
#       DROP '/target/' from paths when using 'in-target'.

USER="tuhadmin" # WARNING: If USER is changed, it must also be changed in both preseed.cfg files.
USER_ROOT="home/$USER"


set_grub_theme() {
    # Set custom Temple University-branded GRUB theme
    mkdir -p /target/usr/share/grub/themes
    cp -r /cdrom/preseed/theme /target/usr/share/grub/themes/tu-grub 
    echo GRUB_THEME=/usr/share/grub/themes/tu-grub/theme.txt >> /target/etc/default/grub
    rm /target/etc/grub.d/05_debian_theme # Prevent grub from falling back to built-in Debian theme
    in-target update-grub
}

lightdm_autologin() {
    # Automatically log in as USER with LightDM
    mkdir -p /target/etc/lightdm/
    cat << EOF > /target/etc/lightdm/lightdm.conf
[Seat:*]
autologin-user=$USER
user-session=openbox
EOF
}

create_xinit() {
    # Auto-start file manager (pcmanfm) when window manager (X11) loads
    # (pcmanfm enables auto-mounting of USB drives)
    cat > "/target/$USER_ROOT/.xinitrc" << 'EOF'
#!/bin/sh
. /etc/X11/Xsession
pcmanfm --daemon-mode
EOF
    in-target chmod 755 "/$USER_ROOT/.xinitrc"
}

copy_openbox_config() {
    # Copy custom Openbox configuration into target system.
    # Custom Openbox config files:
    #   - autostart
    #   - environment
    #   - rc.xml

    mkdir -p "/target/$USER_ROOT/.config/openbox"

    for file in /cdrom/preseed/"${1}"/openbox/*; do 
        cp "$file" "/target/$USER_ROOT/.config/openbox"
    done

    in-target chown $USER:$USER -R "/$USER_ROOT/.config"
}

copy_scripts() {
    for script in /cdrom/preseed/"${1}"/scripts/*.sh; do

        # Copy ".sh" files into USER's home directory
        cp "${script}" "/target/$USER_ROOT"
        
        BASE_SCRIPT=$(basename "$script")
        in-target chmod 775 "/${USER_ROOT}/${BASE_SCRIPT}"
        in-target chown $USER:$USER "/${USER_ROOT}/${BASE_SCRIPT}"

        # By linking the scripts to /usr/bin, we avoid having to update the PATH variable and the scripts can be invoked anywhere in the user session.
        # We also strip the suffix to simplify commands, e.g. `setup` instead of `~/setup.sh`.
        in-target ln -s "/${USER_ROOT}/${BASE_SCRIPT}" "/usr/bin/$(basename "${script}" ".sh")"
    done
}


main() {
    # Script must be run with 1 argument, being the name of the config directory.
    # This is set in the preseed file chosen from the GRUB screen, which is specified at `/boot/grub/grub.cfg`.
    if [ "$#" -lt 1 ]; then 
        exit 10
    fi

    # When the late_command fails, the Debian installer only returns the exit code. 
    # By setting a unique exit code for each step, we can narrow down errors when they occur.

    if ! set_grub_theme; then 
        exit 5
    fi
    
    if ! lightdm_autologin; then 
        exit 6
    fi

    if ! create_xinit; then 
        exit 7
    fi
    
    if ! copy_openbox_config "$@"; then 
        exit 8
    fi 

    if ! copy_scripts "$@"; then 
        exit 9 
    fi
}

main "$@"