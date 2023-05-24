{
  description = "Test case for flyctl under nixpkgs";

  inputs = {
    stable.url = "github:NixOS/nixpkgs/release-22.11";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flyctl-0-1-12 = {
      url = "github:superfly/flyctl/v0.1.12";
      flake = false;
    };
  };

  outputs = { self, stable, unstable, flyctl-0-1-12 }: let
    pkgs-stable = stable.legacyPackages.x86_64-linux;
    pkgs-unstable = unstable.legacyPackages.x86_64-linux;
    patched-flyctl = pkgs-unstable.flyctl.overrideAttrs (o: {
      version = "0.1.12";
      src = flyctl-0-1-12;
    });
  in {

    apps.x86_64-linux.stable = {program = "${pkgs-stable.flyctl}/bin/flyctl"; type = "app";};
    apps.x86_64-linux.unstable = { program = "${pkgs-unstable.flyctl}/bin/flyctl"; type = "app";};
    apps.x86_64-linux.latest = { program = "${patched-flyctl}/bin/flyctl"; type = "app";};
  };
}
