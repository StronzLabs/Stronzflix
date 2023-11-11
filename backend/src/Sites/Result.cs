namespace Stronzflix.Sites
{
    public struct Result
    {
        public Site Site { get; private set; }
        public string Title { get; private set; }
        public string Url { get; private set; }
        public string Poster { get; private set; }

        public Result(Site site, string title, string url, string poster)
        {
            this.Site = site;
            this.Title = title;
            this.Url = url;
            this.Poster = poster;
        }
    }
}
