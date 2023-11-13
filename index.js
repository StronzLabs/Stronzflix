import express from 'express';

import { Registry } from './utils/registry.js';
import { StreamingCommunity} from './sites/streamingcommunity.js';

const siteRegistry = new Registry();
siteRegistry.register(new StreamingCommunity("https://streamingcommunity.at"), "StreamingCommunity");


const app = express();

app.disable("x-powered-by");
app.disable("etag");
app.use((_, response, next) => {
    response.removeHeader("Date");
    next();
});

app.listen(3000, () => {
    console.log("Server Listening on PORT:", 3000);
});

app.get("/api/search", (request, response) => {
    const site = request.query.site;
    const query = request.query.query;

    const siteInstance = siteRegistry.get(site);

    response.send(siteInstance.search(query));
});

app.get("/api/get_title", (request, response) => {
    const site = request.query.site;
    const url = request.query.url;

    const siteInstance = siteRegistry.get(site);

    response.send(siteInstance.getTitle(url));
});

app.get("/api/get_source", (request, response) => {
    const site = request.query.site;
    const url = request.query.url;

    const siteInstance = siteRegistry.get(site);

    response.send(siteInstance.getSource(url));
});

app.use("/", express.static("interface"));
