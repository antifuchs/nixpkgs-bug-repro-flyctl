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
    patched-flyctl = with pkgs-unstable; buildGoModule rec {
      pname = "flyctl";
      version = "0.1.12";

      src = flyctl-0-1-12;

      vendorHash = "sha256-YMj4iRSXfQYCheGHQeJMd5PFDRlXGIVme0Y2heJMm3Y=";

      subPackages = [ "." ];

      ldflags = [
        "-s" "-w"
        "-X github.com/superfly/flyctl/internal/buildinfo.commit=v${version}"
        "-X github.com/superfly/flyctl/internal/buildinfo.buildDate=1970-01-01T00:00:00Z"
        "-X github.com/superfly/flyctl/internal/buildinfo.environment=production"
        "-X github.com/superfly/flyctl/internal/buildinfo.version=${version}"
      ];

      nativeBuildInputs = [ installShellFiles ];

      preBuild = ''
        go generate ./...
      '';

      preCheck = ''
        HOME=$(mktemp -d)
      '';

      postCheck = ''
        go test ./... -ldflags="-X 'github.com/superfly/flyctl/internal/buildinfo.buildDate=1970-01-01T00:00:00Z'"
      '';

      postInstall = ''
        installShellCompletion --cmd flyctl \
          --bash <($out/bin/flyctl completion bash) \
          --fish <($out/bin/flyctl completion fish) \
          --zsh <($out/bin/flyctl completion zsh)
        ln -s $out/bin/flyctl $out/bin/fly
      '';
    };
  in {
    apps.x86_64-linux.stable = {program = "${pkgs-stable.flyctl}/bin/flyctl"; type = "app";};
    apps.x86_64-linux.unstable = { program = "${pkgs-unstable.flyctl}/bin/flyctl"; type = "app";};
    apps.x86_64-linux.latest = { program = "${patched-flyctl}/bin/flyctl"; type = "app";};
  };
}
