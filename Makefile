.PHONY: system user full update clean

system:
	sudo nixos-rebuild switch --flake .#nixos

user:
	home-manager switch --flake .#gl00m

full:
	sudo nixos-rebuild switch --flake .#gl00m-full

update:
	nix flake update

clean:
	nix-collect-garbage -d
