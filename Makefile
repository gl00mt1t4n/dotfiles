.PHONY: hm-switch
hm-switch:
	home-manager switch --flake .#gl00m

.PHONY: clean
clean:
	nix-collect-garbage -d
