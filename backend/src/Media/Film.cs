namespace Stronzflix.Media
{
    public class Film : Title, IPlayable
    {
        public string Url { get; private set; }
        public string Cover { get; private set; }   
        
        public Film(string name, string url, string cover)
            : base(name, Kind.Movie)
        {
            this.Url = url;
            this.Cover = cover;
        }
    }
}
