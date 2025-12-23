{ pkgs, ... }:
{

  # Enable aggressive PCIe power management
  boot.kernelParams = [ "pcie_aspm.policy=powersupersave" ];

  # V3 SE-specific ASPM tuning service
  # Enables ASPM L1 on devices where BIOS left it disabled:
  # - Intel WiFi AX210 (02:00.0) - most impactful for battery
  # - Radeon HD Audio (e4:00.1)
  # - Thunderbolt tunnels (00:03.1, 00:04.1)
  systemd.services.enable-aspm = {
    description = "Enable ASPM on V3 SE devices";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${./aspm_v3se.sh}";
      Restart = "no";
    };

    path = with pkgs; [
      pciutils
    ];
  };

}
