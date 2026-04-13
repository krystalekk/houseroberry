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
const statusPill = document.getElementById('status-pill');

function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

function getTierLabel(value) {
    if (!value) return 'STANDARD';
    if (value.toLowerCase() === 'premium') return 'PREMIUM';
    return 'STANDARD';
}

function updateHud(data) {
    label.textContent = data.label || 'Nieznana posesja';
    owner.textContent = data.owner || 'Nieznany wlasciciel';
    street.textContent = data.street || 'Nieznana ulica';
    tier.textContent = getTierLabel(data.tier);
    alarm.textContent = data.alarm ? 'Aktywny' : 'Nieaktywny';
    searched.textContent = `${data.searched || 0} / ${data.total || 0}`;
    loot.textContent = String(data.loot || 0);
    timer.textContent = formatTime(Math.max(0, data.timer || 0));

    const progress = data.total > 0 ? Math.min(100, ((data.searched || 0) / data.total) * 100) : 0;
    progressBar.style.width = `${progress}%`;
    progressBar.classList.toggle('alarm', Boolean(data.alarm));

    statusPill.classList.remove('alarm', 'hurry');

    if (data.alarm) {
        statusPill.textContent = 'Alarm aktywny';
        statusPill.classList.add('alarm');
        statusText.textContent = 'System ochrony juz dziala. Koncz szybko i znikaj.';
    } else if ((data.timer || 0) <= 60) {
        statusPill.textContent = 'Ostatnia minuta';
        statusPill.classList.add('hurry');
        statusText.textContent = 'Masz malo czasu. Bierz najlepszy loot i uciekaj.';
    } else {
        statusPill.textContent = 'Cicho i szybko';
        statusText.textContent = 'Zachowaj spokoj, bierz najlepszy loot i pilnuj czasu.';
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
