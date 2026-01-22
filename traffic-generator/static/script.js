// UI Elements
const startBtn = document.getElementById('start-btn');
const stopBtn = document.getElementById('stop-btn');
const statusDot = document.getElementById('status-dot');
const statusText = document.getElementById('status-text');
const runtimeEl = document.getElementById('runtime');

// Sliders
const concurrentUsersSlider = document.getElementById('concurrent-users');
const usersValue = document.getElementById('users-value');
const durationSlider = document.getElementById('duration');
const durationValue = document.getElementById('duration-value');

// Journey mix sliders
const browseSlider = document.getElementById('browse-weight');
const browseValue = document.getElementById('browse-value');
const shoppingSlider = document.getElementById('shopping-weight');
const shoppingValue = document.getElementById('shopping-value');
const orderSlider = document.getElementById('order-weight');
const orderValue = document.getElementById('order-value');
const adminSlider = document.getElementById('admin-weight');
const adminValue = document.getElementById('admin-value');

// Stats polling
let statsInterval = null;

// Update slider values
concurrentUsersSlider.addEventListener('input', (e) => {
    usersValue.textContent = e.target.value;
});

durationSlider.addEventListener('input', (e) => {
    durationValue.textContent = e.target.value;
});

browseSlider.addEventListener('input', (e) => {
    browseValue.textContent = e.target.value;
});

shoppingSlider.addEventListener('input', (e) => {
    shoppingValue.textContent = e.target.value;
});

orderSlider.addEventListener('input', (e) => {
    orderValue.textContent = e.target.value;
});

adminSlider.addEventListener('input', (e) => {
    adminValue.textContent = e.target.value;
});

// Start traffic
startBtn.addEventListener('click', async () => {
    const config = {
        concurrent_users: parseInt(concurrentUsersSlider.value),
        intensity: document.getElementById('intensity').value,
        duration: parseInt(durationSlider.value),
        headless: document.getElementById('headless').checked,
        journey_mix: {
            browse: parseInt(browseSlider.value),
            shopping: parseInt(shoppingSlider.value),
            order: parseInt(orderSlider.value),
            admin: parseInt(adminSlider.value)
        }
    };

    try {
        const response = await fetch('/api/start', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(config)
        });

        if (response.ok) {
            startBtn.disabled = true;
            stopBtn.disabled = false;
            statusDot.classList.remove('idle');
            statusDot.classList.add('running');
            statusText.textContent = 'Running';

            // Start polling for stats
            if (statsInterval) clearInterval(statsInterval);
            statsInterval = setInterval(updateStats, 1000);
        } else {
            const error = await response.json();
            alert('Error: ' + error.error);
        }
    } catch (err) {
        alert('Failed to start traffic: ' + err.message);
    }
});

// Stop traffic
stopBtn.addEventListener('click', async () => {
    try {
        const response = await fetch('/api/stop', {
            method: 'POST'
        });

        if (response.ok) {
            startBtn.disabled = false;
            stopBtn.disabled = true;
            statusDot.classList.remove('running');
            statusDot.classList.add('idle');
            statusText.textContent = 'Stopped';

            // Stop polling
            if (statsInterval) {
                clearInterval(statsInterval);
                statsInterval = null;
            }
        }
    } catch (err) {
        alert('Failed to stop traffic: ' + err.message);
    }
});

// Update statistics
async function updateStats() {
    try {
        const response = await fetch('/api/stats');
        const stats = await response.json();

        // Update status
        if (!stats.running && statsInterval) {
            clearInterval(statsInterval);
            statsInterval = null;
            startBtn.disabled = false;
            stopBtn.disabled = true;
            statusDot.classList.remove('running');
            statusDot.classList.add('idle');
            statusText.textContent = 'Completed';
        }

        // Update runtime
        const minutes = Math.floor(stats.runtime / 60);
        const seconds = stats.runtime % 60;
        runtimeEl.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;

        // Update main stats
        document.getElementById('active-sessions').textContent = stats.active_sessions;
        document.getElementById('total-journeys').textContent = stats.total_journeys;
        document.getElementById('page-loads').textContent = stats.total_page_loads;

        // Calculate success rate
        const total = stats.success_count + stats.failure_count;
        const successRate = total > 0 ? Math.round((stats.success_count / total) * 100) : 0;
        document.getElementById('success-rate').textContent = successRate + '%';

        // Update service stats
        document.getElementById('store-calls').textContent = stats.service_stats.store.calls + ' calls';
        document.getElementById('store-errors').textContent = stats.service_stats.store.errors + ' errors';

        document.getElementById('cart-calls').textContent = stats.service_stats.cart.calls + ' calls';
        document.getElementById('cart-errors').textContent = stats.service_stats.cart.errors + ' errors';

        document.getElementById('order-calls').textContent = stats.service_stats.order.calls + ' calls';
        document.getElementById('order-errors').textContent = stats.service_stats.order.errors + ' errors';

        document.getElementById('users-calls').textContent = stats.service_stats.users.calls + ' calls';
        document.getElementById('users-errors').textContent = stats.service_stats.users.errors + ' errors';

        // Update activity feed
        const activityFeed = document.getElementById('activity-feed');
        if (stats.recent_actions && stats.recent_actions.length > 0) {
            activityFeed.innerHTML = stats.recent_actions.map(action => `
                <div class="activity-item ${action.status}">
                    <span class="activity-time">${action.timestamp}</span>
                    <span class="activity-text">${action.action}</span>
                </div>
            `).join('');
        }

    } catch (err) {
        console.error('Failed to fetch stats:', err);
    }
}

// Initial stats load
updateStats();
