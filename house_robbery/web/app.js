const app = document.getElementById('app');
const label = document.getElementById('label');
const owner = document.getElementById('owner');
const street = document.getElementById('street');
const tier = document.getElementById('tier');
const alarm = document.getElementById('alarm');
const searched = document.getElementById('searched');
const loot = document.getElementById('loot');
const timer = document.getElementById('timer');
const statusText = document.getElementById('status-text');
const progressBar = document.getElementById('progress-bar');

function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function updateHud(data) {
    label.textContent = data.label || 'Unknown Property';
    owner.textContent = data.owner || 'Unknown Owner';
    street.textContent = data.street || 'Unknown';
    tier.textContent = (data.tier || 'standard').toUpperCase();
    alarm.textContent = data.alarm ? 'ACTIVE' : 'OFFLINE';
    searched.textContent = `${data.searched || 0} / ${data.total || 0}`;
    loot.textContent = String(data.loot || 0);
    timer.textContent = formatTime(Math.max(0, data.timer || 0));

    const progress = data.total > 0 ? Math.min(100, ((data.searched || 0) / data.total) * 100) : 0;
    progressBar.style.width = `${progress}%`;
    progressBar.classList.toggle('alarm', Boolean(data.alarm));

    if (data.alarm) {
        statusText.textContent = 'Alarm active. Police response likely.';
    } else if ((data.timer || 0) <= 60) {
        statusText.textContent = 'Last minute. Grab the best loot and go.';
    } else {
        statusText.textContent = 'Stay quiet. Work fast.';
    }
}

window.addEventListener('message', (event) => {
    const { action, data } = event.data || {};

    if (action === 'show') {
        app.classList.remove('hidden');
        updateHud(data || {});
        return;
    }

    if (action === 'hide') {
        app.classList.add('hidden');
    }
});
