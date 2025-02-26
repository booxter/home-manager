# Confirm that both Firefox and Thunderbird can be configured at the same time.
{ lib, realPkgs, ... }:
lib.recursiveUpdate (import ./thunderbird.nix { inherit lib realPkgs; }) {
  programs.firefox = {
    enable = true;
    package = realPkgs.firefox;
  };
}
