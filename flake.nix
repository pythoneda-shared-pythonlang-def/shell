# shell/flake.nix
#
# This file defines a nix flake for pythoneda-shared-pythonlang/shell.
#
# GNU GENERAL PUBLIC LICENSE
# Version 3, 29 June 2007
#
# Copyright (C) 2024-today rydnr https://github.com/pythoneda-shared-pythonlang-def/shell
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
{
  description = "Nix flake for pythoneda-shared-pythonlang/shell";
  inputs = rec {
    flake-utils = { url = "github:numtide/flake-utils/v1.0.0"; };
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    pythoneda-shared-pythonlang-banner = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.85";
    };
    pythoneda-shared-pythonlang-domain = {
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pythoneda-shared-pythonlang-banner.follows =
        "pythoneda-shared-pythonlang-banner";
      url = "github:pythoneda-shared-pythonlang-def/domain/0.0.131";
    };
  };
  outputs = inputs:
    with inputs;
    let
      defaultSystems = flake-utils.lib.defaultSystems;
      supportedSystems = if builtins.elem "armv6l-linux" defaultSystems then
        defaultSystems
      else
        defaultSystems ++ [ "armv6l-linux" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        org = "pythoneda-shared-pythonlang";
        repo = "shell";
        version = "0.0.4";
        sha256 = "15aszjj7kpm4c0jgn1w36zsv026h2vg9isd66p6hz65x0sc32a6q";
        pname = "${org}-${repo}";
        pythonpackage = "pythoneda.shared.shell";
        package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
        entrypoint = "shell_app";
        description = "shared domain for shell operations";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>" ];
        archRole = "S";
        space = "D";
        layer = "D";
        nixpkgsVersion = builtins.readFile "${nixpkgs}/.version";
        nixpkgsRelease =
          builtins.replaceStrings [ "\n" ] [ "" ] "nixpkgs-${nixpkgsVersion}";
        shared = import "${pythoneda-shared-pythonlang-banner}/nix/shared.nix";
        pkgs = import nixpkgs { inherit system; };
        pythoneda-shared-pythonlang-shell-for = { python
          , pythoneda-shared-pythonlang-banner
          , pythoneda-shared-pythonlang-domain }:
          let
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
            banner_file = "${package}/shell_banner.py";
            banner_class = "shellBanner";
          in python.pkgs.buildPythonPackage rec {
            inherit pname version;
            projectDir = ./.;
            pyprojectTomlTemplate = ./templates/pyproject.toml.template;
            pyprojectToml = pkgs.substituteAll {
              authors = builtins.concatStringsSep ","
                (map (item: ''"${item}"'') maintainers);
              desc = description;
              inherit homepage pname pythonMajorMinorVersion package
                version;
              pythonedaSharedPythonlangDomain =
                pythoneda-shared-pythonlang-domain.version;
              src = pyprojectTomlTemplate;
            };
            bannerTemplateFile =
              "${pythoneda-shared-pythonlang-banner}/templates/banner.py.template";
            bannerTemplate = pkgs.substituteAll {
              project_name = pname;
              file_path = banner_file;
              inherit banner_class org repo;
              tag = version;
              pescio_space = space;
              arch_role = archRole;
              hexagonal_layer = layer;
              python_version = pythonMajorMinorVersion;
              nixpkgs_release = nixpkgsRelease;
              src = bannerTemplateFile;
            };

            entrypointTemplateFile =
              "${pythoneda-shared-pythonlang-banner}/templates/entrypoint.sh.template";
            entrypointTemplate = pkgs.substituteAll {
              arch_role = archRole;
              hexagonal_layer = layer;
              nixpkgs_release = nixpkgsRelease;
              inherit homepage maintainers org python repo version;
              pescio_space = space;
              python_version = pythonMajorMinorVersion;
              pythoneda_shared_banner = pythoneda-shared-pythonlang-banner;
              pythoneda_shared_domain = pythoneda-shared-pythonlang-domain;
              src = entrypointTemplateFile;
            };
            src = pkgs.fetchFromGitHub {
              owner = org;
              rev = version;
              inherit repo sha256;
            };

            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip poetry-core ];
            propagatedBuildInputs = with python.pkgs; [
              pythoneda-shared-pythonlang-banner
              pythoneda-shared-pythonlang-domain
            ];

            # pythonImportsCheck = [ pythonpackage ];

            unpackPhase = ''
              command cp -r ${src}/* .
              command chmod -R +w .
              command cp ${pyprojectToml} ./pyproject.toml
              command cp ${bannerTemplate} ./${banner_file}
              command cp ${entrypointTemplate} ./entrypoint.sh
            '';

            postPatch = ''
              substituteInPlace ./entrypoint.sh \
                --replace "@SOURCE@" "$out/bin/${entrypoint}.sh" \
                --replace "@PYTHONPATH@" "$PYTHONPATH:$out/lib/python${pythonMajorMinorVersion}/site-packages" \
                --replace "@CUSTOM_CONTENT@" "" \
                --replace "@ENTRYPOINT@" "$out/lib/python${pythonMajorMinorVersion}/site-packages/${package}/application/${entrypoint}.py" \
                --replace "@BANNER@" "$out/bin/banner.sh"
            '';

            postInstall = with python.pkgs; ''
              for f in $(command find . -name '__init__.py'); do
                if [[ ! -e $out/lib/python${pythonMajorMinorVersion}/site-packages/$f ]]; then
                  command cp $f $out/lib/python${pythonMajorMinorVersion}/site-packages/$f;
                fi
              done
              command mkdir -p $out/dist $out/bin $out/deps/flakes
              command cp dist/${wheelName} $out/dist
              command cp ./entrypoint.sh $out/bin/${entrypoint}.sh
              command chmod +x $out/bin/${entrypoint}.sh
              command echo '#!/usr/bin/env sh' > $out/bin/banner.sh
              command echo "export PYTHONPATH=$PYTHONPATH" >> $out/bin/banner.sh
              command echo "${python}/bin/python $out/lib/python${pythonMajorMinorVersion}/site-packages/${banner_file} \$@" >> $out/bin/banner.sh
              command chmod +x $out/bin/banner.sh
              for dep in ${pythoneda-shared-pythonlang-banner} ${pythoneda-shared-pythonlang-domain}; do
                command cp -r $dep/dist/* $out/deps || true
                if [ -e $dep/deps ]; then
                  command cp -r $dep/deps/* $out/deps || true
                fi
                METADATA=$dep/lib/python${pythonMajorMinorVersion}/site-packages/*.dist-info/METADATA
                NAME="$(command grep -m 1 '^Name: ' $METADATA | command cut -d ' ' -f 2)"
                VERSION="$(command grep -m 1 '^Version: ' $METADATA | command cut -d ' ' -f 2)"
                command ln -s $dep $out/deps/flakes/$NAME-$VERSION || true
              done
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        defaultPackage = packages.default;
        devShells = rec {
          default = pythoneda-shared-pythonlang-shell-python312;
          pythoneda-shared-pythonlang-shell-python39 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-pythonlang-shell-python39;
            python = pkgs.python39;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-shared-pythonlang-shell-python310 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-pythonlang-shell-python310;
            python = pkgs.python310;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-shared-pythonlang-shell-python311 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-pythonlang-shell-python311;
            python = pkgs.python311;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python311;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-shared-pythonlang-shell-python312 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-pythonlang-shell-python312;
            python = pkgs.python312;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python312;
            inherit archRole layer org pkgs repo space;
          };
          pythoneda-shared-pythonlang-shell-python313 = shared.devShell-for {
            banner = "${
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python313
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.pythoneda-shared-pythonlang-shell-python313;
            python = pkgs.python313;
            pythoneda-shared-pythonlang-banner =
              pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python313;
            pythoneda-shared-pythonlang-domain =
              pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python313;
            inherit archRole layer org pkgs repo space;
          };
        };
        packages = rec {
          default = pythoneda-shared-pythonlang-shell-python312;
          pythoneda-shared-pythonlang-shell-python39 =
            pythoneda-shared-pythonlang-shell-for {
              python = pkgs.python39;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python39;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python39;
            };
          pythoneda-shared-pythonlang-shell-python310 =
            pythoneda-shared-pythonlang-shell-for {
              python = pkgs.python310;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python310;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python310;
            };
          pythoneda-shared-pythonlang-shell-python311 =
            pythoneda-shared-pythonlang-shell-for {
              python = pkgs.python311;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python311;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python311;
            };
          pythoneda-shared-pythonlang-shell-python312 =
            pythoneda-shared-pythonlang-shell-for {
              python = pkgs.python312;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python312;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python312;
            };
          pythoneda-shared-pythonlang-shell-python313 =
            pythoneda-shared-pythonlang-shell-for {
              python = pkgs.python313;
              pythoneda-shared-pythonlang-banner =
                pythoneda-shared-pythonlang-banner.packages.${system}.pythoneda-shared-pythonlang-banner-python313;
              pythoneda-shared-pythonlang-domain =
                pythoneda-shared-pythonlang-domain.packages.${system}.pythoneda-shared-pythonlang-domain-python313;
            };
        };
      });
}
