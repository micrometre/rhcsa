# Master the Root Password Reset & Boot Targets (Essential Exam Drill)

This is one of the most critical RHCSA skills. 
You should practice interrupting GRUB and resetting root until it takes under 90 seconds.

## Infrastructure Configuration (Automated via Ansible)

To make this drill easier to practice in our environment, our Ansible `common` role automates the visibility of the GRUB menu during boot. By default, many modern Linux distributions hide the GRUB menu to speed up boot times. 

Our playbook applies the following configurations to `/etc/default/grub`:
- `GRUB_TIMEOUT=5`: Provides a 5-second countdown before the default kernel is booted.
- `GRUB_TIMEOUT_STYLE=menu`: Forces the menu to be displayed, overriding any hidden settings.

Whenever these settings are updated, a handler automatically rebuilds the GRUB configuration using `grub2-mkconfig -o /boot/grub2/grub.cfg`. This ensures you always have a clear 5-second window to interrupt the boot process and begin the drill.

## The Drill

### Boot into Emergency Mode
1. Reboot the system.
2. The GRUB menu will now automatically display for 5 seconds. Immediately use the arrow keys to stop the countdown and highlight the kernel entry you want to modify.
4. Press the `e` key to edit the boot parameters.
5. Find the line that starts with `linux` (it might be `linuxefi`).
6. Navigate to the end of this line.
7. Delete the `rhgb` and `quiet` parameters (if present).
8. Type `rd.break` at the end of the line.
9. Press `Ctrl + x` or `F10` to boot with these modified parameters.

### Remount Root Filesystem
1. You will be dropped into an emergency shell with the filesystem mounted read-only (`/sysroot`).
2. Execute the following commands to remount it read-write:
   ```bash
   mount -o remount,rw /sysroot
   ```

### Chroot into the System
1. Change the root directory to the system's actual root:
   ```bash
   chroot /sysroot
   ```

### Reset the Root Password
1. Now that you are inside the system, use the `passwd` command to set a new password for the root user:
   ```bash
   passwd root
   ```
2. Enter and confirm the new password when prompted.

### Update SELinux Context (Crucial)
1. After changing the password, you must create a file to tell SELinux to relabel the password file on the next boot.
   ```bash
   touch /.autorelabel
   ```

### Exit and Reboot
1. Exit the chroot environment:
   ```bash
   exit
   ```
2. Exit the emergency shell (this will trigger the relabel and reboot):
   ```bash
   exit
   ```

### Verify
1. The system will reboot. Once it comes back up, you should be able to log in as root with the new password.