{ pkgs, lib, config, inputs, ... }:

{
  android = {
    enable = true;
    flutter.enable = true;
  };
  packages = with pkgs; [
    # Logo handling
    imagemagick
    librsvg
  ];
}
