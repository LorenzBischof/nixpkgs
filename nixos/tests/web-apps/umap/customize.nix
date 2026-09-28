{ pkgs, ... }:
let
  pictograms = pkgs.runCommand "umap-test-pictograms" { } ''
    mkdir -p $out/pictograms/test
    printf 'pictogram-collection-ok' > $out/pictograms/test/marker.svg
  '';
  # Upstream's custom statics and templates override files at their own
  # relative path, below the umap/static and umap/templates roots.
  customStatics = pkgs.writeTextDir "umap/theme.css" "body { color: red; }";
  customTemplates = pkgs.writeTextDir "umap/navigation.html" "<nav>custom-template-ok</nav>";
in
{
  name = "umap-customize";

  meta.maintainers = pkgs.umap.meta.maintainers;

  nodes.machine =
    { ... }:
    {
      services.umap = {
        enable = true;
        settings = {
          SITE_URL = "http://localhost";
          UMAP_PICTOGRAMS_COLLECTIONS.Test.path = "${pictograms}";
          UMAP_CUSTOM_STATICS = "${customStatics}";
          UMAP_CUSTOM_TEMPLATES = "${customTemplates}";
        };
      };
    };

  testScript =
    { nodes, ... }:
    let
      staticRoot = nodes.machine.systemd.services.umap.environment.STATIC_ROOT;
    in
    ''
      import json

      machine.wait_for_unit("umap.service")
      machine.wait_for_unit("nginx.service")

      machine.wait_for_open_port(80)
      machine.wait_until_succeeds("curl -sSfL http://localhost/ | grep -i umap")

      with subtest("Statics are collected at build time, not at runtime"):
          assert "${staticRoot}".startswith("/nix/store/"), "${staticRoot}"
          machine.fail("journalctl -u umap.service | grep -q 'static files copied'")

      with subtest("Custom static overrides the packaged one"):
          manifest = json.loads(machine.succeed("cat ${staticRoot}/staticfiles.json"))
          machine.succeed(
              "curl -sSfL http://localhost/static/"
              + manifest["paths"]["umap/theme.css"]
              + " | grep -q red"
          )

      with subtest("Custom template overrides the packaged one"):
          machine.succeed("curl -sSfL http://localhost/ | grep -q custom-template-ok")

      with subtest("Pictogram collection is served from the nix store via nginx"):
          src = machine.succeed(
              "curl -sSfL http://localhost/pictogram/json/ | "
              "grep -oE '/static/pictograms/[^\"]+' | head -1"
          ).strip()
          assert src, "pictogram collection not listed"
          machine.succeed(f"curl -sSfL http://localhost{src} | grep -q pictogram-collection-ok")
    '';
}
