{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    dwm
    st
    surf
    ungoogled-chromium
  ];

  xsession = {
    enable = true;
    windowManager = { command = "${pkgs.dwm}/bin/dwm"; };
  };
}
