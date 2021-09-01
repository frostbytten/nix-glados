{
  description = "NixOS configuration for GLaDOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:frostbytten/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }: {
    nixosConfigurations.glados = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.apple-macbook-pro-11-5
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.frostbytten = import ./hm-frostbytten.nix;
        }
        ({ config, pkgs, ... }:
          {
            imports = [ ./hardware-configuration.nix ];
            fileSystems."/" = { options = [ "noatime" "nodiratime" ]; };

            boot = {
              kernelPackages = pkgs.linuxPackages_latest;
              loader = {
                systemd-boot.enable = true; 
                efi.canTouchEfiVariables = true;
                grub = {
                  enable = true;
                  version = 2;
                  efiSupport = true;
                  enableCryptodisk = true;
                  device = "nodev";
                };
              };
              initrd.luks.devices.crypt = {
               device = "/dev/sda2";
               preLVM = true;
              };
            };

            time.timeZone = "America/New_York";

            networking = {
              hostName = "glados";
              useDHCP = false;
              interfaces.wlp4s0.useDHCP = true;
              networkmanager.enable = true;
            };

            security = {
              sudo.enable = true;
            };

            i18n = {
              defaultLocale = "en_US.UTF-8";
              supportedLocales = [ "en_US.UTF-8/UTF-8" ];
            };

            console = {
              useXkbConfig = true;
            };

            users.users.frostbytten = {
              isNormalUser = true;
              extraGroups = [ "wheel" "networkmanager" ];
              hashedPassword = "$6$k30CF7ugQ7dp$G9deLiP5wetj7om06ONBmUIbPnNi.qdRAxgh0c.JLCVTHUy608k8irhpW7T3jePC4cmn9y.L415HFe/6UTlyy1";
            };

            environment = {
              systemPackages = with pkgs; [
                gitAndTools.gitFull
                  vim
                  vis
                  curl
              ];

              shellAliases = {
                ls = "ls --color=auto";
                ll = "ls -la --color=auto";
              };
           };
           
           services = {
             xserver = {
               enable = true;
               layout = "us";
               xkbOptions = "ctrl:nocaps";
               desktopManager.xterm.enable = false;
               displayManager.defaultSession = "none+i3";
               windowManager.i3 = {
                 enable = true;
                 extraPackages = [ pkgs.dmenu ];
               };
             };
           };

           nixpkgs = {
             config = {
                allowBroken = true;
                allowUnfree = true;
             };
           };

            nix = {
              package = pkgs.nixFlakes;
              useSandbox = true;
              autoOptimiseStore = true;
              readOnlyStore = false;
              allowedUsers = [ "@wheel" ];
              trustedUsers = [ "@wheel" ];
              extraOptions = ''
                experimental-features = nix-command flakes
                keep-outputs = true
                keep-derivations = true
              '';

              gc = {
                automatic = true;
                dates = "weekly";
                options = "--delete-older-than 7d --max-freed $((64 * 1024**3))";
              };
  
              optimise = {
                automatic = true;
                dates = [ "weekly" ];
              };
            };
            system.stateVersion = "21.05";
          }
        )
      ];
    };
  };
}
