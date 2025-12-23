{ ... }:
{
  imports = [
    ./sensors.nix
    # ./audio.nix  # Testing manual XDG approach instead
    ./power.nix

    ../../common/gpu/amd/default.nix
    ../../common/cpu/amd/default.nix
    ../../common/pc/laptop/default.nix
  ];
}
