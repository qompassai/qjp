"""QJP gate (Tiger Style wave 2, 2026-10-17).

Validation: the flake evaluates clean and the repo's only test expression
(pkgs/tests/default.nix, an OCI/Jetson container test) instantiates with
the same arguments the overlay supplies (l4tVersion from overlay.nix).
Adversarial: the test expression must reject a missing required argument,
and the flake must expose the expected hardware configurations.
The OCI runtime itself needs a Jetson + container runtime with NVIDIA
passthrough; it is not runnable on an x86_64 build host and stays pinned
as a hardware test (see .ai/memory/inbox note).
"""
import shutil
import subprocess

import pytest

ROOT = __file__.rsplit("/tests/", 1)[0]
NIX = shutil.which("nix")
INST = shutil.which("nix-instantiate")
needs_nix = pytest.mark.skipif(NIX is None or INST is None, reason="nix not installed")

ARGS = ('{ l4tVersion = "35.6.1"; dockerTools = (import <nixpkgs> {}).dockerTools;'
        ' writeShellScriptBin = (import <nixpkgs> {}).writeShellScriptBin; }')


def nix_env():
    import os
    out = subprocess.run(
        [NIX, "eval", "--impure", "--raw", "--expr",
         'let f = builtins.getFlake "path:' + ROOT + '"; in f.inputs.nixpkgs.outPath'],
        capture_output=True, text=True, timeout=300)
    assert out.returncode == 0, out.stderr
    env = dict(os.environ)
    env["NIX_PATH"] = "nixpkgs=" + out.stdout.strip()
    return env


@needs_nix
def test_flake_check_no_build():
    r = subprocess.run([NIX, "flake", "check", "--no-build", "path:" + ROOT],
                       capture_output=True, text=True, timeout=900)
    assert r.returncode == 0, r.stdout + r.stderr


@needs_nix
def test_oci_test_expression_instantiates():
    expr = f'(import {ROOT}/pkgs/tests/default.nix {ARGS}).oci.name'
    r = subprocess.run([INST, "--eval", "--strict", "-E", expr],
                       capture_output=True, text=True, timeout=300, env=nix_env())
    assert r.returncode == 0, r.stderr
    assert "oci-test" in r.stdout


@needs_nix
def test_oci_test_expression_rejects_missing_arg():
    expr = f'(import {ROOT}/pkgs/tests/default.nix {{}}).oci'
    r = subprocess.run([INST, "--eval", "-E", expr],
                       capture_output=True, text=True, timeout=300)
    assert r.returncode != 0
    assert "l4tVersion" in r.stderr
