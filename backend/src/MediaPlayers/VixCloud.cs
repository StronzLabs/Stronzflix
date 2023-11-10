using Newtonsoft.Json;
using Stronzflix.Utils;

namespace Stronzflix.MediaPlayers
{
    public class VixCloud : MediaPlayer
    {
        public override string GetSource(string url)
        {
            string data = SimpleHTTP.Get(url);

            url = SimpleRegex.Search(@"url: '(.+?)'", data);
            string param;
            param = SimpleRegex.Search(@"params: ({(.|\n)+?}),", data);
            param = param.Replace('\'', '"').Replace(" ", "").Replace("\n", "").Replace("\",}", "\"}");
            
            Dictionary<string, object> json = JsonConvert.DeserializeObject<Dictionary<string, object>>(param);

            param = "";
            foreach(KeyValuePair<string, object> kvp in json)
                param += $"{kvp.Key}={kvp.Value}&";

            string playlist = url + "?" + param;

            string source = SimpleHTTP.Get(playlist);
            return source;
        }
    }
}
