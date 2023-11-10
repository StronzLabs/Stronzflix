namespace Stronzflix.Sites
{
    public struct Result
    {
        public Site Site { get; private set; }
        public string Title { get; private set; }
        public string Url { get; private set; }

        public Result(Site site, string title, string url)
        {
            this.Site = site;
            this.Title = title;
            this.Url = url;
        }
    }
}
