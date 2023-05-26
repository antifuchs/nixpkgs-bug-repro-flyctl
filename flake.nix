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

    testapp = pkgs: {
      go = pkgs {
        name = "testapp";
        version = "0.0.1";
        src = ./testapp;
        vendorHash = null;
      };

      cgo = pkgs.buildGoModule {
        name = "testapp";
        version = "0.0.1";
        src = ./testapp;
        vendorHash = null;
        CGO_ENABLED=1;
        tags = ["enablecgo"];
      };

      go19 = pkgs.buildGo119Module {
        name = "testapp";
        version = "0.0.1";
        src = ./testapp-go19;
        vendorHash = null;
      };

      cgo19 = pkgs.buildGo119Module {
        name = "testapp";
        version = "0.0.1";
        src = ./testapp-go19;
        vendorHash = null;
        CGO_ENABLED=1;
        tags = ["enablecgo"];
      };
    };

    diagnostics = pkgs-stable.writeShellScript "diagnostics" ''
      set -x
      ulimit -a
      export
      readlink /proc/$$/task/*/ns/* | sort -u
    '';

  in {
    apps.x86_64-linux.stable = {program = "${pkgs-stable.flyctl}/bin/flyctl"; type = "app";};
    apps.x86_64-linux.unstable = { program = "${pkgs-unstable.flyctl}/bin/flyctl"; type = "app";};
    apps.x86_64-linux.latest = { program = "${patched-flyctl}/bin/flyctl"; type = "app";};

    apps.x86_64-linux.userenv-stable = {program = "${(userenv {pkgs = pkgs-stable; flyctl = pkgs-stable.flyctl;})}/bin/run-flyctl"; type = "app";};
    apps.x86_64-linux.userenv-unstable = { program = "${(userenv {pkgs = pkgs-unstable; flyctl = pkgs-unstable.flyctl;})}/bin/run-flyctl"; type = "app";};
    apps.x86_64-linux.userenv-latest = { program = "${(userenv {flyctl = patched-flyctl; pkgs = pkgs-unstable;})}/bin/run-flyctl"; type = "app";};

    apps.x86_64-linux.testapp = {program = "${(testapp pkgs-unstable).go}/bin/testapp"; type= "app";};
    apps.x86_64-linux.testapp-cgo = {program = "${(testapp pkgs-unstable).cgo}/bin/testapp"; type= "app";};
    apps.x86_64-linux.testapp-go19 = {program = "${(testapp pkgs-unstable).go19}/bin/testapp"; type= "app";};
    apps.x86_64-linux.testapp-cgo19 = {program = "${(testapp pkgs-unstable).cgo19}/bin/testapp"; type= "app";};

    apps.x86_64-linux.stable-testapp = {program = "${(testapp pkgs-stable).go}/bin/testapp"; type= "app";};
    apps.x86_64-linux.stable-testapp-cgo = {program = "${(testapp pkgs-stable).cgo}/bin/testapp"; type= "app";};
    apps.x86_64-linux.stable-testapp-go19 = {program = "${(testapp pkgs-stable).go19}/bin/testapp"; type= "app";};
    apps.x86_64-linux.stable-testapp-cgo19 = {program = "${(testapp pkgs-stable).cgo19}/bin/testapp"; type= "app";};

    apps.x86_64-linux.diagnostics = {program = "${diagnostics}"; type="app";};
 };
}
