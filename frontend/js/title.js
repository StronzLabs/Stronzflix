const backend = "http://127.0.0.1:8989";

const urlParams = new URLSearchParams(window.location.search);
const site = urlParams.get("site");
const url = urlParams.get("url");

const seasonSelect = document.getElementById("season-select");
const seasonBox = document.getElementById("season-box");

var title = undefined;

async function loadTitle()
{
    const json = await fetch(backend + `/api/get_title?site=${site}&url=${url}`)
    .then(r => r.json());
    title = json.title;

    for(let i = 0; i < title.seasons.length; i++)
    {
        const season = title.seasons[i];
        
        const option = document.createElement("option");
        option.value = `Stagione ${i + 1}`;
        option.innerText = `Stagione ${i + 1}`;
        seasonSelect.appendChild(option);
    }

    populateSeason();
}

function populateSeason()
{
    seasonBox.innerHTML = "";
    const seasonIndex = seasonSelect.selectedIndex;
    const season = title.seasons[seasonIndex];
    for(let i = 0; i < season.length; i++)
    {
        const episode = season[i];
        const card = document.createElement("a");
        card.className = "card";
        card.href = `/media.html?site=${encodeURIComponent(site)}&url=${encodeURIComponent(episode.url)}`;
        card.innerHTML = `<h5 class="card-title">${episode.name}</h5>`;
        seasonBox.appendChild(card);
    }
}

loadTitle();