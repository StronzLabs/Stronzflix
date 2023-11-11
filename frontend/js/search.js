const searchField = document.getElementById("search-field");
const resultBox = document.getElementById("result-box");

async function search()
{
    if(event.key && event.key !== 'Enter')
        return;

    const json = await fetch(`${backend}/api/search?site=StreamingCommunity&query=${searchField.value}`)
   .then(r => r.json());
    const results = json.results;

    resultBox.innerHTML = "";
    for (let i = 0; i < results.length; i++)
    {
        const result = results[i];
        const card = document.createElement("div");
        card.className = "card";
        card.onclick = () => {javascript:
            site = result.site.name;
            url = result.url;
            setController('title');
        };
        card.innerHTML = `<img src="${result.poster}"></img><h5 class="card-title">${result.title}</h5>`;
        resultBox.appendChild(card);
    }
}
