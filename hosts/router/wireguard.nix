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
      pskEnabled = false;
    };
  };
  peerSecretName = name: "wg0-peer-${name}-psk";
in
{
  secrix.services.systemd-networkd.secrets = let
    pskPeers = lib.attrsets.filterAttrs (name: peer: peer.pskEnabled) wg0Peers;
    mapPeer = name: peer: {
      name = peerSecretName name;
      value.encrypted.file = ./secrets/wireguard/${peerSecretName name}.age;
    };
    peerSecrets = lib.attrsets.mapAttrs' mapPeer pskPeers;
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
      wireguardPeers = let
        secrets = config.secrix.services.systemd-networkd.secrets;
      in
      map (peer: {
        AllowedIPs = lib.strings.concatStringsSep "," peer.value.allowedIPs;
        PublicKey = peer.value.publicKey;
        PresharedKeyFile = if peer.value.pskEnabled then secrets."${peerSecretName peer.name}".decrypted.path else null;
      }) (lib.attrsToList wg0Peers);
    };
  };

  systemd.network.networks = {
    "10-wg0" = {
      matchConfig.Name = "wg0";
      networkConfig = {
        IPv4Forwarding = true;
        IPv6SendRA = false;
        Address = [ "10.6.0.1/24" "${vars.extra.opnsense.p6}::6:0:1/96" ];
      };
    };
  };
}
