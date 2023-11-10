using System.Net;

namespace Stronzflix.Utils
{
    public static class SimpleHTTP
    {
        public static string Get(string url, Dictionary<string, string> headers = null)
        {
            using HttpClient client = new HttpClient();

            if (headers == null)
                headers = new Dictionary<string, string>();

            if (!headers.ContainsKey("User-Agent"))
                headers.Add("User-Agent", "Stronzflix");

            foreach (KeyValuePair<string, string> header in headers)
                client.DefaultRequestHeaders.Add(header.Key, header.Value);
            HttpResponseMessage response = client.GetAsync(url).Result;

            if (response.IsSuccessStatusCode)
                return response.Content.ReadAsStringAsync().Result;
                
            Console.WriteLine($"Error: {response.StatusCode} - {response.ReasonPhrase}");
            return null;
        }
    }
}
