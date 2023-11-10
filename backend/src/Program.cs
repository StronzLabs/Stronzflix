using System.Net;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Stronzflix.Media;
using Stronzflix.Sites;

namespace Stronzflix
{

    public sealed class Application
    {
        public static void Main(string[] args)
        {
            SiteRegistry.Instance.Register(
                new StreamingCommunity("https://streamingcommunity.at"), "StreamingCommunity"
            );

            // Site s = new StreamingCommunity("https://streamingcommunity.at");

            // Result[] results = s.Search("Arrow");
            // Series title = (Series)s.GetTitle(results[0]);

            // Episode e = title.Seasons[7][0];
            
            // string source = s.GetSource(e);
            // Console.WriteLine(source);
            CreateWebHostBuilder(args).Build().Run();
        }

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
        WebHost.CreateDefaultBuilder(args)
            .UseKestrel(options =>
            {
                options.Listen(IPAddress.Any, 8989);
            })
            .UseStartup<Application>();

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddMvc(options => options.EnableEndpointRouting = false);
        }

        public void Configure(IApplicationBuilder app)
        {
            app.UseMvc();
        }
    }
}
