{
  system,
  nix-darwin,
  home-manager,
  nix-homebrew,
  sops-nix,
  nix-openclaw,
  commonNixpkgsConfig,
  commonOverlays,
}:
let
  # ホスト固有の値と profile 対応はここから取得する。
  hostDefs = import ./hosts/default.nix;

  # darwinSystem 側でも flake 共通の nixpkgs 設定をそのまま使う。
  nixpkgsModule = {
    nixpkgs = {
      config = commonNixpkgsConfig;
      overlays = commonOverlays;
    };
  };

  # Homebrew 自体は全ホストで有効化し、利用ユーザーだけホストごとに追従させる。
  nixHomebrewModule = { config, ... }: {
    nix-homebrew = {
      enable = true;
      enableRosetta = false;
      user = config.system.primaryUser;
      autoMigrate = true;
    };
  };

  # Home Manager は primaryUser に対してだけ差し込み、
  # profile ごとの user 設定ファイルを読み込む。
  homeManagerModule = profile: { config, ... }:
    let
      username = config.system.primaryUser;
      homeDirectory = config.users.users.${username}.home;
    in
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        sharedModules = [
          nix-openclaw.homeManagerModules.openclaw
        ];
        extraSpecialArgs = {
          inherit profile;
          inherit homeDirectory username;
        };
        users.${username} = {
          imports = [
            ../home-manager/users/default.nix
            (../home-manager/profiles + "/${profile}.nix")
          ];
        };
      };
    };

  # 1 ホスト分の darwinSystem を組み立てる。
  mkDarwinConfiguration = configName:
    let
      cfg = hostDefs.hosts.${configName};
    in
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        profile = cfg.profile;
      };
      modules = [
        nixpkgsModule
        (hostDefs.moduleFor configName)
        nix-homebrew.darwinModules.nix-homebrew
        nixHomebrewModule
        sops-nix.darwinModules.sops
        home-manager.darwinModules.home-manager
        (homeManagerModule cfg.profile)
      ];
    };
in
# hosts/default.nix に定義した全ホストから flake の出力を自動生成する。
builtins.mapAttrs
  (configName: _: mkDarwinConfiguration configName)
  hostDefs.hosts
