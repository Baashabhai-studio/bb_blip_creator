/* ──────────────────────────────────────────────────────────────────
   BLIP CREATOR - NUI controller
   ────────────────────────────────────────────────────────────────── */

const RES = (typeof GetParentResourceName !== 'undefined') ? GetParentResourceName() : 'blip_creator';
const DEV = (typeof GetParentResourceName === 'undefined'); // true when opened directly in a browser

// ── State ───────────────────────────────────────────────────────────
let state = {
    isAdmin: false,
    blips: {},                       // id -> data
    editingId: null,
    form: { label: '', sprite: 1, color: 0, scale: 0.8, shortRange: false, x: 0, y: 0, z: 0 },
    catFilter: 'All',
};

// ── DOM ─────────────────────────────────────────────────────────────
const $ = (s) => document.querySelector(s);
const app = $('#app');
const els = {
    title: $('#title'), subtitle: $('#subtitle'), adminBadge: $('#adminBadge'),
    label: $('#f-label'), x: $('#f-x'), y: $('#f-y'), z: $('#f-z'),
    scale: $('#f-scale'), scaleVal: $('#scaleVal'), short: $('#f-short'),
    color: $('#f-color'), colorVal: $('#colorVal'), palette: $('#colorPalette'),
    spriteSearch: $('#spriteSearch'), spriteGrid: $('#spriteGrid'), catChips: $('#catChips'),
    selSpriteId: $('#selSpriteId'), selSpriteThumb: $('#selectedSpriteBox .sprite-thumb'),
    saveBtn: $('#saveBtn'), cancelEdit: $('#cancelEdit'),
    blipList: $('#blipList'), emptyState: $('#emptyState'),
    manageCount: $('#manageCount'), manageSearch: $('#manageSearch'),
};

// Toast element
const toast = document.createElement('div');
toast.id = 'toast';
document.body.appendChild(toast);
let toastTimer;
function showToast(msg, kind) {
    toast.textContent = msg;
    toast.className = 'show ' + (kind || '');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { toast.className = ''; }, 3200);
}

