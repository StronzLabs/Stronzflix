export class Site
{
    constructor(name, url)
    {
        this.name = name;
        this.url = url;
    }

    search(query) { throw new Error("Not implemented"); }
    getTitle(url) { throw new Error("Not implemented"); }
    getSource(url) { throw new Error("Not implemented"); }
}
