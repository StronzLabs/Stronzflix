import { Site } from './site.js';
import { default as request } from 'sync-request';
import { decode } from 'html-entities';

export class StreamingCommunity extends Site
{
    constructor(url)
    {
        super("StreamingCommunity", url);

        this.search_url = this.url + "/search?q=";
        this.cdn = url.split("//").join("//cdn.");

        const inhertia_version = this.getInertia();
        this.inhertia =  {
            "X-Inertia": true,
            "X-Inertia-Version": inhertia_version,
        };
    }

    getInertia()
    {
        const response = request('GET', this.url, {
            headers: this.inhertia,
        });

        const version = response.getBody().toString().match(/version&quot;:&quot;(?<inertia>[a-z0-9]+)&quot;/)[1];
        return version;
    }

    search(query)
    {
        const json = JSON.parse(request('GET', this.search_url + query, {
            headers: this.inhertia,
        }).getBody('utf8'));

        const titles = json.props.titles;

        let results = []
        for (const title of titles)
        {
            const poster = title.images.find(image => image.type == "poster").filename;

            results.push({
                "site": this.name,
                "title": title.name,
                "url": "/titles/" + title.id + "-" + title.slug,
                "poster": this.cdn + "/images/" + poster
            });
        }

        return { "results": results };
    }

    getEpisodes(seasonUrl)
    {
        const json = JSON.parse(request('GET', this.url + seasonUrl, {
            headers: this.inhertia,
        }).getBody('utf8'));

        const season = json.props.loadedSeason;
        const titleId = json.props.title.id;
        
        let episodes = [];
        for(const episode of season.episodes)
        {
            const cover = episode.images.find(image => image.type == "cover").filename;
            episodes.push({
                "url": "/watch/" + titleId + "?e=" + episode.id,
                "name": episode.name,
                "cover": this.cdn + "/images/" + cover
            });
        }

        return episodes;
    }

    getSeries(url, title)
    {
        let episodes = [];
        for (const season of title.seasons)
        {
            const seasonUrl = url + "/stagione-" + season.number;
            episodes.push(this.getEpisodes(seasonUrl));
        }

        return { "seasons": episodes };
    }

    getFilm(title)
    {
        return { "url": "/watch/" + title.id, "name": title.name };
    }

    getTitle(url)
    {
        const json = JSON.parse(request('GET', this.url + url, {
            headers: this.inhertia,
        }).getBody('utf8'));

        const title = json.props.title;

        const result = title.type == "tv" ? this.getSeries(url, title) : this.getFilm(title);
   
        return { "title": result, "site": this.name, };
    }

    parseVixCloud(url)
    {
        const data = request('GET', url).getBody('utf8');

        const playlistUrl = data.match(/url: '(.+?)'/)[1];    
        
        const jsonString = data.match(/params: ({(.|\n)+?}),/)[1].replace(/\'/g, '"').replace(/ /g, "").replace(/\n/g, "").replace(/\",}/g, "\"}");
        const json = JSON.parse(jsonString);
        
        let param = "";
        for(const key in json)
            param += key + "=" + json[key] + "&";
        param = param.substring(0, param.length - 1);

        const playlist = playlistUrl + "?" + param;
        const source = request('GET', playlist).getBody('utf8');
        return source;
    }

    getSource(url)
    {
        const titleId = url.match(/watch\/(\d+)/)[1];
        const episodeId = url.match(/\?e=(\d+)/)[1];
        const iframeSrc = "/iframe/" + titleId + "?episode_id=" + episodeId;

        const iframe = request('GET', this.url + iframeSrc, {
            headers: { "User-Agent": "Stronzflix" }
        }).getBody('utf8');
        const src = decode(iframe.match(/src="(.+?)"/)[1]);

        return this.parseVixCloud(src);
    }
}
