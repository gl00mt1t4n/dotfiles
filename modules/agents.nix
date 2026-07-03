{ pkgs, lib, config, ... }:
let
  managedFiles = [
    ".codex/config.toml"
    ".codex/rules/default.rules"
    ".claude/settings.json"
    ".claude/CLAUDE.md"
    ".config/tmux/tmux.conf"
  ];
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
  };

  home.packages = with pkgs; [
    age
    sops
    ssh-to-age
    tmux
  ];

  home.activation.backupExistingAgentConfigs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for rel in ${lib.escapeShellArgs managedFiles}; do
      target="$HOME/$rel"
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        backup="$target.hm-backup"
        i=1
        while [ -e "$backup" ]; do
          backup="$target.hm-backup-$i"
          i=$((i + 1))
        done
        mv "$target" "$backup"
      fi
    done
  '';

  home.file.".codex/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/agents/codex/config.toml";
  home.file.".codex/rules/default.rules".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/agents/codex/rules/default.rules";
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/agents/claude/settings.json";
  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/agents/claude/CLAUDE.md";
  home.file.".config/tmux/tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/agents/tmux/tmux.conf";

  programs.bash.bashrcExtra = ''
    # Recovery-safe default: do not auto-attach tmux from interactive shells.
    # Manual `tmux` remains available when wanted.
  '';
}
