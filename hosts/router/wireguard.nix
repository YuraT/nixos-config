{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix;

  wg0Peers = [
    {
      name = "Yura-TPX13";
      allowedIPs = [ "10.6.0.3/32" "${vars.extra.opnsense.p6}::6:3:0/112" ];
      publicKey = "iJa5JmJbMHNlbEluNwoB2Q8LyrPAfb7S/mluanMcI08=";
      pskEnabled = true;
    }
    {
      name = "Yura-Pixel7Pro";
      allowedIPs = [ "10.6.0.4/32" "${vars.extra.opnsense.p6}::6:4:0/112" ];
      publicKey = "UjZlsukmAsX60Z5FnZwKCSu141Gjj74+hBVT3TRhwT4=";
      pskEnabled = true;
    }
    {
      name = "AsusS513";
      allowedIPs = [ "10.6.0.100/32" ];
      publicKey = "XozJ7dHdJfkLORkCVxaB1VmvHEOAA285kRZcmzfPl38=";
      pskEnabled = true;
    }
  ];
in
{
  secrix.services.systemd-networkd.secrets = let
    pskEnabledPeers = builtins.filter (peer: peer.pskEnabled) wg0Peers;
    peerToSecretAttrs = peer: {
      name = "wg0-peer-${peer.name}-psk";
      value.encrypted.file = ./secrets/wireguard/wg0-peer-${peer.name}-psk.age;
    };
    peerSecretsList = map peerToSecretAttrs pskEnabledPeers;
    peerSecrets = builtins.listToAttrs peerSecretsList;
  in
  {
    wg0-private-key.encrypted.file = ./secrets/wireguard/wg0-private-key.age;
  } // peerSecrets;

  systemd.network.netdevs = {
    "10-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };
      wireguardConfig = {
        PrivateKeyFile = config.secrix.services.systemd-networkd.secrets.wg0-private-key.decrypted.path;
        ListenPort = 18596;
      };
      wireguardPeers = map (peer: {
        AllowedIPs = lib.strings.concatStringsSep "," peer.allowedIPs;
        PublicKey = peer.publicKey;
        PresharedKeyFile = if peer.pskEnabled then config.secrix.services.systemd-networkd.secrets."wg0-peer-${peer.name}-psk".decrypted.path else null;
      }) wg0Peers;
    };
  };
}
