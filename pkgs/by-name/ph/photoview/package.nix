{
  lib,
  buildGoModule,
  fetchFromGitHub,
  callPackage,
  makeWrapper,
  pkg-config,
  # Native dependencies for image processing and face recognition
  dlib,
  libjpeg,
  libheif,
  blas,
  lapack,
  # Runtime dependencies
  exiftool,
  darktable,
  ffmpeg,
}:

buildGoModule (finalAttrs: {
  pname = "photoview";
  version = "2.4.0";

  src = fetchFromGitHub {
    owner = "photoview";
    repo = "photoview";
    rev = "v${finalAttrs.version}";
    hash = "sha256-ZfvBdQlyqONsrviZGL22Kt+AiPaVWwdoREDUrHDYyIs=";
  };

  vendorHash = "sha256-Tn4OxSV41s/4n2Q3teJRJNc39s6eKW4xE9wW/CIR5Fg=";

  modRoot = "api";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    dlib
    libjpeg
    libheif
    blas
    lapack
  ];

  postConfigure = ''
    # Fix Go bindings for libheif's typedef'd enums, as in upstream:
    # https://github.com/strukturag/libheif/commit/66c5196d3ba3b1decb40e068eca34d39731c5c86
    substituteInPlace vendor/github.com/strukturag/libheif/go/heif/heif.go \
      --replace-fail 'uint32(compression)' 'C.heif_compression_format(compression)' \
      --replace-fail 'uint32(colorspace)' 'C.heif_colorspace(colorspace)' \
      --replace-fail 'uint32(chroma)' 'C.heif_chroma(chroma)' \
      --replace-fail 'uint32(channel)' 'C.heif_channel(channel)'
  '';

  postInstall = ''
    # Install face recognition models
    mkdir -p $out/share/photoview
    cp -r ${finalAttrs.src}/api/data $out/share/photoview/

    # Symlink the UI
    ln -s ${finalAttrs.passthru.ui} $out/share/photoview/ui

    # Rename binary and wrap with runtime dependencies
    mv $out/bin/api $out/bin/photoview
    wrapProgram $out/bin/photoview \
      --set PHOTOVIEW_FACE_RECOGNITION_MODELS_PATH $out/share/photoview/data/models \
      --set PHOTOVIEW_UI_PATH $out/share/photoview/ui \
      --set PHOTOVIEW_SERVE_UI 1 \
      --prefix PATH : ${
        lib.makeBinPath [
          exiftool
          darktable
          ffmpeg
        ]
      }
  '';

  passthru.ui = callPackage ./ui.nix { inherit (finalAttrs) src version; };

  meta = {
    description = "Photo gallery for self-hosted personal servers";
    homepage = "https://photoview.github.io/";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ nettika ];
    mainProgram = "photoview";
    platforms = lib.platforms.linux;
  };
})