// ── NUI fetch helper ────────────────────────────────────────────────
async function post(name, data) {
    if (DEV) return mockPost(name, data);
    try {
        const res = await fetch(`https://${RES}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        });
        return await res.json().catch(() => ({}));
    } catch (e) { return {}; }
}

// ── Sprite thumbnail ────────────────────────────────────────────────
// Each blip icon is bundled at html/blips/<id>.png (real GTA icons, offline).
// We load it as an <img>; if a particular id has no image we fall back to the number.
function applyThumb(el) {
    const id = parseInt(el.dataset.id, 10);
    el.innerHTML = '';
    el.classList.remove('has-img');
    if (id > 0) {
        const img = document.createElement('img');
        img.className = 'thumb-img';
        img.loading = 'lazy';
        img.alt = '#' + id;
        img.onload = () => el.classList.add('has-img');
        img.onerror = () => { img.remove(); el.textContent = id; };
        img.src = 'blips/' + id + '.png';
        el.appendChild(img);
    } else {
        el.textContent = id;
    }
}

// ── Build palette ───────────────────────────────────────────────────
function buildPalette() {
    els.palette.innerHTML = '';
    BLIP_COLORS.forEach(c => {
        const sw = document.createElement('div');
        sw.className = 'swatch';
        sw.style.background = c.hex;
        sw.title = `${c.name} (#${c.id})`;
        sw.dataset.id = c.id;
        sw.onclick = () => setColor(c.id);
        els.palette.appendChild(sw);
    });
    markActiveColor();
}
function markActiveColor() {
    document.querySelectorAll('.swatch').forEach(s =>
        s.classList.toggle('swatch--active', parseInt(s.dataset.id, 10) === state.form.color));
}
function setColor(id) {
    state.form.color = id;
    els.color.value = id;
    els.colorVal.textContent = '#' + id;
    markActiveColor();
    livePreview();
}

// ── Build category chips ────────────────────────────────────────────
function buildCats() {
    const cats = ['All', ...Array.from(new Set(BLIP_DATA.map(b => b.cat)))];
    els.catChips.innerHTML = '';
    cats.forEach(cat => {
        const c = document.createElement('div');
        c.className = 'chip' + (cat === state.catFilter ? ' chip--active' : '');
        c.textContent = cat;
        c.onclick = () => { state.catFilter = cat; buildCats(); renderSprites(); };
        els.catChips.appendChild(c);
    });
}

// ── Render sprite grid ──────────────────────────────────────────────
function renderSprites() {
    const q = els.spriteSearch.value.trim().toLowerCase();
    const frag = document.createDocumentFragment();
    let count = 0;
    for (const b of BLIP_DATA) {
        if (state.catFilter !== 'All' && b.cat !== state.catFilter) continue;
        if (q && !(b.name.toLowerCase().includes(q) || String(b.id) === q)) continue;
        const card = document.createElement('div');
        card.className = 'sprite-card' + (b.id === state.form.sprite ? ' sprite-card--active' : '');
        card.onclick = () => setSprite(b.id);
        const thumb = document.createElement('span');
        thumb.className = 'sprite-thumb'; thumb.dataset.id = b.id;
        applyThumb(thumb);
        const name = document.createElement('span'); name.className = 'name'; name.textContent = b.name;
        const sid = document.createElement('span'); sid.className = 'sid'; sid.textContent = '#' + b.id;
        card.append(thumb, name, sid);
        frag.appendChild(card);
        if (++count > 300) break; // keep DOM light; search narrows it
    }
    els.spriteGrid.innerHTML = '';
    els.spriteGrid.appendChild(frag);
}
function setSprite(id) {
    state.form.sprite = id;
    els.selSpriteId.textContent = id;
    els.selSpriteThumb.dataset.id = id;
    applyThumb(els.selSpriteThumb);
    document.querySelectorAll('.sprite-card').forEach(c => c.classList.remove('sprite-card--active'));
    renderSprites();
    livePreview();
}

// ── Live preview (debounced) ────────────────────────────────────────
let previewTimer;
function livePreview() {
    syncFormFromInputs();
    clearTimeout(previewTimer);
    previewTimer = setTimeout(() => {
        post('preview', formToBlip());
    }, 120);
}
function syncFormFromInputs() {
    state.form.label = els.label.value;
    state.form.scale = parseFloat(els.scale.value);
    state.form.shortRange = els.short.checked;
    state.form.x = parseFloat(els.x.value) || 0;
    state.form.y = parseFloat(els.y.value) || 0;
    state.form.z = parseFloat(els.z.value) || 0;
    const cid = parseInt(els.color.value, 10);
    if (!isNaN(cid)) { state.form.color = Math.max(0, Math.min(85, cid)); els.colorVal.textContent = '#' + state.form.color; markActiveColor(); }
}
function formToBlip() {
    const f = state.form;
    return { label: f.label || 'Blip', sprite: f.sprite, color: f.color, scale: f.scale,
             shortRange: f.shortRange, coords: { x: f.x, y: f.y, z: f.z } };
}

// ── Manage list ─────────────────────────────────────────────────────
function colorHex(id) { const c = BLIP_COLORS.find(c => c.id === id); return c ? c.hex : '#5b8cff'; }
function renderList() {
    const ids = Object.keys(state.blips);
    els.manageCount.textContent = ids.length;
    const q = els.manageSearch.value.trim().toLowerCase();
    els.blipList.innerHTML = '';
    let shown = 0;
    ids.sort((a, b) => Number(a) - Number(b)).forEach(id => {
        const d = state.blips[id];
        if (q && !d.label.toLowerCase().includes(q) && String(d.sprite) !== q) return;
        shown++;
        const row = document.createElement('div'); row.className = 'blip-row';
        row.innerHTML = `
            <span class="dot" style="color:${colorHex(d.color)};background:${colorHex(d.color)}"></span>
            <div class="info">
                <div class="name"></div>
                <div class="meta">Sprite #${d.sprite} · Color #${d.color} · Scale ${(+d.scale).toFixed(2)} · ${d.coords.x.toFixed(1)}, ${d.coords.y.toFixed(1)}</div>
            </div>
            <div class="row-actions">
                <button class="mini-btn" data-act="tp">Teleport</button>
                <button class="mini-btn" data-act="edit">Edit</button>
                <button class="mini-btn mini-btn--danger" data-act="del">Delete</button>
            </div>`;
        row.querySelector('.name').textContent = d.label;
        row.querySelector('[data-act=tp]').onclick = () => post('teleport', { coords: d.coords });
        row.querySelector('[data-act=edit]').onclick = () => startEdit(id);
        row.querySelector('[data-act=del]').onclick = () => { post('delete', { id }); };
        els.blipList.appendChild(row);
    });
    els.emptyState.classList.toggle('show', shown === 0);
}

// ── Edit / Save ─────────────────────────────────────────────────────
function loadIntoForm(d) {
    els.label.value = d.label || '';
    els.x.value = d.coords.x.toFixed(2); els.y.value = d.coords.y.toFixed(2); els.z.value = d.coords.z.toFixed(2);
    els.scale.value = d.scale; els.scaleVal.textContent = (+d.scale).toFixed(2);
    els.short.checked = !!d.shortRange;
    state.form = { label: d.label, sprite: d.sprite, color: d.color, scale: +d.scale,
                   shortRange: !!d.shortRange, x: d.coords.x, y: d.coords.y, z: d.coords.z };
    setColor(d.color); setSprite(d.sprite);
}
function startEdit(id) {
    state.editingId = id;
    loadIntoForm(state.blips[id]);
    els.saveBtn.textContent = 'Save changes';
    els.cancelEdit.classList.remove('hidden');
    switchTab('create');
    livePreview();
}
function cancelEdit() {
    state.editingId = null;
    els.saveBtn.textContent = 'Create blip';
    els.cancelEdit.classList.add('hidden');
    post('clearPreview');
}
function save() {
    syncFormFromInputs();
    const blip = formToBlip();
    if (!blip.label.trim()) return showToast('Please enter a label.', 'error');
    if (!blip.coords.x && !blip.coords.y) return showToast('Set a location first.', 'error');
    if (state.editingId) {
        post('update', { id: state.editingId, blip });
        cancelEdit();
    } else {
        post('create', blip);
    }
}

// ── Tabs ────────────────────────────────────────────────────────────
function switchTab(name) {
    document.querySelectorAll('.tab').forEach(t => t.classList.toggle('tab--active', t.dataset.tab === name));
    document.querySelectorAll('.tabpane').forEach(p => p.classList.toggle('tabpane--active', p.id === 'tab-' + name));
    if (name === 'manage') renderList();
}

// ── Open / Close ────────────────────────────────────────────────────
function openPanel(payload) {
    state.isAdmin = !!payload.isAdmin;
    state.blips = payload.blips || {};
    if (payload.config) {
        els.title.textContent = payload.config.title || 'Blip Creator';
        els.subtitle.textContent = payload.config.subtitle || '';
        state.form.sprite = payload.config.defaultSprite || 1;
        state.form.color = payload.config.defaultColor || 0;
        state.form.scale = payload.config.defaultScale || 0.8;
    }
    if (payload.position) {
        els.x.value = payload.position.x.toFixed(2);
        els.y.value = payload.position.y.toFixed(2);
        els.z.value = payload.position.z.toFixed(2);
    }
    els.adminBadge.classList.toggle('hidden', !state.isAdmin);
    els.scale.value = state.form.scale; els.scaleVal.textContent = (+state.form.scale).toFixed(2);
    setColor(state.form.color); setSprite(state.form.sprite);
    renderList();
    app.classList.remove('hidden');
    els.label.focus();
}
function closePanel() {
    app.classList.add('hidden');
    cancelEdit();
    post('close');
}

// ── Inbound NUI messages ────────────────────────────────────────────
window.addEventListener('message', (e) => {
    const d = e.data || {};
    switch (d.action) {
        case 'open':     openPanel(d); break;
        case 'close':    app.classList.add('hidden'); break;
        case 'setBlips': state.blips = d.blips || {}; renderList(); break;
        case 'setAdmin': state.isAdmin = !!d.isAdmin; els.adminBadge.classList.toggle('hidden', !state.isAdmin); break;
        case 'notify':   showToast(d.message, d.kind); break;
    }
});

// ── Wire events ─────────────────────────────────────────────────────
$('#closeBtn').onclick = closePanel;
els.saveBtn.onclick = save;
els.cancelEdit.onclick = cancelEdit;
document.querySelectorAll('.tab').forEach(t => t.onclick = () => switchTab(t.dataset.tab));
els.spriteSearch.oninput = renderSprites;
els.manageSearch.oninput = renderList;
els.scale.oninput = () => { els.scaleVal.textContent = (+els.scale.value).toFixed(2); livePreview(); };
['input', 'change'].forEach(ev => {
    els.label.addEventListener(ev, livePreview);
    [els.x, els.y, els.z].forEach(i => i.addEventListener(ev, livePreview));
    els.short.addEventListener(ev, livePreview);
    els.color.addEventListener(ev, livePreview);
});
$('#useMe').onclick = async () => {
    const p = await post('getMyPosition');
    if (p) { els.x.value = p.x.toFixed(2); els.y.value = p.y.toFixed(2); els.z.value = p.z.toFixed(2); livePreview(); showToast('Position set.', 'success'); }
};
$('#useWp').onclick = async () => {
    const p = await post('getWaypoint');
    if (p && p.ok) { els.x.value = p.x.toFixed(2); els.y.value = p.y.toFixed(2); els.z.value = p.z.toFixed(2); livePreview(); showToast('Waypoint position set.', 'success'); }
    else showToast('No waypoint set on the map.', 'error');
};
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !app.classList.contains('hidden')) closePanel();
});

