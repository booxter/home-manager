modulePath:
{ config, lib, pkgs, ... }:

let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

  withName = path:
    pkgs.substituteAll {
      src = path;
      name = cfg.wrappedPackageName;
    };

in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (lib.setAttrByPath modulePath {
    enable = true;
    profiles.bookmarks = {
      settings = { "general.smoothScroll" = false; };
      bookmarks = [
        {
          toolbar = true;
          bookmarks = [{
            name = "Home Manager";
            url = "https://wiki.nixos.org/wiki/Home_Manager";
          }];
        }
        {
          name = "wikipedia";
          tags = [ "wiki" ];
          keyword = "wiki";
          url = "https://en.wikipedia.org/wiki/Special:Search?search=%s&go=Go";
        }
        {
          name = "kernel.org";
          url = "https://www.kernel.org";
        }
        {
          name = "Nix sites";
          bookmarks = [
            {
              name = "homepage";
              url = "https://nixos.org/";
            }
            {
              name = "wiki";
              tags = [ "wiki" "nix" ];
              url = "https://wiki.nixos.org/";
            }
            {
              name = "Nix sites";
              bookmarks = [
                {
                  name = "homepage";
                  url = "https://nixos.org/";
                }
                {
                  name = "wiki";
                  url = "https://wiki.nixos.org/";
                }
              ];
            }
          ];
        }
      ];
    };
  } // {
    nmt.script = let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      profilePath = if isDarwin then
        "Library/Application Support/Firefox/Profiles"
      else
        ".mozilla/firefox";
    in ''
      bookmarksUserJs=$(normalizeStorePaths \
        "home-files/${profilePath}/bookmarks/user.js")

      assertFileContent \
        $bookmarksUserJs \
        ${withName ./expected-bookmarks-user.js}

      bookmarksFile="$(sed -n \
        '/browser.bookmarks.file/ {s|^.*\(/nix/store[^"]*\).*|\1|;p}' \
        $TESTED/home-files/'${profilePath}'/bookmarks/user.js)"""

      echo "bookmarksFile: $bookmarksFile"

      assertFileContent \
        $bookmarksFile \
        ${./expected-bookmarks.html}
    '';
  });
}
