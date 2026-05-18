{
  description = "gl00m's system config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent.url = "github:NousResearch/hermes-agent";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia = {
      url = "github:gl00mt1t4n/caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, hermes-agent, zen-browser, caelestia, ... }:
  let
    system = "x86_64-linux";
    overlays = [
      (final: prev: {
        zen-browser = zen-browser.packages.${system}.default;
      })
    ];
    pkgs = import nixpkgs { inherit system overlays; };

    # Override the binary's -p flag to load QML from the live submodule instead
    # of the Nix store. Edits to caelestia/**/*.qml hot-reload without make user.
    caelestia-shell-local = caelestia.packages.${system}.caelestia-shell.overrideAttrs (old: {
      postInstall = builtins.replaceStrings
        [ ''--add-flags "-p $out/share/caelestia-shell"'' ]
        [ ''--add-flags "-p /home/gl00m/dotfiles/caelestia"'' ]
        old.postInstall;
    });

    caelestiaHmModules = [
      caelestia.homeManagerModules.default
      { programs.caelestia.package = caelestia-shell-local; }
    ];
  in {

    # System only
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.overlays = overlays; }
        ./configuration.nix
        hermes-agent.nixosModules.default
      ];
    };

    # User only
    homeConfigurations.gl00m = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home.nix ] ++ caelestiaHmModules;
    };

    # Both unified
    nixosConfigurations.gl00m-full = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        { nixpkgs.overlays = overlays; }
        ./configuration.nix
        hermes-agent.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.gl00m = { imports = [ ./home.nix ] ++ caelestiaHmModules; };
        }
      ];
    };

  };
}
