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

    # brew-src は 6.0.15 以上必須: cask が Homebrew 6 系 DSL (command_wrapper 等) を使うため 5.1 系では bundle が失敗する
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src = {
        url = "github:Homebrew/brew/6.0.15";
        flake = false;
      };
    };

    # sops-nix: 暗号化した secrets の配置
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenClaw: 宣言的な OpenClaw パッケージと Home Manager module
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      sops-nix,
      nix-openclaw,
    }:
    let
      # darwin 側は Apple Silicon Mac だけを管理対象にしている。
      system = "aarch64-darwin";
      insecurePackages = [
      ];
      # flake 全体で共通化する nixpkgs 設定。
      commonNixpkgsConfig = {
        allowUnfree = true;
        permittedInsecurePackages = insecurePackages;
      };
      # OpenClaw を pkgs 側に差し込む overlay。
      commonOverlays = [ nix-openclaw.overlays.default ];
      pkgs = import nixpkgs {
        inherit system;
        config = commonNixpkgsConfig;
        overlays = commonOverlays;
      };
      # Ubuntu 向け standalone home-manager の組み立ては home-linux 配下で管理する。
      homeConfigurations = import ./home-linux/mk-home-configurations.nix {
        inherit
          nixpkgs
          home-manager
          nix-openclaw
          commonNixpkgsConfig
          commonOverlays
          ;
      };
      # darwinConfigurations の組み立ては flake 直下から追い出して、
      # nix-darwin 配下で管理する。
      darwinConfigurations = import ./nix-darwin/mk-configurations.nix {
        inherit
          system
          nix-darwin
          home-manager
          nix-homebrew
          sops-nix
          nix-openclaw
          commonNixpkgsConfig
          commonOverlays
          ;
      };
    in
    {
      # game/work/server の各ホスト構成。
      inherit darwinConfigurations;
      # ubuntu の standalone home-manager 構成。
      inherit homeConfigurations;
      # `nix fmt` 用フォーマッタ (treefmt + nixfmt)。
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-tree;
      };
    };
}
