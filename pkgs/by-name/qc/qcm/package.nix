{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch2,
  cmake,
  pkg-config,
  qt6,
  curl,
  ffmpeg,
  cubeb,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qcm";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "hypengw";
    repo = "Qcm";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-41GsG+NKCMw+LuRUf31ilRso/SkKYVV3IrMSviOZdWs=";
  };

  patches = [
    ./remove_cubeb_vendor.patch
    # Include QElapsedTimer explicitly with recent Qt versions.
    # https://github.com/hypengw/QmlMaterial/pull/12
    (fetchpatch2 {
      url = "https://github.com/hypengw/QmlMaterial/commit/88a79980b6584adbbaa94a35053f19f5dd26edf8.patch";
      extraPrefix = "qml_material/";
      stripLen = 1;
      hash = "sha256-mLORE6H8SzO8mGMGcegGkW4lkEKSsksappUINO1Imk0=";
    })
  ];

  # Qt 6.10 requires private components to be found explicitly.
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'COMPONENTS Core Quick ShaderTools' 'COMPONENTS Core Quick ShaderTools GuiPrivate QuickPrivate'
    substituteInPlace core/log.cpp \
      --replace-fail '#include <cstdio>' $'#include <cstdio>\n#include <unistd.h>'
    substituteInPlace request/session_share.cpp \
      --replace-fail '#include "curl_easy.h"' $'#include "curl_easy.h"\n#include <mutex>'
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtwayland
    curl
    ffmpeg
    cubeb
  ];

  # Correct qml import path
  postInstall = ''
    mv $out/lib/qt6 $out/lib/qt-6
  '';

  meta = {
    description = "Unofficial Qt client for netease cloud music";
    homepage = "https://github.com/hypengw/Qcm";
    license = lib.licenses.gpl2Plus;
    mainProgram = "Qcm";
    maintainers = with lib.maintainers; [ aleksana ];
    platforms = lib.platforms.linux;
  };
})
