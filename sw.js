const CACHE = 'nexcipher-v2';
const ASSETS = ['/', '/index.html', '/manifest.json'];
self.addEventListener('install', e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS))); self.skipWaiting(); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(k => Promise.all(k.filter(n=>n!==CACHE).map(n=>caches.delete(n))))); self.clients.claim(); });
self.addEventListener('fetch', e => { if(e.request.method!=='GET')return; e.respondWith(caches.match(e.request).then(cached=>{ const fresh=fetch(e.request).then(res=>{ if(res&&res.status===200){const cl=res.clone();caches.open(CACHE).then(c=>c.put(e.request,cl));} return res; }).catch(()=>cached); return cached||fresh; })); });
