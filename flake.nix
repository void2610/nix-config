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

    # OpenClaw: 宣言的な OpenClaw パッケージと Home Manager module
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, sops-nix, nix-openclaw }:
  let
    # 現在は Apple Silicon Mac だけを管理対象にしている。
    system = "aarch64-darwin";
    insecurePackages = [
      # nixpkgs 側で insecure 扱いだが、server で明示的に利用する。
      "openclaw-2026.3.12"
    ];
    # flake 全体で共通化する nixpkgs 設定。
    commonNixpkgsConfig = {
      allowUnfree = true;
      permittedInsecurePackages = insecurePackages;
    };
    # OpenClaw を pkgs 側に差し込む overlay。
    commonOverlays = [ nix-openclaw.overlays.default ];
    melchiorRepo = "/Users/shuya.izumi/Documents/GitHub/melchior";
    melchiorNixDir = builtins.path {
      path = ./pkgs/melchior;
      name = "melchior-nix";
    };
    pkgs = import nixpkgs {
      inherit system;
      config = commonNixpkgsConfig;
      overlays = commonOverlays;
    };
    # Melchior は共有 repo なので、repo には個人用 flake を置かず、
    # 自分の nix-config 側だけで開発環境を管理する。
    melchiorDevShell = import "${melchiorNixDir}/dev-shell.nix" {
      inherit pkgs melchiorRepo;
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
    devShells.${system}.melchior = melchiorDevShell;
    # game/work/server の各ホスト構成。
    inherit darwinConfigurations;
  };
}
