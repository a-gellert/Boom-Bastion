/* Bastion Blast — Poki SDK bridge.
 * Loaded from index.html by tools/patch_bundle.js. On non-Poki hosts every call
 * is a no-op, so the same bundle runs on itch.io, Yandex and localhost.
 *
 * Headless tests set window.BastionPokiTest = true (tools/web_smoke.js --poki=1):
 * the bridge then reports itself as available and completes a fake ad in 700 ms.
 */
(function () {
  'use strict';

  function isTest() {
    return window.BastionPokiTest === true || /[?&]pokitest=1/.test(location.search);
  }
  var sdk = null;
  var loading = false;
  var adActive = false;
  var log = [];

  function note(name, extra) {
    log.push({ name: name, t: Date.now(), extra: extra || null });
    if (log.length > 40) log.shift();
    if (window.console && console.log) console.log('[POKI]', name, extra || '');
  }

  function onPokiHost() {
    var h = location.hostname || '';
    return /(^|\.)poki\.com$/.test(h) || /(^|\.)poki-gdn\.com$/.test(h) || /(^|\.)poki\.dev$/.test(h);
  }

  function load() {
    if (sdk || loading || isTest() || !onPokiHost()) return;
    loading = true;
    var s = document.createElement('script');
    s.src = 'https://game-cdn.poki.com/scripts/v2/poki-sdk.js';
    s.async = true;
    s.onload = function () {
      if (!window.PokiSDK || !window.PokiSDK.init) { note('sdk-missing'); return; }
      window.PokiSDK.init().then(function () {
        sdk = window.PokiSDK;
        note('ready');
      }).catch(function (e) {
        note('init-failed', String(e || ''));
      });
    };
    s.onerror = function () { note('load-failed'); };
    document.head.appendChild(s);
  }

  function call(name, fn) {
    if (!sdk || !sdk[name]) return;
    try { fn(sdk[name]); } catch (e) { note(name + '-error', String(e || '')); }
  }

  window.BastionPoki = {
    available: function () { return isTest() || !!sdk; },
    gameLoadingFinished: function () {
      note('gameLoadingFinished');
      call('gameLoadingFinished', function (f) { f(); });
    },
    gameplayStart: function () {
      note('gameplayStart');
      call('gameplayStart', function (f) { f(); });
    },
    gameplayStop: function () {
      note('gameplayStop');
      call('gameplayStop', function (f) { f(); });
    },
    happyTime: function () {
      note('happyTime');
      call('happyTime', function (f) { f(); });
    },
    commercialBreak: function () {
      note('commercialBreak');
      if (isTest()) {
        adActive = true;
        setTimeout(function () { adActive = false; note('adEnd'); }, 700);
        return true;
      }
      if (!sdk || !sdk.commercialBreak) return false;
      adActive = true;
      try {
        sdk.commercialBreak().then(function () {
          adActive = false;
          note('adEnd');
        }).catch(function () {
          adActive = false;
          note('ad-failed');
        });
      } catch (e) {
        adActive = false;
        note('ad-error', String(e || ''));
        return false;
      }
      return true;
    },
    adActive: function () { return adActive; },
    log: log
  };

  load();
})();
