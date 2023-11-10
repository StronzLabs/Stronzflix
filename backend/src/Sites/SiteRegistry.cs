using Stronzflix.Utils;

namespace Stronzflix.Sites
{
    public sealed class SiteRegistry : Registry<Site>
    {
        private static SiteRegistry instance = null;
        public static SiteRegistry Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = new SiteRegistry();
                }
                return instance;
            }
        }
    }
}
