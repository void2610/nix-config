{ pkgs }:
pkgs.buildNpmPackage rec {
  pname = "claude-code-ui";
  version = "1.27.1";
  nodejs = pkgs.nodejs_22;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@siteboon/claude-code-ui/-/claude-code-ui-${version}.tgz";
    hash = "sha512-jyMIquTFyokODwmAkOVyeR/+KbKodiviFrr4WdH9Yy6U+yyMtP2JDSaxcMMQhHuGpvL3bkUIS2Y5TbQtGCAA6g==";
  };

  npmDepsHash = "sha256-ILQOfHCvN1ebPtB5Ae3BXFINS8r6PPRdlRVjbSI2w0c=";

  postPatch = ''
    cp ${./claude-code-ui-package-lock.json} package-lock.json
  '';

  nativeBuildInputs = with pkgs; [
    python3
    pkg-config
    makeWrapper
  ];

  dontNpmBuild = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@siteboon/claude-code-ui
    cp -r . $out/lib/node_modules/@siteboon/claude-code-ui

    mkdir -p $out/bin
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/claude-code-ui \
      --add-flags "$out/lib/node_modules/@siteboon/claude-code-ui/server/cli.js"
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/cloudcli \
      --add-flags "$out/lib/node_modules/@siteboon/claude-code-ui/server/cli.js"

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Web-based UI for Claude Code CLI";
    homepage = "https://cloudcli.ai";
    license = licenses.gpl3Only;
    mainProgram = "claude-code-ui";
    platforms = platforms.darwin;
  };
}
