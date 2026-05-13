.PHONY: system user full update clean commit

system: commit
	sudo nixos-rebuild switch --flake .#nixos

user: commit
	home-manager switch --flake .#gl00m

full: commit
	sudo nixos-rebuild switch --flake .#gl00m-full

update: commit
	nix flake update

clean:
	nix-collect-garbage -d

commit:
	@cd /home/gl00m/dotfiles && git add .
	@read -p "Commit message: " msg; git diff --cached --quiet || git commit -m "$$msg"
	@git push
