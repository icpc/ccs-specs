(function () {
  function build(versions) {
    // ReadTheDocs theme: place the switcher in the sidebar search box.
    var host = document.querySelector('.wy-side-nav-search') ||
               document.querySelector('.md-header__inner');
    if (!host) return;
    var seg = window.location.pathname.split('/').filter(Boolean)[0];
    var current = versions.indexOf(seg) >= 0 ? seg : versions[0];
    var wrap = document.createElement('div');
    wrap.className = 'md-version-switch';
    var select = document.createElement('select');
    select.setAttribute('aria-label', 'Select specification version');
    versions.forEach(function (v) {
      var o = document.createElement('option');
      o.value = v; o.text = v;
      select.appendChild(o);
    });
    select.value = current;
    select.onchange = function () {
      window.location.href = window.location.origin + '/' + select.value + '/';
    };
    wrap.appendChild(select);
    host.appendChild(wrap);
  }
  fetch('/versions.json')
    .then(function (r) { return r.json(); })
    .then(build)
    .catch(function () {});
})();
