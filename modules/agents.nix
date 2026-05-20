{ pkgs, lib, ... }:
let
  managedFiles = [
    ".codex/config.toml"
    ".codex/rules/default.rules"
    ".claude/settings.json"
    ".claude/CLAUDE.md"
    ".config/tmux/tmux.conf"
  ];
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

  home.file.".codex/config.toml".source = ../agents/codex/config.toml;
  home.file.".codex/rules/default.rules".source = ../agents/codex/rules/default.rules;
  home.file.".claude/settings.json".source = ../agents/claude/settings.json;
  home.file.".claude/CLAUDE.md".source = ../agents/claude/CLAUDE.md;
  home.file.".config/tmux/tmux.conf".source = ../agents/tmux/tmux.conf;

  programs.bash.bashrcExtra = ''
    if [[ $- == *i* ]] && [ -z "$TMUX" ] && [ -z "$NO_TMUX" ] && command -v tmux >/dev/null 2>&1; then
      case "''${TERM_PROGRAM:-}" in
        vscode) ;;
        *) tmux new-session -A -s main ;;
      esac
    fi
  '';
}
