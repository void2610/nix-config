{
  description = "shuya の Mac 設定";

  inputs = {
    # nixpkgs（unstable）
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # nix-darwin: macOS システム設定管理
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager: ユーザー環境管理
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-homebrew: Homebrew の宣言的管理
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    # sops-nix: 暗号化した secrets の配置
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, sops-nix }:
  let
    system = "aarch64-darwin";
    mkDarwinConfiguration =
      {
        configName,
        profile,
      }:
      nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit profile; };
        modules = [
          (import ./nix-darwin/hosts/default.nix { inherit configName; })

          nix-homebrew.darwinModules.nix-homebrew
          ({ config, ... }: {
            nix-homebrew = {
              enable = true;
              enableRosetta = false;
              user = config.system.primaryUser;
              autoMigrate = true;
            };
          })

          sops-nix.darwinModules.sops

          home-manager.darwinModules.home-manager
          ({ config, ... }:
            let
              username = config.system.primaryUser;
              homeDirectory = config.users.users.${username}.home;
            in
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit profile;
                  inherit homeDirectory username;
                };
                users.${username} = {
                  imports = [
                    ./home-manager/users/default.nix
                    (./home-manager/profiles + "/${profile}.nix")
                  ];
                };
              };
            })
        ];
      };
  in
  {
    darwinConfigurations = {
      Macintosh = mkDarwinConfiguration {
        configName = "Macintosh";
        profile = "game";
      };

      "game-dev" = mkDarwinConfiguration {
        configName = "game-dev";
        profile = "game";
      };

      "PCmac24055" = mkDarwinConfiguration {
        configName = "work-dev";
        profile = "work";
      };

      "server-node" = mkDarwinConfiguration {
        configName = "server-node";
        profile = "server";
      };
    };
  };
}
