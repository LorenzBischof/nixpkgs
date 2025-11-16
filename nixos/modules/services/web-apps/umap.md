# Umap {#module-services-umap}

[Umap](https://umap-project.org/) is a tool to create custom maps with OpenStreetMap layers.

## Basic Usage {#module-services-umap-basic-usage}

A minimal configuration to run Umap:

```nix
{
  services.umap = {
    enable = true;
    settings.SITE_URL = "https://umap.example.com";
  };
}
```

## Create an admin account {#module-services-umap-admin-account}

Umap manages users, maps and tile layers through the Django admin site. Create an
account that can reach it:

```bash
umap-manage createsuperuser
```

This prompts for a username, email and password. Log in at `$SITE_URL/admin/`.

The preconfigured CARTO tile layer does not work out of the box, since CARTO now
requires an API key. Replace it under *Tile layers*, for example with the
standard OpenStreetMap tiles at
`https://tile.openstreetmap.org/{z}/{x}/{y}.png`. See the
[upstream documentation](https://docs.umap-project.org/en/stable/config/admin/).

## Custom pictograms {#module-services-umap-pictograms}

Umap ships no marker icons. Icon collections are served from the Nix store via
`UMAP_PICTOGRAMS_COLLECTIONS`; see the
[upstream documentation](https://docs.umap-project.org/en/stable/config/icons/)
for icon libraries to choose from.

Icons must sit directly in `pictograms/<category>/`. Umap scans exactly one
level of categories and skips anything deeper without an error, so most icon
sets need rearranging to match:

```nix
let
  pinhead = pkgs.runCommand "pinhead-pictograms" { } ''
    cd ${pkgs.fetchFromGitHub {
      owner = "waysidemapping";
      repo = "pinhead";
      tag = "v15.25.0";
      hash = "sha256-J2dTXUaZ40e11T9Bs4wAmPo4Dlt1YMWzEXcRh+8rqe8=";
    }}/icons
    for category in */; do
      install -Dm444 -t "$out/pictograms/''${category%/}" $(find "$category" -name '*.svg')
    done
    install -Dm444 -t "$out/pictograms/general" *.svg
  '';
in
{
  services.umap.settings.UMAP_PICTOGRAMS_COLLECTIONS.Pinhead = {
    path = "${pinhead}";
    attribution = "Wayside Mapping";
  };
}
```
