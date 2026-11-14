{
  lib,
  buildPythonPackage,
  fetchPypi,
  fetchurl,
  setuptools,
  setuptools-scm,
  pytestCheckHook,
  pytest-cov-stub,
  vcrpy,
  citeproc-py,
  looseversion,
  requests,
}:

buildPythonPackage rec {
  pname = "duecredit";
  version = "0.11.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-e1wa4Qkn+eAs9NVOLHSoqgDNKcONY33v48lI09jp8zo=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    citeproc-py
    looseversion
    requests
  ];

  nativeCheckInputs = [
    pytestCheckHook
    pytest-cov-stub
    vcrpy
  ];
  disabledTests = [ "test_import_doi" ]; # tries to access network

  # citeproc-py removed the default style used by duecredit.
  # https://github.com/citeproc-py/citeproc-py/pull/197
  postPatch =
    let
      harvard1 = fetchurl {
        url = "https://raw.githubusercontent.com/citeproc-py/citeproc-py/1ae4985d8a9bacdb36e87a0001961bbe73627e73/citeproc/data/styles/harvard1.csl";
        hash = "sha256-zwUcZ+pvhK6TMIddSb8xP4jAUxszA6+8/0F/VjC8SyM=";
      };
    in
    ''
      substituteInPlace duecredit/io.py \
        --replace-fail 'cp.CitationStylesStyle(style, validate=False)' \
          'cp.CitationStylesStyle("${harvard1}" if style == "harvard1" else style, validate=False)'
    '';

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  pythonImportsCheck = [ "duecredit" ];

  meta = {
    homepage = "https://github.com/duecredit/duecredit";
    description = "Simple framework to embed references in code";
    mainProgram = "duecredit";
    changelog = "https://github.com/duecredit/duecredit/releases/tag/${version}";
    license = with lib.licenses; [
      bsd2
      cc-by-sa-30
    ];
    maintainers = [ lib.maintainers.bcdarwin ];
  };
}
