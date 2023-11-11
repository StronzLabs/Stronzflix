const seasonSelect = document.getElementById("season-select");
const seasonBox = document.getElementById("season-box");

async function loadTitle()
{
    const json = await fetch(`${backend}/api/get_title?site=${site}&url=${url}`)
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
        const card = document.createElement("div");
        card.className = "card";
        card.onclick = () => {
            url = episode.url;
            setController('media');
        };
        console.log(episode);
        card.innerHTML = `
            <div class="card-content">
                <img src="${episode.cover}"></img>
                <h5 class="card-title">${i + 1} - ${episode.name}</h5>
            </div>
        `;
        seasonBox.appendChild(card);
    }
}
