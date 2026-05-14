{ pkgs, ... }:
{
  home.packages = with pkgs; [
    delta
    gh
  ];

  programs.git = {
    enable = true;
    userName = "gl00mt1t4n";
    userEmail = "gloomtitan1337@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      push.autoSetupRemote = true;
    };
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
      };
    };
  };
}
