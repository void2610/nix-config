{ pkgs, ... }:
let
  melchiorRepo = "/Users/shuya.izumi/Documents/GitHub/melchior";
  melchiorShell = import ../../pkgs/melchior/dev-shell.nix {
    inherit pkgs melchiorRepo;
  };
in
{
  programs.zsh.initContent = ''
    mel() {
      cd ${melchiorRepo} || return 1
      nix develop ${melchiorShell}
    }
  '';
}
