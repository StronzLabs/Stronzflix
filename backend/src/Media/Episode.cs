namespace Stronzflix.Media
{
    public class Episode : IPlayable
    {
        public string Url { get; private set; }
        public string Name { get; private set; }
        public string Cover { get; private set; }

        public Episode(string name, string url, string cover)
        {
            this.Url = url;
            this.Name = name;
            this.Cover = cover;
        }
    }
}
