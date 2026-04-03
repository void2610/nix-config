# repo 外から入っても、Melchior repo 直下へ寄せる。
export MELCHIOR_REPO="@melchiorRepo@"
if [[ "$PWD" != "$MELCHIOR_REPO"* ]]; then
  cd "$MELCHIOR_REPO"
fi

# ビルド時に使う Python と toolchain を固定する。
export MELCHIOR_BUILD_PYTHON_ROOT="@python312@"
export MELCHIOR_BUILD_PYTHON_EXECUTABLE="@python312@/bin/python3"
export MELCHIOR_EMBEDDED_SITE_PACKAGES="@melchiorEmbeddedSitePackages@"
export MELCHIOR_SAM_SITE_PACKAGES_SRC="@melchiorSamSitePackages@"
export MELCHIOR_CMAKE_BIN="@cmakeBin@"
export MELCHIOR_EXTRA_LINK_FLAGS="@extraLinkFlags@"

export MELCHIOR_NATIVE_CLANG="/Library/Developer/CommandLineTools/usr/bin/clang"
export MELCHIOR_NATIVE_CLANGXX="/Library/Developer/CommandLineTools/usr/bin/clang++"
export MELCHIOR_NATIVE_LD="/Library/Developer/CommandLineTools/usr/bin/ld"
export CC="$MELCHIOR_NATIVE_CLANG"
export CXX="$MELCHIOR_NATIVE_CLANGXX"
export LD="$MELCHIOR_NATIVE_LD"
export SDKROOT="@nativeSdkRoot@"
export MACOSX_DEPLOYMENT_TARGET="@nativeDeploymentTarget@"

export MELCHIOR_PCL_DIR="$(dirname "$(find @pcl@ -name PCLConfig.cmake | head -n 1)")"
export MELCHIOR_BULLET_DIR="$(dirname "$(find @bullet@ -name BulletConfig.cmake | head -n 1)")"
export PCL_ROOT="@pcl@"
export Bullet_ROOT="@bullet@"
export OpenCV_ROOT="@opencv@"

# Nix 側ライブラリを CMake / compiler / linker が見つけやすいように補助パスを足す。
export CPATH="@cgns@/include:@eigen@/include/eigen3:@freetypeDev@/include/freetype2:@glfw@/include:@glewDev@/include:@glm@/include:@libharu@/include:@libjpegDev@/include:@lz4Dev@/include:@libpng@/include:@libusb1Dev@/include/libusb-1.0:@pcl@/include:@opencv@/include/opencv4:@projDev@/include:@xzDev@/include${CPATH:+:$CPATH}"
export LIBRARY_PATH="@cgns@/lib:@freetypeOut@/lib:@glfw@/lib:@glewOut@/lib:@libharu@/lib:@libjpegOut@/lib:@lz4Lib@/lib:@libpng@/lib:@libusb1@/lib:@pcl@/lib:@bullet@/lib:@opencv@/lib:@projOut@/lib:@xzOut@/lib:@zstdOut@/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
export CMAKE_INCLUDE_PATH="@cgns@/include:@eigen@/include/eigen3:@freetypeDev@/include/freetype2:@libharu@/include:@libjpegDev@/include:@lz4Dev@/include:@libpng@/include:@libusb1Dev@/include/libusb-1.0:@pcl@/include:@opencv@/include/opencv4:@projDev@/include:@xzDev@/include${CMAKE_INCLUDE_PATH:+:$CMAKE_INCLUDE_PATH}"
export CMAKE_LIBRARY_PATH="@cgns@/lib:@freetypeOut@/lib:@glfw@/lib:@glewOut@/lib:@libharu@/lib:@libjpegOut@/lib:@lz4Lib@/lib:@libpng@/lib:@libusb1@/lib:@pcl@/lib:@bullet@/lib:@opencv@/lib:@projOut@/lib:@xzOut@/lib:@zstdOut@/lib${CMAKE_LIBRARY_PATH:+:$CMAKE_LIBRARY_PATH}"
export CMAKE_PREFIX_PATH="@assimp@:@bullet@:@cgns@:@eigen@:@freetypeDev@:@glfw@:@glew@:@glm@:@jsoncpp@:@libharu@:@libjpegDev@:@lz4Dev@:@libpng@:@libusb1@:@opencv@:@pcl@:@proj@:@xzDev@:@zstdDev@${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
export PKG_CONFIG_PATH="@cgns@/lib/pkgconfig:@freetypeDev@/lib/pkgconfig:@glfw@/lib/pkgconfig:@glewOut@/lib/pkgconfig:@jsoncppDev@/lib/pkgconfig:@libharu@/lib/pkgconfig:@libjpegDev@/lib/pkgconfig:@lz4Lib@/lib/pkgconfig:@libpng@/lib/pkgconfig:@libusb1Dev@/lib/pkgconfig:@opencv@/lib/pkgconfig:@pcl@/lib/pkgconfig:@projDev@/lib/pkgconfig:@xzDev@/lib/pkgconfig:@zstdDev@/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LDFLAGS="@extraLinkFlags@ ${LDFLAGS:+$LDFLAGS}"

mkdir -p "$MELCHIOR_REPO/.nix-melchior/bin"
mkdir -p "$MELCHIOR_REPO/.nix-melchior/cmake"
