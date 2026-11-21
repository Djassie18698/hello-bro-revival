// Ninja Online as an installable app. A browser only offers "Install" (Chrome, Edge) for a page with a service worker, so this
// one exists, and it does nothing else on purpose: it keeps NO copies of game files. Every request goes to the network exactly
// as without it, so a player can never be left with old code after an update (the server's ETag / no-cache rules stay in charge).
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil((async () => { for (const k of await caches.keys()) await caches.delete(k); await self.clients.claim(); })()));
self.addEventListener('fetch', () => {}); // no respondWith: the browser fetches as usual
