{ config, lib, pkgs, ... }:
let
  vars = import ./vars.nix config;
  domain = vars.domain;
in
{
  # Glance dashboard
  services.glance.enable = true;
  services.glance.settings.pages = [
    {
      name = "Home";
      # hideDesktopNavigation = true; # Uncomment if needed
      columns = [
        {
          size = "small";
          widgets = [
            {
              type = "calendar";
              firstDayOfWeek = "monday";
            }
            {
              type = "rss";
              limit = 10;
              collapseAfter = 3;
              cache = "12h";
              feeds = [
                { url = "https://rtk0c.pages.dev/index.xml"; }
                { url = "https://www.yegor256.com/rss.xml"; }
                { url = "https://selfh.st/rss/"; title = "selfh.st"; }
                { url = "https://ciechanow.ski/atom.xml"; }
                { url = "https://www.joshwcomeau.com/rss.xml"; title = "Josh Comeau"; }
                { url = "https://samwho.dev/rss.xml"; }
                { url = "https://ishadeed.com/feed.xml"; title = "Ahmad Shadeed"; }
              ];
            }
            {
              type = "twitch-channels";
              channels = [
                "theprimeagen"
                "j_blow"
                "piratesoftware"
                "cohhcarnage"
                "christitustech"
                "EJ_SA"
              ];
            }
          ];
        }
        {
          size = "full";
          widgets = [
            {
              type = "group";
              widgets = [
                { type = "hacker-news"; }
                { type = "lobsters"; }
              ];
            }
            {
              type = "videos";
              channels = [
                "UCXuqSBlHAE6Xw-yeJA0Tunw" # Linus Tech Tips
                "UCR-DXc1voovS8nhAvccRZhg" # Jeff Geerling
                "UCsBjURrPoezykLs9EqgamOA" # Fireship
                "UCBJycsmduvYEL83R_U4JriQ" # Marques Brownlee
                "UCHnyfMqiRRG1u-2MsSQLbXA" # Veritasium
              ];
            }
            {
              type = "group";
              widgets = [
                {
                  type = "reddit";
                  subreddit = "technology";
                  showThumbnails = true;
                }
                {
                  type = "reddit";
                  subreddit = "selfhosted";
                  showThumbnails = true;
                }
              ];
            }
          ];
        }
        {
          size = "small";
          widgets = [
            {
              type = "weather";
              location = "San Jose, California, United States";
              units = "metric";
              hourFormat = "12h";
              # hideLocation = true; # Uncomment if needed
            }
            {
              type = "markets";
              markets = [
                { symbol = "SPY"; name = "S&P 500"; }
                { symbol = "BTC-USD"; name = "Bitcoin"; }
                { symbol = "NVDA"; name = "NVIDIA"; }
                { symbol = "AAPL"; name = "Apple"; }
                { symbol = "MSFT"; name = "Microsoft"; }
              ];
            }
            {
              type = "releases";
              cache = "1d";
              # token = "..."; # Uncomment and set if needed
              repositories = [
                "glanceapp/glance"
                "go-gitea/gitea"
                "immich-app/immich"
                "syncthing/syncthing"
              ];
            }
          ];
        }
      ];
    }
    {
      name = "Infrastructure";
      columns = [
        {
          size = "small";
          widgets = [
            {
              type = "server-stats";
              servers = [
                {
                  type = "local";
                  name = "Router";
                  mountpoints."/nix/store".hide = true;
                }
              ];
            }
          ];
        }
        {
          size = "full";
          widgets = [
            {
              type = "iframe";
              title = "Grafana";
              title-url = "/grafana/";
              source = "/grafana/d-solo/rYdddlPWk/node-exporter-full?orgId=1&from=1747211119196&to=1747297519196&timezone=browser&var-datasource=PBFA97CFB590B2093&var-job=node&var-node=localhost:9100&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B%7Cmmcblk%5B0-9%5D%2B&refresh=1m&panelId=74&__feature.dashboardSceneSolo";
              height = 400;
            }
          ];
        }
        {
          size = "small";
          widgets = [
            {
              type = "dns-stats";
              service = "adguard";
              url = "http://localhost:${toString config.services.adguardhome.port}";
              username = "";
              password = "";
            }
          ];
        }
      ];
    }
  ];
}
