using Microsoft.AspNetCore.Mvc;
using Stronzflix.Media;
using Stronzflix.Sites;

namespace Stronzflix.Apis
{
    [Route("api/search")]
    [ApiController]
    public sealed class Search : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            string query = this.Request.Query["query"];
            string site = this.Request.Query["site"];

            Result[] results = SiteRegistry.Instance.Get(site).Search(query);

            Dictionary<string, Result[]> json = new Dictionary<string, Result[]>
            {
                { "results", results }
            };

            return new JsonResult(json);
        }
    }

    [Route("api/get_title")]
    [ApiController]
    public sealed class GetTitle : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            string site = this.Request.Query["site"];
            string url = this.Request.Query["url"];

            Title result = SiteRegistry.Instance.Get(site).GetTitle(url);

            if (result is Series series)
            {
                Dictionary<string, Series> json = new Dictionary<string, Series>
                {
                    { "title", series }
                };

                return new JsonResult(json);
            }
            else
                throw new NotImplementedException();
        }
    }

    [Route("api/get_source")]
    [ApiController]
    public sealed class GetSource : ControllerBase
    {
        [HttpGet]
        public ActionResult<string> Get()
        {
            string site = this.Request.Query["site"];
            string url = this.Request.Query["url"];

            string result = SiteRegistry.Instance.Get(site).GetSource(url);
            return result;
        }
    }
}
