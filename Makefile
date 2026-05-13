.PHONY: system user full update clean commit

system:
	sudo nixos-rebuild switch --flake .#nixos
	$(MAKE) commit

user:
	home-manager switch --flake .#gl00m
	$(MAKE) commit

full:
	sudo nixos-rebuild switch --flake .#gl00m-full
	$(MAKE) commit

update:
	nix flake update
	$(MAKE) commit

clean:
	nix-collect-garbage -d

commit:
	@cd /home/gl00m/dotfiles && git add .
	@read -p "Commit message: " msg; git diff --cached --quiet || git commit -m "$$msg"
	@git push
