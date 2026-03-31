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
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew }:
  let
    hostname = "Macintosh";
    username = "shuya";
    system = "aarch64-darwin";
  in
  {
    darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        # nix-darwin の基本設定
        ./nix-darwin/hosts/${hostname}.nix

        # nix-homebrew モジュール
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = false; # Apple Silicon のみ使用
            user = username;
            # 既存の Homebrew インストールを自動移行
            autoMigrate = true;
          };
        }

        # home-manager を nix-darwin に統合
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            users.${username} = import ./home-manager/users/${username}.nix;
          };
        }
      ];
    };
  };
}
