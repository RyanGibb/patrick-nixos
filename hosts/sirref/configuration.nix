{ pkgs, config, lib, ryan-nixos, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/patrick-website.nix
    ../../modules/desk-rejection-website.nix
    ../../modules/rss_to_mail.nix
  ];

  boot.loader.grub = {
    enable = true;
    default = "saved";
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ git vim tmux agenix ];

  programs.bash.promptInit = ''
    PS1='\u@\h:\w \$ '
  '';

  users.users = rec {
    patrick = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      initialHashedPassword = root.initialHashedPassword;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+"
      ];
    };
    technical_support = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILpJ2Y1tRU37NQBy6sP+Cz/iNiJ6ZGqlIDeBR5bx+oEl ryan@freumh.org"
      ];
    };
    root = {
      initialHashedPassword =
        "$y$j9T$Z8Fs2l74CgVO/t1ZSNmo./$GvOWgmfjNS.CmkzYTXYYkzgFKRMdAaqe1sXSZrJlqI.";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiobEqDGuy5NpMIh3JDZ5cMO0EbgYAFtDUWGObkpO6+"
      ];
    };
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  services.rss_to_mail = {
    enable = true;
    users = [ "patrick" ];
  };

  networking.hostName = "sirref";
  networking.domain = "sirref.org";
  security.acme.acceptTerms = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  time.timeZone = "Europe/London";
  console.keyMap = "uk";

  age.secrets.cal-patrick = {
    file = ../../secrets/cal-patrick.age;
    mode = "770";
    owner = "${config.systemd.services.radicale.serviceConfig.User}";
    group = "${config.systemd.services.radicale.serviceConfig.Group}";
  };
 
  eilean = {
    serverIpv4 = "95.216.193.242";
    serverIpv6 = "2a01:4f9:c010:8298::1";
    publicInterface = "eth0";

    username = "patrick";

    mailserver.enable = true;
    matrix = {
      enable = true;
      bridges.whatsapp = true;
      bridges.signal = true;
    };

    # <><><> Calendar <><><>
    radicale = {
      enable = true;
      users.${config.eilean.username}.passwordFile = config.age.secrets.cal-patrick.path;
    };

    # mastodon.enable = true;
    # gitea.enable = true;
    # headscale.enable = true;
  };

  eilean.dns.nameservers = [ ];
  eilean.services.dns.zones = {
    ${config.networking.domain} = {
      records = [
        {
          name = "@";
          type = "NS";
          data = "ns1";
        }
        {
          name = "@";
          type = "NS";
          data = "ns1.freumh.org.";
        }
        {
          name = "ns1";
          type = "A";
          data = config.eilean.serverIpv4;
        }
        {
          name = "ns1";
          type = "AAAA";
          data = config.eilean.serverIpv6;
        }
        {
          name = "mail._domainkey.sirref.org";
          type = "TXT";
          data =
            "v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDnHd/+eEPaYxfbqwV5MKWlorOPrOMojqhKaYKJQgzBri7/kj96h8RiTt00AxHUGc5LUAhJnDTEnyn9MEdeB+DYplmn29D9v9M1tWrz1b/kmAmkhacnRGnlIk/mc70Wqfu1W/2jmEYXfXT6wSTq6o/Ch/myI2X8rljYMdmHnlgZjQIDAQAB";
        }
      ];
    }; 
    "deskrejection.com" = {
      soa.serial = 1706745602;
      records = [{
          name = "@";
          type = "NS";
          data = "ns1";
        }
        {
          name = "@";
          type = "NS";
          data = "ns1.freumh.org.";
        }
        {
          name = "ns1";
          type = "A";
          data = config.eilean.serverIpv4;
        }
        {
          name = "ns1";
          type = "AAAA";
          data = config.eilean.serverIpv6;
        }
        {
          name = "ns2";
          type = "A";
          data = config.eilean.serverIpv4;
        }
        {
          name = "ns2";
          type = "AAAA";
          data = config.eilean.serverIpv6;
        }
        {
          name = "@";
          type = "A";
          data = config.eilean.serverIpv4;
        }
        {
          name = "@";
          type = "AAAA";
          data = config.eilean.serverIpv6;
        }
      ];
    };
    "freumh.org" =
      ryan-nixos.nixosConfigurations.owl.config.eilean.services.dns.zones."freumh.org";
  };

  # <><><> Email <><><>
  age.secrets.email-patrick.file = ../../secrets/email-patrick.age;
  age.secrets.email-system.file = ../../secrets/email-system.age;
  eilean.mailserver.systemAccountPasswordFile =
    config.age.secrets.email-system.path;
  mailserver.loginAccounts = {
    "${config.eilean.username}@${config.networking.domain}" = {
      passwordFile = config.age.secrets.email-patrick.path;
      aliases = [
        "dns@${config.networking.domain}"
        "postmaster@${config.networking.domain}"
      ];
    };
    "misc@${config.networking.domain}" = {
      passwordFile = config.age.secrets.email-patrick.path;
      catchAll = [ "${config.networking.domain}" ];
    };
    "system@${config.networking.domain}" = {
      aliases = [ "nas@${config.networking.domain}" ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11";
}
