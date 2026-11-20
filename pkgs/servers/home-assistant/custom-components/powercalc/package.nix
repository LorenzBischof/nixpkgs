{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  fetchpatch2,

  # dependencies
  numpy,

  # tests
  aioresponses,
  gitMinimal,
  gitpython,
  home-assistant,
  jsonschema,
  pytest-freezegun,
  pytest-homeassistant,
  pytestCheckHook,
}:

buildHomeAssistantComponent (finalAttrs: {
  owner = "bramstroker";
  domain = "powercalc";
  version = "1.27.0";

  src = fetchFromGitHub {
    owner = "bramstroker";
    repo = "homeassistant-powercalc";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cutPSIXOPrA1PkFbgRxZWoiQxpS/nbaJvKdBKJJ+Ne0=";
  };

  patches = [
    # Migrate tests to pytest-homeassistant for Home Assistant 2026.11
    # https://github.com/bramstroker/homeassistant-powercalc/pull/5202
    (fetchpatch2 {
      url = "https://github.com/bramstroker/homeassistant-powercalc/commit/d6b4db627e9d12be94288a1248de580a53f12f82.patch?full_index=1";
      excludes = [
        "tests/strategy/test_battery_rate.py"
        "uv.lock"
      ];
      hash = "sha256-srRh7hl1FraslYwYRqsnTpa7paJSvlSZ77kYrmqcFY0=";
    })
  ];

  dependencies = [ numpy ];

  nativeCheckInputs = [
    aioresponses
    gitMinimal
    gitpython
    home-assistant
    jsonschema
    pytest-freezegun
    pytest-homeassistant
    pytestCheckHook
  ];

  # tests share tests/testing_config/.storage, so parallel workers race on it
  dontUsePytestXdist = true;

  preCheck = ''
    patchShebangs --build tests/setup.sh
    tests/setup.sh
  '';

  meta = {
    changelog = "https://github.com/bramstroker/homeassistant-powercalc/releases/tag/${finalAttrs.src.tag}";
    description = "Custom Home Assistant component for virtual power sensors";
    homepage = "https://github.com/bramstroker/homeassistant-powercalc";
    maintainers = with lib.maintainers; [ CodedNil ];
    license = lib.licenses.mit;
  };
})
