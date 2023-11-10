const backend = "http://127.0.0.1:8989";

const urlParams = new URLSearchParams(window.location.search);
const site = urlParams.get("site");
const url = urlParams.get("url");

const source = `${backend}/api/get_source?site=${site}&url=${url}`;

const video = document.getElementById('video');

if (Hls.isSupported())
{
    const hls = new Hls();
    hls.loadSource(source);
    hls.attachMedia(video);
    video.play();
}
else if (video.canPlayType('application/vnd.apple.mpegurl'))
{
    video.src = source;
    video.addEventListener('loadedmetadata', () => video.play());
}
