{ pkgs, ... }:
{
  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    fzf
    zoxide
    wl-clipboard
    #screenshots
    grim
    slurp #region selection
    starship # terminal prompt

  ];

  "[❯](green)";
        error_symbol = "[❯](red)";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
    };
  };

