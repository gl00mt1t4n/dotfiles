#flake.nix

{
	description = "gl00m's Home Manager config";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-unstable;
		
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
};
};

outputs = { nixpkgs, home-manager, ...};

let
	lib = nixpkgs.lib;
system = "x86_64-linus";
pkgs = import nixpkgs {inherit system; };

in {
	homeConfigurations = {
		gl00m = home-manager.lib.homeManagerConfiguration {
inherit pkgs;
modules = [ ./home.nix ];
};
};
};
}
