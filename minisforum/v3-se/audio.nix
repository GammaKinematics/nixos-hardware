{ pkgs, ... }:
{
  # V3 SE uses ALC245 codec - hardware Master volume control doesn't work properly.
  # This patches PipeWire's ALSA mixer paths to ignore Master and use PCM for volume.
  # Based on: https://github.com/mudkipme/awesome-minisforum-v3#alternative-workaround-for-global-volume-control

  # --- PipeWire overlay approach (requires recompiling PipeWire - use home-manager instead) ---
  # nixpkgs.overlays = [
  #   (final: prev: {
  #     pipewire = prev.pipewire.overrideAttrs (old: {
  #       postInstall = (old.postInstall or "") + ''
  #         # Add [Element Master] with volume=ignore before [Element PCM]
  #         sed -i '/^\[Element PCM\]/i [Element Master]\nswitch = mute\nvolume = ignore\n' \
  #           $out/share/alsa-card-profile/mixer/paths/analog-output.conf.common
  #
  #         # Change existing Master to volume=ignore in headphones config
  #         sed -i '/^\[Element Master\]/,/^\[/ s/^volume = merge$/volume = ignore/' \
  #           $out/share/alsa-card-profile/mixer/paths/analog-output-headphones.conf
  #       '';
  #     });
  #   })
  # ];

  # Disable audio session suspension to fix headphone port dropout
  # Based on: https://github.com/mudkipme/awesome-minisforum-v3#disable-audio-session-suspension
  services.pipewire.wireplumber.extraConfig."disable-suspend"."monitor.alsa.rules" = [
    {
      matches = [
        { "node.name" = "~alsa_input.*"; }
        { "node.name" = "~alsa_output.*"; }
      ];
      actions = {
        update-props = {
          "session.suspend-timeout-seconds" = 0;
        };
      };
    }
  ];

  # --- Previous soft-mixer approach (didn't work on V3 SE - zeroed hardware amps) ---
  # Based on https://github.com/mudkipme/awesome-minisforum-v3/issues/9#issue-2407782714
  #
  # services.pipewire.wireplumber.extraConfig."alsa-soft-mixer"."monitor.alsa.rules" = [
  #   {
  #     # Enable soft-mixer.
  #     # Fix global volume control.
  #     actions.update-props."api.alsa.soft-mixer" = true;
  #     matches = [
  #       {
  #         "device.name" = "alsa_card.pci-0000_e4_00.6";
  #       }
  #     ];
  #   }
  #   {
  #     # Disable soft-mixer for input devices.
  #     actions.update-props."api.alsa.soft-mixer" = false;
  #     matches = [
  #       {
  #         "device.name" = "~alsa_card.*";
  #         "node.name" = "~alsa_input.*";
  #       }
  #     ];
  #   }
  # ];
}
