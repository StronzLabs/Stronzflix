const backend = "http://127.0.0.1:8989";
const searchField = document.getElementById("search-field");

const urlParams = new URLSearchParams(window.location.search);
const query = urlParams.get("search");
if(query)
{
    searchField.value = query;
    search();
}

function performSearch()
{
    if(event.key === 'Enter')
        window.location.href = `/search.html?search=${searchField.value}`;
}

async function search()
{
    const json = await fetch(backend + `/api/search?site=StreamingCommunity&query=${searchField.value}`)
   .then(r => r.json());
    const results = json.results;

    const resultBox = document.getElementById("result-box");
    resultBox.innerHTML = "";
    for (let i = 0; i < results.length; i++)
    {
        const result = results[i];
        const card = document.createElement("a");
        card.className = "card";
        card.href = `/title.html?site=${encodeURIComponent(result.site.name)}&url=${encodeURIComponent(result.url)}`;
        card.innerHTML = `<h5 class="card-title">${result.title}</h5>`;
        resultBox.appendChild(card);
    }
}
