'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"icons/Icon-maskable-192.png": "5ba39972f9917b5bab0e47c9fe3c893f",
"icons/Icon-maskable-512.png": "40add6bb1d0f005e793ca76bc6cc83f0",
"icons/Icon-192.png": "1249ae2800263f8940075339abf43589",
"icons/Icon-512.png": "6fea2608857dcfdd882c0c8ca15e7117",
"version.json": "b4f07bf391736f7df6125823503cd9ae",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"manifest.json": "2ef18b68a441118a8014495c1e2bf140",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "1fcba7a59e49001aa1b4409a25d425b0",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "5b8d20acec3e57711717f61417c1be44",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "b2703f18eee8303425a5342dba6958db",
"assets/fonts/MaterialIcons-Regular.otf": "4a03b4c5c8292e5074be5f2218417989",
"assets/FontManifest.json": "23cad3e62f2ae7931d72bbef8f4475db",
"assets/assets/Lato-Regular.ttf": "122dd68d69fe9587e062d20d9ff5de2a",
"assets/assets/release.txt": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/Icon-app.ico": "3b55ba9eac59bbe07e351fd6b04f950e",
"assets/assets/images/Icon-app.png": "6fea2608857dcfdd882c0c8ca15e7117",
"assets/assets/images/currency/demon_soul.png": "081c315c975953e00d53837ae45997f2",
"assets/assets/images/currency/ap.png": "e7f9f98efa9106f06d3a2ba70ad64911",
"assets/assets/images/currency/gold_ofuda.png": "5fd0bccecbc45b88e3bd1ea1dee8843e",
"assets/assets/images/currency/skin_token.png": "74711f1f7cd2be8e5f23545f223843e3",
"assets/assets/images/currency/broken_amulet.png": "6a8052e85e4b42d1d67b81549df19374",
"assets/assets/images/currency/scale.png": "6d30e6f937071c021f712ec56f29190e",
"assets/assets/images/currency/contrib.png": "ec853240d42c769b3480dbaf208cd577",
"assets/assets/images/currency/ar_amulet.png": "8f537c8b789046257d004d06f75a3532",
"assets/assets/images/currency/hyakki_ticket.png": "259b0ae0db855d9e0815a10969390241",
"assets/assets/images/currency/honor.png": "9fa4d5bc7f180572a723ff7a610be7c9",
"assets/assets/images/currency/sakura.png": "182a7a26f238b310300a413d600e4cac",
"assets/assets/images/currency/reverse_scale.png": "7d9065e0f191489f30aaccda7fb0a7fd",
"assets/assets/images/currency/jade.png": "51e7630da54da954651f7243cee78968",
"assets/assets/images/currency/daruma.png": "468d0917acb6bcddefd3c9bd4f0d905b",
"assets/assets/images/currency/mystery_amulet.png": "0c7ba0152753059432d4517a94de3252",
"assets/assets/images/currency/coin.png": "0bd4900751d7dda66260480ea955e636",
"assets/assets/images/currency/s_jade.png": "7ecda6daa71c020da5ec08fa4ef4eb4b",
"assets/assets/images/currency/totem_key.png": "8982707a81ba53b481f8e2261d49b723",
"assets/assets/images/currency/sp_skin_token.png": "4715ff8973d9eebf17c1f0642344b329",
"assets/assets/images/currency/medal.png": "57c78bd46085bc79cba585db48ae4b44",
"assets/assets/images/currency/ofuda.png": "c97f54ca6219855bb0d4bac8613f4a27",
"assets/AssetManifest.bin": "1975122e8d2e61d92f3bd22d4d71994f",
"assets/AssetManifest.json": "32049beaccad548203605b98605073a3",
"assets/AssetManifest.bin.json": "f15cd66daf5f1140a450d8ab693519b2",
"assets/NOTICES": "6c901c5fee88ae2e3b3fa2e3a3b1b710",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"flutter_bootstrap.js": "553826fb356b1a162c9f2d41fb8ddbde",
"favicon.png": "7aff1cacaa1bf0b82d1edfd4978951f7",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"index.html": "634294f5d66dd841846758fcfe511cb8",
"/": "634294f5d66dd841846758fcfe511cb8",
"main.dart.js": "68b39a30a699711ee3298e830ce6a82c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
