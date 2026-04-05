{ pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "uloop-cli";
  version = "1.6.3";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/uloop-cli/-/uloop-cli-${version}.tgz";
    hash = "sha512-YGDf9FrJTOeDwypdhJlgnoVE78evZHrZH3foe+76Dc06fbkc78fQGWj/LnQ/SIsjt6Gn2ymaJGfW3HX4Vod6rw==";
  };

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/uloop-cli
    cp -r . $out/lib/node_modules/uloop-cli

    mkdir -p $out/bin
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/uloop \
      --add-flags "$out/lib/node_modules/uloop-cli/dist/cli.bundle.cjs"

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "CLI tool for Unity Editor communication via Unity CLI Loop";
    homepage = "https://github.com/hatayama/uLoopMCP#readme";
    license = licenses.mit;
    mainProgram = "uloop";
    platforms = platforms.darwin;
  };
}
