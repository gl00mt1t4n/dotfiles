{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gh
  ];

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "gl00mt1t4n";
      user.email = "gloomtitan1337@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      push.autoSetupRemote = true;
    };
  };
}
