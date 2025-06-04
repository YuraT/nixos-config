{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix;
  wg0 = vars.ifs.wg0;

  peerIps = ifObj: token: [
    "${ifObj.p4}.${toString token}/32"
    "${ifObj.p6}:${toString token}:0/112"
    "${ifObj.ulaPrefix}:${toString token}:0/112"
  ];

  mkWg0Peer = token: publicKey: {
    allowedIPs = peerIps wg0 token;
    inherit publicKey;
    pskEnabled = true;
  };

  wg0Peers = {
    "Yura-TPX13" = mkWg0Peer 100 "iFdsPYrpw7vsFYYJB4SOTa+wxxGVcmYp9CPxe0P9ewA=";
    "Yura-Pixel7Pro" = mkWg0Peer 101 "GPdXxjvnhsyufd2QX/qsR02dinUtPnnxrE66oGt/KyA=";
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
      value.decrypted.user = "systemd-network";
      value.decrypted.group = "systemd-network";
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
        Name = wg0.name;
      };
      wireguardConfig = {
        PrivateKeyFile = secrets.wg0-private-key.decrypted.path;
        ListenPort = wg0.listenPort;
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
        Address = [ wg0.addr4Sized wg0.addr6Sized wg0.ulaAddrSized ];
      };
    };
  };
}
