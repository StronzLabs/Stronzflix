namespace Stronzflix.Media
{
    public class Film : Title, IPlayable
    {
        public string Url { get; private set; }
        
        public Film(string name, string url)
            : base(name, Kind.Movie)
        {
            this.Url = url;
        }
    }
}
