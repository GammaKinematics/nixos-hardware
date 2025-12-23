#!/bin/bash
# ASPM tuning script for Minisforum V3 SE
# Enables ASPM on devices where BIOS left it disabled

# Check if running as root
if [[ $(id -u) != 0 ]]; then
    echo "This needs to be run as root"
    exit 1
fi

# Function to enable ASPM on a device
# Uses setpci's CAP_EXP (PCIe capability) shorthand
# Link Control register is at CAP_EXP+0x10, ASPM is bits 0-1
# Values: 0=disabled, 1=L0s, 2=L1, 3=L0s+L1
enable_aspm() {
    local device="$1"
    local setting="$2"
    local name="$3"

    if ! lspci -s "$device" > /dev/null 2>&1; then
        echo "[$device] $name - not present, skipping"
        return 0
    fi

    local current=$(setpci -s "$device" CAP_EXP+10.w 2>/dev/null)
    if [[ -z "$current" ]]; then
        echo "[$device] $name - no PCIe capability, skipping"
        return 0
    fi

    echo -n "[$device] $name: 0x$current -> "

    # Set ASPM bits (bits 0-1), mask with :3
    setpci -s "$device" CAP_EXP+10.w="${setting}:3" 2>/dev/null

    local new=$(setpci -s "$device" CAP_EXP+10.w 2>/dev/null)
    echo "0x$new"
}

echo "Enabling ASPM on V3 SE devices..."

# Intel WiFi AX210 - Enable L1 (most impactful for battery)
enable_aspm "02:00.0" 2 "Intel WiFi AX210"

# Radeon HD Audio - Enable L1 (L0s can cause audio glitches)
enable_aspm "e4:00.1" 2 "Radeon HD Audio"

# Thunderbolt tunnels - Enable L1
enable_aspm "00:03.1" 2 "Thunderbolt tunnel 1"
enable_aspm "00:04.1" 2 "Thunderbolt tunnel 2"

echo "Done."