// ── Init ────────────────────────────────────────────────────────────
buildPalette();
buildCats();
renderSprites();

// ── DEV mock (browser preview only) ─────────────────────────────────
function mockPost(name, data) {
    if (name === 'getMyPosition') return Promise.resolve({ x: -1037.5, y: -2737.6, z: 20.1 });
    if (name === 'getWaypoint')   return Promise.resolve({ x: 250.3, y: -1370.2, z: 30.0, ok: true });
    if (name === 'create') {
        const id = String(Object.keys(state.blips).length + 1);
        state.blips[id] = data; renderList(); showToast('Blip created (preview).', 'success');
    }
    if (name === 'update') { state.blips[data.id] = data.blip; renderList(); showToast('Updated (preview).', 'success'); }
    if (name === 'delete') { delete state.blips[data.id]; renderList(); showToast('Deleted (preview).', 'success'); }
    return Promise.resolve({});
}
if (DEV) {
    openPanel({
        isAdmin: true,
        position: { x: -1037.50, y: -2737.60, z: 20.10 },
        config: { title: 'BB Blip Creator', subtitle: 'by Baasha Bhai', defaultSprite: 108, defaultColor: 3, defaultScale: 0.8 },
        blips: {
            '1': { label: 'Pacific Bank', sprite: 108, color: 3, scale: 0.9, shortRange: true, coords: { x: 235.0, y: 216.0, z: 106.0 } },
            '2': { label: 'Sandy Hospital', sprite: 61, color: 1, scale: 0.8, shortRange: true, coords: { x: 1839.0, y: 3672.0, z: 34.0 } },
            '3': { label: 'Ammu-Nation', sprite: 110, color: 5, scale: 0.7, shortRange: true, coords: { x: 22.0, y: -1107.0, z: 29.0 } },
        },
    });
}
