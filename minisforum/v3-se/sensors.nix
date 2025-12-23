{ pkgs, lib, ... }:
{

  # Enable IIO for brightness and accelerometer sensors
  hardware.sensor.iio.enable = lib.mkDefault true;

  services.fprintd.enable = lib.mkDefault true;

  # Override ACPI DSDT to fix the accelerometer.
  # The V3 SE uses a different DSDT than the V3, so we use a bundled copy.
  # Only the accelerometer ID is patched (SMOCF05 -> SMO8B30).
  # The touchscreen (PNP0C50) is left untouched unlike the V3 patch.
  boot.initrd.prepend =
    let
      minisforum-v3se-acpi-override = pkgs.stdenv.mkDerivation {
        name = "minisforum-v3se-acpi-override";
        CPIO_PATH = "kernel/firmware/acpi";

        # Unpack dsdt.dsl as the source
        src = ./dsdt.dsl;
        dontUnpack = true;

        nativeBuildInputs = with pkgs; [
          acpica-tools
          cpio
        ];

        buildPhase = ''
          cp $src dsdt.dsl
          patch -p0 < ${./dsdt.patch}
        '';

        installPhase = ''
          mkdir -p $CPIO_PATH
          iasl -tc dsdt.dsl
          cp dsdt.aml $CPIO_PATH
          find kernel | cpio -H newc --create > acpi_override
          cp acpi_override $out
        '';
      };
    in
    [ (toString minisforum-v3se-acpi-override) ];

  # Fix accelerometer rotation for V3 SE.
  # DMI modalias: dmi:...svnMicroComputer(HK)TechLimited:pnV3SE:...
  # Parent modalias: acpi:SMO8B30:SMO8B30:
  services.udev.extraHwdb = ''
    sensor:modalias:acpi:SMO8B30*:dmi:*svnMicroComputer*:pnV3SE:*
      ACCEL_MOUNT_MATRIX=-1, 0, 0; 0, -1, 0; 0, 0, -1
  '';

}
