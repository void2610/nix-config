{
  nixpkgs,
  home-manager,
  nix-openclaw,
  commonNixpkgsConfig,
  commonOverlays,
}:
let
  # ホスト固有の値と profile 対応はここから取得する。
  hostDefs = import ./hosts/default.nix;

  # 1 ホスト分の standalone home-manager 構成を組み立てる。
  mkHomeConfiguration =
    configName:
    let
      cfg = hostDefs.hosts.${configName};
    in
    home-manager.lib.homeManagerConfiguration {
      # Linux 側でも flake 共通の nixpkgs 設定をそのまま使う。
      pkgs = import nixpkgs {
        system = cfg.system;
        config = commonNixpkgsConfig;
        overlays = commonOverlays;
      };
      extraSpecialArgs = {
        inherit (cfg) profile username homeDirectory;
      };
      modules = [
        nix-openclaw.homeManagerModules.openclaw
        ./users/default.nix
        (./profiles + "/${cfg.profile}.nix")
      ]
      ++ cfg.extraModules;
    };
in
# hosts/default.nix に定義した全ホストから flake の出力を自動生成する。
builtins.mapAttrs (configName: _: mkHomeConfiguration configName) hostDefs.hosts
