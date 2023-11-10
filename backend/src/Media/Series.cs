namespace Stronzflix.Media
{
    public class Series : Title
    {
        public Episode[][] Seasons { get; }

        public Series(string name, Episode[][] seasons)
            : base(name, Kind.Series)
        {
            this.Seasons = seasons;
        }
    }
}
