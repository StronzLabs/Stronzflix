using System.Linq;
using System.Net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Stronzflix.Media;
using Stronzflix.MediaPlayers;
using Stronzflix.Utils;

namespace Stronzflix.Sites
{
    public class StreamingCommunity : Site
    {
        private readonly string search_url;
        private readonly Dictionary<string, string> inhertia;

        private readonly string cdn;

        public StreamingCommunity(string url)
            : base("StreamingCommunity", url)
        {
            this.search_url = base.Url + "/search?q=";
            this.cdn = string.Join("//cdn.", url.Split("//"));
            string inhertia_version = this.GetInertia();
            this.inhertia = new Dictionary<string, string>()
            {
                { "X-Inertia", "true" },
                { "X-Inertia-Version", inhertia_version },
            };
        }

        private string GetInertia()
        {
            string html = SimpleHTTP.Get(base.Url);
            string match = SimpleRegex.Search(@"version&quot;:&quot;(?<inertia>[a-z0-9]+)&quot;", html);
            return match;
        }

        public override Result[] Search(string query)
        {
            string json = SimpleHTTP.Get(this.search_url + query, this.inhertia);
            Dictionary<string, object> data = JsonConvert.DeserializeObject<Dictionary<string, object>>(json);
            JArray titles = (JArray)((JObject)data["props"])["titles"];

            List<Result> results = new List<Result>();
            foreach (JObject title in titles.Cast<JObject>())
            {
                string title_id = (string)title["id"];
                string title_slug = (string)title["slug"];
                JArray images = (JArray)title["images"];
                string poster = "";
                foreach(JObject image in images.Cast<JObject>())
                    if((string)image["type"] == "poster")
                    {
                        poster = (string)image["filename"];
                        break;
                    }

                string title_url = "/titles/" + title_id + "-" + title_slug;
                string title_name = (string)title["name"];
                string poster_url = this.cdn + "/images/" + poster;

                results.Add(new Result(this, title_name, title_url, poster_url));
            }

            return results.ToArray();
        }

        private Episode[] GetEpisodes(string season_url)
        {
            string json = SimpleHTTP.Get(base.Url + season_url, this.inhertia);
            Dictionary<string, object> data = JsonConvert.DeserializeObject<Dictionary<string, object>>(json);
            
            JObject loaded_season = (JObject)((JObject)data["props"])["loadedSeason"];
            string title_id = (string)((JObject)((JObject)data["props"])["title"])["id"];
            
            JArray episodes = (JArray)loaded_season["episodes"];
            
            List<Episode> episodes_list = new List<Episode>();

            foreach(JObject episode in episodes.Cast<JObject>())
            {
                string episode_id = (string)episode["id"];

                string episode_url = "/watch/" + title_id + "?e=" + episode_id;
                string episode_name = (string)episode["name"];

                episodes_list.Add(new Episode(episode_name, episode_url));
            }

            return episodes_list.ToArray();
        }

        public override Title GetTitle(string url)
        {
            string json = SimpleHTTP.Get(base.Url + url, this.inhertia);
            Dictionary<string, object> data = JsonConvert.DeserializeObject<Dictionary<string, object>>(json);
            JArray seasons = (JArray)((JObject)((JObject)data["props"])["title"])["seasons"];
            string name = (string)((JObject)((JObject)data["props"])["title"])["name"];
            
            List<Episode[]> episodes = new List<Episode[]>();

            foreach(JObject season in seasons.Cast<JObject>())
            {
                string season_number = (string)season["number"];
                string season_url = url + "/stagione-" + season_number;

                episodes.Add(this.GetEpisodes(season_url));
            }

            return new Series(name, episodes.ToArray());
        }

        public override string GetSource(string url)
        {
            string title_id = SimpleRegex.Search(@"watch/(\d+)", url);
            string episode_id = SimpleRegex.Search(@"\?e=(\d+)", url);
            string iframeSrc = "/iframe/" + title_id + "?episode_id=" + episode_id;

            string iframe = SimpleHTTP.Get(base.Url + iframeSrc);
            string src = WebUtility.HtmlDecode(SimpleRegex.Search("src=\"(.+?)\"", iframe));

            return new VixCloud().GetSource(src);
        }
    }
}
