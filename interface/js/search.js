const searchField = document.getElementById("search-field");
const resultBox = document.getElementById("result-box");

async function search()
{
    if(event.key && event.key !== 'Enter')
        return;

    const json = await fetch(`/api/search?site=StreamingCommunity&query=${searchField.value}`)
   .then(r => r.json());
    const results = json.results;

    resultBox.innerHTML = "";
    for (let i = 0; i < results.length; i++)
    {
        const result = results[i];
        const card = document.createElement("div");
        card.className = "card";
        card.onclick = () => {
            site = result.site;
            url = result.url;
            setController('title');
        };
        card.innerHTML = `
            <div class="card-content">
                <img src="${result.poster}"></img>
                <h5 class="card-title">${result.title}</h5>
            </div>
        `;
        resultBox.appendChild(card);
    }
}
