using Stronzflix.Media;

namespace Stronzflix.Sites
{
    public abstract class Site
    {
        public string Name { get; private set; }
        public string Url { get; private set; }

        public Site(string name, string url)
        {
            this.Name = name;
            this.Url = url;
        }

        public abstract Result[] Search(string query);

        public abstract Title GetTitle(string url);

        public abstract string GetSource(string url);
    }
}
