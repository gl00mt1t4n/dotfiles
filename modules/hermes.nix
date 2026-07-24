{ config, ... }:
{
  sops.age.keyFile = "/home/gl00m/.config/sops/age/keys.txt";

  sops.secrets."hermes-env" = {
    sopsFile = ../secrets/hermes.yaml;
    format = "yaml";
    restartUnits = [ "hermes-agent.service" ];
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environmentFiles = [ config.sops.secrets."hermes-env".path ];

    settings = {
      model = {
        base_url = "https://api.openai.com/v1";
        default = "gpt-4o";
      };
      toolsets = [ "all" ];
      terminal = { backend = "local"; cwd = "."; timeout = 180; };
      memory = { memory_enabled = true; user_profile_enabled = true; };
      display = { compact = false; };
    };

    documents = {
      "USER.md" = ../agents/hermes/USER.md;
    };
  };
}
