{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix;
  wg0 = vars.wg.wg0;

  wg0Peers = {
    "Yura-TPX13" = {
      allowedIPs = [ "${wg0.p4}.3/32" "${wg0.p6}:3:0/112" ];
      publicKey = "iJa5JmJbMHNlbEluNwoB2Q8LyrPAfb7S/mluanMcI08=";
      pskEnabled = true;
    };
    "Yura-Pixel7Pro" = {
      allowedIPs = [ "${wg0.p4}.4/32" "${wg0.p6}:4:0/112" ];
      publicKey = "UjZlsukmAsX60Z5FnZwKCSu141Gjj74+hBVT3TRhwT4=";
      pskEnabled = true;
    };
    "AsusS513" = {
      allowedIPs = [ "${wg0.p4}.100/32" ];
      publicKey = "XozJ7dHdJfkLORkCVxaB1VmvHEOAA285kRZcmzfPl38=";
      pskEnabled = false;
    };
  };
  peerSecretName = name: "wg0-peer-${name}-psk";
  secrets = config.secrix.services.systemd-networkd.secrets;
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

  systemd.network.netdevs = {
    "10-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };
      wireguardConfig = {
        PrivateKeyFile = secrets.wg0-private-key.decrypted.path;
        ListenPort = 18596;
      };
      wireguardPeers = map (peer: {
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
        Address = [ wg0.addr4Sized wg0.addr6Sized ];
      };
    };
  };
}
