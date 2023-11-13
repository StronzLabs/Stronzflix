const video = document.getElementById('video');

function loadMedia()
{
    const source = `/api/get_source?site=${site}&url=${url}`;
    
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
}
