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

    userenv = {pkgs, flyctl}: pkgs.buildFHSUserEnv {
      name = "run-flyctl";
      targetPkgs = (pkgs: with pkgs; [flyctl]) ;
      runScript = pkgs.writeShellScript "run-flyctl" ''
        exec flyctl "$@"
      '';
    };
  in {
    apps.x86_64-linux.stable = {program = "${pkgs-stable.flyctl}/bin/flyctl"; type = "app";};
    apps.x86_64-linux.unstable = { program = "${pkgs-unstable.flyctl}/bin/flyctl"; type = "app";};
    apps.x86_64-linux.latest = { program = "${patched-flyctl}/bin/flyctl"; type = "app";};

    apps.x86_64-linux.userenv-stable = {program = "${(userenv {pkgs = pkgs-stable; flyctl = pkgs-stable.flyctl;})}/bin/run-flyctl"; type = "app";};
    apps.x86_64-linux.userenv-unstable = { program = "${(userenv {pkgs = pkgs-unstable; flyctl = pkgs-unstable.flyctl;})}/bin/run-flyctl"; type = "app";};
    apps.x86_64-linux.userenv-latest = { program = "${(userenv {flyctl = patched-flyctl; pkgs = pkgs-unstable;})}/bin/run-flyctl"; type = "app";};
 };
}
