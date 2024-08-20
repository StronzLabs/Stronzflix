async function fetchLatestReleaseAttachments() {
    try {
        const response = await fetch(`https://api.github.com/repos/Bonfra04/Stronzflix/releases/latest`);
        const release = await response.json();

        if (response.ok) {
            const attachments = release.assets.map(asset => ({
                name: asset.name,
                downloadUrl: asset.browser_download_url
            }));
            
            return attachments;
        } else {
            throw new Error(`Failed to fetch latest release: ${response.statusText}`);
        }
    } catch (error) {
        console.error('Error fetching latest release:', error);
        return null;
    }
}

async function downloadFor(platform) {
    const attachments = await fetchLatestReleaseAttachments();
    const attachment = attachments.find(attachment => attachment.name.includes(platform));

    window.location = attachment.downloadUrl;
}

async function populateChangelog() {
    const changelog = document.getElementById('changelog');
    
    const response = await fetch(`https://api.github.com/repos/Bonfra04/Stronzflix/releases`);
    if (!response.ok)
        return;
    const releases = await response.json();

    for (const release of releases) {
        const releaseSection = document.createElement('section');
        releaseSection.classList.add('release');
        releaseSection.innerHTML = `
            <a href=${release.html_url}><h2>${release.name}</h2></a>
            <p>${release.body.replaceAll("\n", "<br>")}</p>
        `;
        changelog.appendChild(releaseSection);
    }
}

function closeCollapsible(collapsible) {
    const div = document.getElementById(collapsible);
    const element = div.querySelector('.collapsible-content');
    const button = div.querySelector('.collapsible-button');

    element.style.maxHeight = null;
    button.classList.remove('active');
}

function openCollapsible(collapsible) {
    const div = document.getElementById(collapsible);
    const element = div.querySelector('.collapsible-content');
    const button = div.querySelector('.collapsible-button');

    element.style.maxHeight = `${element.scrollHeight}px`;
    button.classList.add('active');
    window.location = `${window.location.href.split('#')[0]}#${collapsible}`;
}

function toggleCollapsible(collapsible) {
    const div = document.getElementById(collapsible);
    const element = div.querySelector('.collapsible-content');
    const button = div.querySelector('.collapsible-button');

    if (element.style.maxHeight)
        closeCollapsible(collapsible);
    else
        openCollapsible(collapsible);
}

function closeAllCollapsibles() {
    const collapsibles = document.querySelectorAll('.collapsible');
    collapsibles.forEach(collapsible => closeCollapsible(collapsible.id));
}

function focusCollapsible(collapsible) {
    closeAllCollapsibles();
    openCollapsible(collapsible);
}

populateChangelog();

if (window.location.hash) {
    const collapsible = document.getElementById(window.location.hash.slice(1));
    if (collapsible)
        focusCollapsible(collapsible.id);
}