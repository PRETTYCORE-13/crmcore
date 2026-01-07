// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/prettycore"
import topbar from "../vendor/topbar"

// Cargar Leaflet una sola vez globalmente
let leafletLoaded = false;
let leafletLoadingPromise = null;

function loadLeaflet() {
  if (leafletLoaded && window.L) {
    return Promise.resolve();
  }

  if (leafletLoadingPromise) {
    return leafletLoadingPromise;
  }

  leafletLoadingPromise = new Promise((resolve, reject) => {
    // Cargar CSS
    if (!document.getElementById('leaflet-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      link.integrity = 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=';
      link.crossOrigin = '';
      document.head.appendChild(link);
    }

    // Cargar JS
    if (!window.L) {
      const script = document.createElement('script');
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.integrity = 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=';
      script.crossOrigin = '';
      script.onload = () => {
        leafletLoaded = true;
        resolve();
      };
      script.onerror = () => {
        reject(new Error('Error al cargar Leaflet'));
      };
      document.head.appendChild(script);
    } else {
      leafletLoaded = true;
      resolve();
    }
  });

  return leafletLoadingPromise;
}

// Hook para Mapa Interactivo con Leaflet
const LocationMap = {
  mounted() {
    this.initializeMap();
  },

  async initializeMap() {
    try {
      await loadLeaflet();

      // Esperar un tick para asegurar que el DOM esté listo
      requestAnimationFrame(() => {
        this.initMap();
      });
    } catch (error) {
      console.error('Error cargando Leaflet:', error);
      this.showError();
    }
  },

  initMap() {
    if (!window.L) {
      console.error('Leaflet no está disponible');
      return;
    }

    const lat = parseFloat(this.el.dataset.lat) || 19.4326;
    const lng = parseFloat(this.el.dataset.lng) || -99.1332;

    try {
      // Limpiar mapa existente si hay uno
      if (this.map) {
        this.map.remove();
      }

      // Inicializar mapa
      this.map = L.map(this.el, {
        center: [lat, lng],
        zoom: 13,
        zoomControl: true,
        attributionControl: true,
        preferCanvas: true // Mejor rendimiento
      });

      // Agregar capa de tiles con configuración optimizada
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap',
        maxZoom: 19,
        minZoom: 3,
        updateWhenZooming: false,
        updateWhenIdle: true,
        keepBuffer: 2
      }).addTo(this.map);

      // Agregar marcador
      this.marker = L.marker([lat, lng], {
        draggable: true,
        title: 'Arrastre para mover'
      }).addTo(this.map);

      // Ajustar tamaño inmediatamente
      this.map.invalidateSize();

      // Eventos del marcador
      this.marker.on('dragend', (e) => {
        const position = e.target.getLatLng();
        this.updateCoordinates(position.lat, position.lng);
      });

      // Evento de clic en el mapa
      this.map.on('click', (e) => {
        const { lat, lng } = e.latlng;
        this.marker.setLatLng([lat, lng]);
        this.updateCoordinates(lat, lng);
      });

    } catch (error) {
      console.error('Error al inicializar el mapa:', error);
      this.showError();
    }
  },

  showError() {
    this.el.innerHTML = `
      <div style="display: flex; align-items: center; justify-content: center; height: 100%; flex-direction: column;">
        <p style="color: #dc2626; margin-bottom: 8px;">Error al cargar el mapa</p>
        <button onclick="location.reload()" style="padding: 8px 16px; background: #3b82f6; color: white; border: none; border-radius: 4px; cursor: pointer;">
          Recargar página
        </button>
      </div>
    `;
  },

  updateCoordinates(lat, lng) {
    const mapXInput = document.querySelector('input[name="cliente_form[map_x]"]');
    const mapYInput = document.querySelector('input[name="cliente_form[map_y]"]');

    if (mapXInput) mapXInput.value = lng.toFixed(6);
    if (mapYInput) mapYInput.value = lat.toFixed(6);

    this.pushEvent("update_coordinates", { lat: lat, lng: lng });
  },

  updated() {
    if (!this.map) return;

    const lat = parseFloat(this.el.dataset.lat) || 19.4326;
    const lng = parseFloat(this.el.dataset.lng) || -99.1332;

    if (this.marker) {
      this.marker.setLatLng([lat, lng]);
      this.map.setView([lat, lng]);
      this.map.invalidateSize();
    }
  },

  destroyed() {
    if (this.map) {
      this.map.remove();
      this.map = null;
      this.marker = null;
    }
  }
};

// Hook para navegación retrasada después de mostrar flash
const NavigateAfterFlash = {
  mounted() {
    this.handleEvent("navigate-after-flash", ({to, delay}) => {
      setTimeout(() => {
        window.location.href = to;
      }, delay);
    });
  }
};

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, LocationMap, NavigateAfterFlash},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

