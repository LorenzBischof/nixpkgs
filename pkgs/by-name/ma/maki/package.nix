{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gitUpdater,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "maki";
  version = "8.0.1";

  src = fetchFromGitHub {
    owner = "mapbox";
    repo = "maki";
    tag = "v${finalAttrs.version}";
    hash = "sha256-aQbGNLHy7WxCRNWiRS812PIpFukwGkAMc57fX4PBZyI=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm444 -t $out/share/maki/icons icons/*.svg

    runHook postInstall
  '';

  passthru.updateScript = gitUpdater { rev-prefix = "v"; };

  meta = {
    description = "Point of interest icon set for maps";
    homepage = "https://labs.mapbox.com/maki-icons/";
    license = lib.licenses.cc0;
    maintainers = with lib.maintainers; [ LorenzBischof ];
    teams = [ lib.teams.geospatial ];
    platforms = lib.platforms.all;
  };
})
