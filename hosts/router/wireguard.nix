{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix;

  wg0Peers = {
    "Yura-TPX13" = {
      allowedIPs = [ "10.6.0.3/32" "${vars.extra.opnsense.p6}::6:3:0/112" ];
      publicKey = "iJa5JmJbMHNlbEluNwoB2Q8LyrPAfb7S/mluanMcI08=";
      pskEnabled = true;
    };
    "Yura-Pixel7Pro" = {
      allowedIPs = [ "10.6.0.4/32" "${vars.extra.opnsense.p6}::6:4:0/112" ];
      publicKey = "UjZlsukmAsX60Z5FnZwKCSu141Gjj74+hBVT3TRhwT4=";
      pskEnabled = true;
    };
    "AsusS513" = {
      allowedIPs = [ "10.6.0.100/32" ];
      publicKey = "XozJ7dHdJfkLORkCVxaB1VmvHEOAA285kRZcmzfPl38=";
      pskEnabled = true;
    };
  };
in
{
  secrix.services.systemd-networkd.secrets = let
    peerSecretName = name: "wg0-peer-${name}-psk";
    mapPeer = name: peer: {
      name = peerSecretName name;
      value = if peer.pskEnabled then {encrypted.file = ./secrets/wireguard/${peerSecretName name}.age;} else null;
    };
    peerSecrets = lib.attrsets.mapAttrs' mapPeer wg0Peers;
  in
  {
    wg0-private-key.encrypted.file = ./secrets/wireguard/wg0-private-key.age;
  } // peerSecrets;

  systemd.network.netdevs = let
    secrets = config.secrix.services.systemd-networkd.secrets;
  in
  {
    "10-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };
      wireguardConfig = {
        PrivateKeyFile = secrets.wg0-private-key.decrypted.path;
        ListenPort = 18596;
      };
      wireguardPeers = lib.attrsets.foldlAttrs (name: peer: acc: acc ++ [{
        AllowedIPs = lib.strings.concatStringsSep "," peer.allowedIPs;
        PublicKey = peer.publicKey;
        PresharedKeyFile = if peer.pskEnabled then secrets."wg0-peer-${name}-psk".decrypted.path else null;
      }]) [] wg0Peers;
    };
  };
}
