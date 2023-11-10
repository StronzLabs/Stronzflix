namespace Stronzflix.Media
{
    public class Episode : IPlayable
    {
        public string Url { get; private set; }
        public string Name { get; private set; }

        public Episode(string name, string url)
        {
            this.Url = url;
            this.Name = name;
        }
    }
}
