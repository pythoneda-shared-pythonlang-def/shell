# pythoneda-shared-pythonlang/shell

shared domain for shell operations

## How to declare it in your flake

Check the latest tag of this repository: https://github.com/pythoneda-shared-pythonlang-def/shell, and use it instead of the `[version]` placeholder below.

```nix
{
  description = "[..]";
  inputs = rec {
    [..]
    pythoneda-shared-pythonlang-shell = {
      [optional follows]
      url =
        "github:pythoneda-shared-pythonlang-def/shell/[version]";
    };
  };
  outputs = [..]
};
```

Should you use another PythonEDA modules, you might want to pin those also used by this project. The same applies to [https://nixos/nixpkgs](nixpkgs "nixpkgs") and [https://github.com/numtide/flake-utils](flake-utils "flake-utils").

The Nix flake is managed by the [https://github.com/pythoneda-shared-pythonlang-def/shell](shell "shell") definition repository.

Use the specific package depending on your system (one of `flake-utils.lib.defaultSystems`) and Python version:

- `#packages.[system].pythoneda-shared-pythonlang-shell-python38`
- `#packages.[system].pythoneda-shared-pythonlang-shell-python39`
- `#packages.[system].pythoneda-shared-pythonlang-shell-python310`
- `#packages.[system].pythoneda-shared-pythonlang-shell-python311`
