.PHONY: system
system:
	sudo nixos-rebuild switch --flake .#nixos

.PHONY: user
user:
	home-manager switch --flake .#gl00m

.PHONY: full
full:
	sudo nixos-rebuild switch --flake .#gl00m-full

.PHONY: clean
clean:
	nix-collect-garbage -d
