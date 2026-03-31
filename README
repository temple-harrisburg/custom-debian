# Overview
Files for custom Debian image. 

Available configurations:
- classroom automation controller
- digital signage
- manual Debian install

# Usage
1. Download a [Debian ISO file](https://www.debian.org/distrib/)
2. Mount ISO image and copy contents to a working directory.
3. Copy `preseed` directory to working directory
4. Copy `boot/grub/grub.cfg` to `boot/grub/grub.cfg` in working directory, overwriting existing config file.
5. `cd` to working directory
6. Build ISO image:
```sh
xorriso -as mkisofs \
  -r -J -joliet-long -l \
  -V "MY_VOLUME_LABEL" \
  -o /path/to/MY_IMAGE_FILE.iso \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  .
```

Burn ISO to USB using method of your choice (Rufus, `dd`, etc.).
