{ pkgs, melchiorRepo }:
let
  # Homebrew 側のライブラリと Nix の toolchain を混ぜると macOS の SDK がずれやすい。
  # そのため、Melchior のコンパイルとリンクは Command Line Tools の純正 toolchain に寄せる。
  nativeSdkRoot = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk";
  nativeDeploymentTarget = "26.0";

  # pyquaternion は upstream のテストが現在の NumPy と噛み合わず、
  # 開発環境を作るだけで失敗することがあるためテストを外して使う。
  pyquaternionNoTests = pkgs.python312Packages.pyquaternion.overridePythonAttrs (_: {
    doCheck = false;
  });

  # Segment Anything は nixpkgs に無いため PyPI から package 化する。
  segmentAnything = pkgs.python312Packages.buildPythonPackage rec {
    pname = "segment-anything";
    version = "1.0";
    format = "setuptools";
    src = pkgs.fetchPypi {
      pname = "segment_anything";
      inherit version;
      hash = "sha256-7Qyfb7B7vvnGI4pwKKE8gnLxumtjBcpz4+BkJmUDc2s=";
    };
    propagatedBuildInputs = with pkgs.python312Packages; [
      torch
      torchvision
    ];
    doCheck = false;
    pythonImportsCheck = [ "segment_anything" ];
  };

  # Melchior 本体の埋め込み Python が見る package 群。
  # ここには OpenCV を入れず、埋め込み Python 側のネイティブ衝突を避ける。
  melchiorPythonPackages = ps: with ps; [
    numpy
    scipy
    ezdxf
    shapely
    numba
    requests
    tqdm
    matplotlib
    tensorboard
    laspy
    coverage
    pyproj
    staticmap
    torch
    torchvision
    pyquaternionNoTests
  ];

  # SAM 実行用の別プロセス Python で使う package 群。
  # こちらには OpenCV を含める。
  melchiorSamPackages = ps: with ps; [
    opencv-python
    torch
    torchvision
    segmentAnything
  ];

  # Melchior 本体用 Python と、CLI / SAM 実行用 Python を分ける。
  melchiorPython = pkgs.python312.withPackages melchiorPythonPackages;
  melchiorCliPython = pkgs.python312.withPackages (ps:
    (melchiorPythonPackages ps) ++ (melchiorSamPackages ps)
  );

  melchiorEmbeddedSitePackages = "${melchiorPython}/${melchiorPython.sitePackages}";
  melchiorSamSitePackages = "${melchiorCliPython}/${melchiorCliPython.sitePackages}";

  # shellHook は役割ごとに分割し、最後に入口スクリプトから source する。
  melchiorEnvScript = pkgs.replaceVars ./env.sh {
    inherit melchiorRepo nativeSdkRoot nativeDeploymentTarget;

    python312 = pkgs.python312;
    cmakeBin = "${pkgs.cmake}/bin/cmake";
    melchiorEmbeddedSitePackages = melchiorEmbeddedSitePackages;
    melchiorSamSitePackages = melchiorSamSitePackages;
    extraLinkFlags = "-L${pkgs.glfw}/lib -L${pkgs.glew.out}/lib -L${pkgs.lz4.lib}/lib -L${pkgs.proj.out}/lib -L${pkgs.xz.out}/lib -L${pkgs.zstd.out}/lib";

    assimp = pkgs.assimp;
    bullet = pkgs.bullet;
    cgns = pkgs.cgns;
    eigen = pkgs.eigen;
    freetypeDev = pkgs.freetype.dev;
    freetypeOut = pkgs.freetype.out;
    glfw = pkgs.glfw;
    glew = pkgs.glew;
    glewDev = pkgs.glew.dev;
    glewOut = pkgs.glew.out;
    glm = pkgs.glm;
    jsoncpp = pkgs.jsoncpp;
    jsoncppDev = pkgs.jsoncpp.dev;
    libharu = pkgs.libharu;
    libjpegDev = pkgs.libjpeg.dev;
    libjpegOut = pkgs.libjpeg.out;
    lz4Dev = pkgs.lz4.dev;
    lz4Lib = pkgs.lz4.lib;
    libpng = pkgs.libpng;
    libusb1 = pkgs.libusb1;
    libusb1Dev = pkgs.libusb1.dev;
    opencv = pkgs.opencv;
    pcl = pkgs.pcl;
    proj = pkgs.proj;
    projDev = pkgs.proj.dev;
    projOut = pkgs.proj.out;
    xzDev = pkgs.xz.dev;
    xzOut = pkgs.xz.out;
    zstdDev = pkgs.zstd.dev;
    zstdOut = pkgs.zstd.out;
  };
  melchiorGlewScript = pkgs.replaceVars ./glew.sh {
    glewDev = pkgs.glew.dev;
    glewConfigPath = "${melchiorRepo}/.nix-melchior/cmake/glew/glew-config.cmake";
  };
  melchiorWrappersScript = pkgs.replaceVars ./wrappers.sh {
    cmakeBin = "${pkgs.cmake}/bin/cmake";
    ninjaBin = "${pkgs.ninja}/bin/ninja";
  };
  melchiorSitePackagesScript = pkgs.replaceVars ./site-packages.sh { };
  melchiorShellFunctionsScript = pkgs.replaceVars ./shell-functions.sh { };
  melchiorShellHook = pkgs.replaceVars ./shell-hook.sh {
    envScript = melchiorEnvScript;
    glewScript = melchiorGlewScript;
    wrappersScript = melchiorWrappersScript;
    sitePackagesScript = melchiorSitePackagesScript;
    shellFunctionsScript = melchiorShellFunctionsScript;
  };
in
pkgs.mkShell {
  packages = [
    pkgs.assimp
    pkgs.bullet
    pkgs.cgns
    pkgs.cmake
    pkgs.eigen
    pkgs.freetype
    pkgs.git
    pkgs.glew
    pkgs.glfw
    pkgs.glm
    pkgs.jsoncpp
    pkgs.libharu
    pkgs.libjpeg
    pkgs.lz4
    pkgs.libpng
    pkgs.libusb1
    pkgs.ninja
    pkgs.opencv
    pkgs.pcl
    pkgs.pkg-config
    pkgs.proj
    pkgs.xz
    pkgs.zstd
    melchiorCliPython
  ];

  shellHook = builtins.readFile melchiorShellHook;
}
