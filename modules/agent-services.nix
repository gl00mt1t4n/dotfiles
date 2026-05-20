{ config, pkgs, ... }:
{
  users.users.openai-proxy = {
    isSystemUser = true;
    group = "openai-proxy";
  };
  users.groups.openai-proxy = {};

  sops = {
    defaultSopsFile = ../secrets/hermes.yaml;
    age.sshKeyPaths = [ "/home/gl00m/.ssh/id_ed25519" ];
    secrets.openai_api_key = {
      owner = "openai-proxy";
      group = "openai-proxy";
      mode = "0400";
    };
  };

  systemd.services.openai-proxy = {
    description = "Local OpenAI API proxy for Hermes";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "openai-proxy";
      Group = "openai-proxy";
      ExecStart = "${pkgs.python3}/bin/python ${../agents/openai-proxy/openai-proxy.py} --host 127.0.0.1 --port 11435 --key-file ${config.sops.secrets.openai_api_key.path}";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/run/secrets" ];
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
    };
  };

  services.hermes-agent = {
    configFile = ../agents/hermes/config.yaml;
    environmentFiles = [];
    documents = {
      "USER.md" = ../agents/hermes/USER.md;
    };
    extraPackages = with pkgs; [
      fd
      git
      ripgrep
      tmux
    ];
  };

  systemd.services.hermes-agent.serviceConfig.TimeoutStopSec = 240;
}
