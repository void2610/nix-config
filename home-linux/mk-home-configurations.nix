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

  # 1 ホスト × 1 arch 分の standalone home-manager 構成を組み立てる。
  mkHomeConfiguration =
    cfg: system:
    home-manager.lib.homeManagerConfiguration {
      # Linux 側でも flake 共通の nixpkgs 設定をそのまま使う。
      pkgs = import nixpkgs {
        inherit system;
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

  # `systems` を持つホストは arch ごとに `<name>-<system>` 形式へ展開し、
  # 単一 `system` のホスト (jetson 等) は既存の target 名を壊さないよう `<name>` のまま出力する。
  expandHost =
    configName: cfg:
    if cfg ? systems then
      builtins.listToAttrs (
        map (system: {
          name = "${configName}-${system}";
          value = mkHomeConfiguration cfg system;
        }) cfg.systems
      )
    else
      { ${configName} = mkHomeConfiguration cfg cfg.system; };
in
# hosts/default.nix に定義した全ホスト × 全 arch から flake の出力を自動生成する。
builtins.foldl' (acc: configName: acc // expandHost configName hostDefs.hosts.${configName}) { } (
  builtins.attrNames hostDefs.hosts
)
