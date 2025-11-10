import os
import shutil

# Directories and paths
repo_dir = "/Users/szamosiattila/mfksensor"
docs_dir = os.path.join(repo_dir, "docs")
logos_dir = os.path.join(docs_dir, "logos")
logo_source_dir = "/Users/szamosiattila/mfksensor/images"  # Update with actual path
logo_files = ["logo1.png", "logo2.png", "logo3.png"]  # Update with actual file names

# Create directories
os.makedirs(docs_dir, exist_ok=True)
os.makedirs(logos_dir, exist_ok=True)

# index.html content
index_html_content = """<!DOCTYPE html>
<html lang="hu">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Éghajlatváltozás Multidiszciplináris Nemzeti Laboratórium 7B alprojekt levegőminőség szenzor adatok</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/PapaParse/5.4.1/papaparse.min.js"></script>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gradient-to-br from-green-50 to-blue-50 font-sans min-h-screen flex flex-col">
  <header class="bg-green-700 text-white text-center py-8 shadow-lg">
    <h1 class="text-2xl md:text-4xl font-extrabold tracking-tight">Éghajlatváltozás Multidiszciplináris Nemzeti Laboratórium 7B alprojekt levegőminőség szenzor adatok</h1>
  </header>

  <nav class="bg-green-600 text-white py-4 shadow-md">
    <div class="container mx-auto px-6 flex justify-center space-x-8">
      <a href="/mfksensor/" class="text-lg font-semibold hover:text-green-200 transition-colors">Kezdőlap</a>
      <a href="/mfksensor/map.html" class="text-lg font-semibold hover:text-green-200 transition-colors">Térkép</a>
    </div>
  </nav>

  <div class="container mx-auto p-6 flex-grow">
    <div class="flex justify-center space-x-6 my-8">
      <img src="/mfksensor/logos/logo1.png" alt="Logo 1" class="h-14 transition-transform hover:scale-105">
      <img src="/mfksensor/logos/logo2.png" alt="Logo 2" class="h-14 transition-transform hover:scale-105">
      <img src="/mfksensor/logos/logo3.png" alt="Logo 3" class="h-14 transition-transform hover:scale-105">
    </div>

    <div class="mb-8 max-w-md mx-auto">
      <label for="sensorSelect" class="block text-lg font-semibold text-gray-700 mb-2">Válassz szenzort:</label>
      <select id="sensorSelect" class="w-full p-3 border border-gray-300 rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-green-500">
        <option value="sensor1">Egri Szenzor</option>
      </select>
    </div>

    <div id="dataContainer" class="bg-white p-6 rounded-xl shadow-xl max-w-4xl mx-auto">
      <div id="dataTable" class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4 text-center"></div>
    </div>

    <div id="lastUpdated" class="text-center mt-6 text-gray-600 text-sm"></div>

    <div class="text-center mt-4 text-red-600 font-semibold">A mérési adatok nem hitelesítettek.</div>
  </div>

  <footer class="bg-green-700 text-white text-center py-4 mt-auto">
    <p class="text-sm">© Éghajlatváltozás Multidiszciplináris Nemzeti Laboratórium projekt támogatásával valósul meg.</p>
  </footer>

  <script>
    const csvUrl = 'https://docs.google.com/spreadsheets/d/e/2PACX-1vR8PPhpLDrZaQSjFH8y9_c1GU6mEPjpy1IBFy5FkCyFi2-XNYpHYJLDkibO8UFu4vDw_VwQVv8pnJcV/pub?gid=0&single=true&output=csv';
    const dataTable = document.getElementById('dataTable');
    const lastUpdated = document.getElementById('lastUpdated');
    const sensorSelect = document.getElementById('sensorSelect');

    async function fetchAndDisplayData() {
      try {
        console.log('Fetching data from:', csvUrl);
        const response = await fetch(csvUrl, { cache: 'no-store' });
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status} ${response.statusText}`);
        }
        const csvText = await response.text();

        if (!csvText || csvText.trim() === '') {
          throw new Error('Empty or invalid CSV data received');
        }

        Papa.parse(csvText, {
          header: true,
          skipEmptyLines: true,
          complete: function(results) {
            console.log('Parsed data:', results.data);
            if (results.data.length === 0 || !results.data[0]) {
              dataTable.innerHTML = '<p class="text-red-500 col-span-full">Nincs adat.</p>';
              return;
            }

            const latestData = results.data[results.data.length - 1];
            dataTable.innerHTML = '';

            const fields = [
              { key: 'Timestamp', label: 'Időbélyeg', unit: '' },
              { key: 'PM1', label: 'PM1', unit: 'µg/m³' },
              { key: 'PM2,5', label: 'PM2.5', unit: 'µg/m³' },
              { key: 'PM4', label: 'PM4', unit: 'µg/m³' },
              { key: 'PM10', label: 'PM10', unit: 'µg/m³' },
              { key: 'Humidity', label: 'Páratartalom', unit: '%' },
              { key: 'Temp', label: 'Hőmérséklet', unit: '°C' },
              { key: 'VOC', label: 'VOC', unit: 'index' },
              { key: 'NOx', label: 'NOx', unit: 'index' },
              { key: 'CO2', label: 'CO2', unit: 'ppm' }
            ];

            fields.forEach(field => {
              const value = latestData[field.key] || 'N/A';
              const cell = document.createElement('div');
              cell.className = `p-4 bg-gray-50 rounded-lg shadow-sm hover:shadow-md transition-shadow ${
                field.key === 'Timestamp' ? 'lg:col-span-3' : ''
              }`;
              cell.innerHTML = `
                <h3 class="text-sm font-semibold text-green-700">${field.label}</h3>
                <p class="text-lg font-bold text-gray-800">${value} <span class="text-gray-500">${field.unit}</span></p>
              `;
              dataTable.appendChild(cell);
            });

            lastUpdated.textContent = `Utolsó frissítés: ${new Date().toLocaleString('hu-HU')}`;
          },
          error: function(error) {
            dataTable.innerHTML = '<p class="text-red-500 col-span-full">Hiba az adatok feldolgozásakor. Kérjük, ellenőrizze a Google Sheets megosztási beállításait.</p>';
            console.error('Papa Parse error:', error);
          }
        });
      } catch (error) {
        dataTable.innerHTML = '<p class="text-red-500 col-span-full">Hiba az adatok lekérésekor: ' + error.message + '. Lehetséges CORS probléma vagy érvénytelen URL.</p>';
        console.error('Fetch error:', error);
      }
    }

    if (typeof Papa === 'undefined') {
      dataTable.innerHTML = '<p class="text-red-500 col-span-full">Hiba: A Papa Parse könyvtár nem töltődött be.</p>';
      console.error('Papa Parse not loaded');
    } else {
      fetchAndDisplayData();
      setInterval(fetchAndDisplayData, 15000);
      sensorSelect.addEventListener('change', () => {
        fetchAndDisplayData();
      });
    }
  </script>
</body>
</html>
"""

# map.html content
map_html_content = """<!DOCTYPE html>
<html lang="hu">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Levegőminőségi Térkép</title>
  <link rel="stylesheet" href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css" />
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    #map { height: calc(100vh - 100px); }
  </style>
</head>
<body class="bg-gradient-to-br from-green-50 to-blue-50 font-sans min-h-screen flex flex-col">
  <header class="bg-green-700 text-white text-center py-8 shadow-lg">
    <h1 class="text-2xl md:text-4xl font-extrabold tracking-tight">Éghajlatváltozás Multidiszciplináris Nemzeti Laboratórium 7B alprojekt levegőminőség szenzor adatok</h1>
  </header>

  <nav class="bg-green-600 text-white py-4 shadow-md">
    <div class="container mx-auto px-6 flex justify-center space-x-8">
      <a href="/mfksensor/" class="text-lg font-semibold hover:text-green-200 transition-colors">Kezdőlap</a>
      <a href="/mfksensor/map.html" class="text-lg font-semibold hover:text-green-200 transition-colors">Térkép</a>
    </div>
  </nav>

  <div class="container mx-auto p-6 flex-grow">
    <div id="map" class="bg-white rounded-xl shadow-xl"></div>
  </div>

  <footer class="bg-green-700 text-white text-center py-4 mt-auto">
    <p class="text-sm">© Éghajlatváltozás Multidiszciplináris Nemzeti Laboratórium projekt támogatásával valósul meg.</p>
  </footer>

  <script src="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js"></script>
  <script>
    document.addEventListener('DOMContentLoaded', () => {
      try {
        console.log('Starting map initialization');
        if (!document.getElementById('map')) {
          throw new Error('Map container not found');
        }
        if (typeof supabase === 'undefined') {
          throw new Error('Supabase JS library not loaded. Check network or script URL.');
        }

        const supabaseClient = supabase.createClient(
          'https://yuamroqhxrflusxeyylp.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1YW1yb3FoeHJmbHVzeGV5eWxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NjA2ODgsImV4cCI6MjA2MTQzNjY4OH0.GOzgzWLxQnT6YzS8z2D4OKrsHkBnS55L7oRTMsEKs8U'
        );
        console.log('Supabase client initialized');

        const map = new maplibregl.Map({
          container: 'map',
          style: {
            version: 8,
            sources: {
              osm: {
                type: 'raster',
                tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
                tileSize: 256,
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              },
              air_quality: {
                type: 'vector',
                tiles: ['supabase://air_quality_mvt/{z}/{x}/{y}']
              }
            },
            layers: [
              {
                id: 'osm-tiles',
                type: 'raster',
                source: 'osm',
                minzoom: 0,
                maxzoom: 19
              },
              {
                id: 'air_quality',
                type: 'circle',
                source: 'air_quality',
                'source-layer': 'air_quality',
                paint: {
                  'circle-radius': 8,
                  'circle-color': [
                    'interpolate',
                    ['linear'],
                    ['get', 'pm2_5'],
                    0, '#00ff00',
                    50, '#ff0000'
                  ]
                }
              }
            ]
          },
          center: [20.362, 47.898],
          zoom: 11
        });
        console.log('Map initialized successfully');

        maplibregl.addProtocol('supabase', async (params, callback) => {
          try {
            console.log('Fetching tile:', params.url);
            const [, , z, x, y] = params.url.match(/(\\w+):\\/\\/(\\w+)\\/(\\d+)\\/(\\d+)\\/(\\d+)/);
            const { data, error } = await supabaseClient.rpc('air_quality_mvt', { z: parseInt(z), x: parseInt(x), y: parseInt(y) });
            if (error) {
              console.error('Supabase RPC error:', error);
              callback(error);
              return;
            }
            if (!data) {
              console.warn('No data returned from air_quality_mvt for tile:', { z, x, y });
              callback(null, new ArrayBuffer(0));
              return;
            }
            const binaryData = Uint8Array.from(atob(data), c => c.charCodeAt(0)).buffer;
            callback(null, binaryData);
          } catch (error) {
            console.error('Error in supabase protocol:', error);
            callback(error);
          }
        });

        map.on('click', 'air_quality', (e) => {
          const props = e.features[0].properties;
          new maplibregl.Popup()
            .setLngLat(e.lngLat)
            .setHTML(`
              <div style="padding: 8px;">
                <p><b>Idő:</b> ${new Date(props.timestamp).toLocaleString('hu-HU')}</p>
                <p><b>PM2.5:</b> ${props.pm2_5 ? props.pm2_5.toFixed(2) : 'N/A'} µg/m³</p>
                <p><b>Hőmérséklet:</b> ${props.temperature ? props.temperature.toFixed(2) : 'N/A'}°C</p>
                <p><b>Páratartalom:</b> ${props.humidity ? props.humidity.toFixed(2) : 'N/A'}%</p>
                <p><b>CO₂:</b> ${props.co2 ? props.co2 : 'N/A'} ppm</p>
              </div>
            `)
            .addTo(map);
        });

        map.on('mouseenter', 'air_quality', () => {
          map.getCanvas().style.cursor = 'pointer';
        });

        map.on('mouseleave', 'air_quality', () => {
          map.getCanvas().style.cursor = '';
        });

        map.on('error', (e) => {
          console.error('Map error:', e.error);
        });
      } catch (error) {
        console.error('Map initialization error:', error);
        const mapContainer = document.getElementById('map');
        if (mapContainer) {
          mapContainer.innerHTML = '<p class="text-red-500 text-center p-4">Hiba a térkép inicializálásakor: ' + error.message + '</p>';
        }
      }
    });
  </script>
</body>
</html>
"""

# supabase_setup.sql content
supabase_sql_content = """-- Create air_quality_with_coords view
CREATE OR REPLACE VIEW air_quality_with_coords AS
SELECT
  id,
  timestamp,
  pm1_0,
  pm2_5,
  pm4_0,
  pm10_0,
  humidity,
  temperature,
  voc,
  nox,
  co2,
  ST_X(location::geometry) AS long,
  ST_Y(location::geometry) AS lat
FROM air_quality;

-- Grant permissions for view
GRANT SELECT ON air_quality_with_coords TO anon;

-- Create air_quality_mvt function
CREATE OR REPLACE FUNCTION air_quality_mvt(z integer, x integer, y integer)
RETURNS bytea AS $$
DECLARE
  result bytea;
BEGIN
  SELECT INTO result ST_AsMVT(q, 'air_quality', 4096, 'geom')
  FROM (
    SELECT
      id,
      timestamp,
      pm2_5,
      temperature,
      humidity,
      co2,
      ST_AsMVTGeom(
        ST_Transform(ST_SetSRID(ST_MakePoint(long, lat), 4326), 3857),
        ST_TileEnvelope(z, x, y),
        4096,
        64,
        true
      ) AS geom
    FROM air_quality_with_coords
    WHERE ST_Transform(ST_SetSRID(ST_MakePoint(long, lat), 4326), 3857) && ST_TileEnvelope(z, x, y)
  ) q;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions for function and table
GRANT SELECT, INSERT ON air_quality TO anon;
GRANT EXECUTE ON FUNCTION air_quality_mvt TO anon;

-- Insert test data
INSERT INTO air_quality (id, timestamp, pm2_5, location)
VALUES
  ('03eca266-69ff-4d05-a2ff-19d57dd9e68f', '2025-05-14 05:46:35+00', 1.9, ST_SetSRID(ST_MakePoint(20.3622481689861, 47.8982806426855), 4326)),
  ('d1467dad-89e7-4f7f-abfc-5c23126a65eb', '2025-05-14 05:46:37+00', 1.9, ST_SetSRID(ST_MakePoint(20.3622481689861, 47.8982806426855), 4326));
"""

# Write files
with open(os.path.join(docs_dir, "index.html"), "w", encoding="utf-8") as f:
    f.write(index_html_content)

with open(os.path.join(docs_dir, "map.html"), "w", encoding="utf-8") as f:
    f.write(map_html_content)

with open(os.path.join(repo_dir, "supabase_setup.sql"), "w", encoding="utf-8") as f:
    f.write(supabase_sql_content)

# Copy logo files
for logo_file in logo_files:
    src_path = os.path.join(logo_source_dir, logo_file)
    dst_path = os.path.join(logos_dir, logo_file)
    if os.path.exists(src_path):
        shutil.copy(src_path, dst_path)
    else:
        print(f"Warning: Logo file {src_path} not found. Please copy manually.")

print("Files created successfully:")
print(f"- {os.path.join(docs_dir, 'index.html')}")
print(f"- {os.path.join(docs_dir, 'map.html')}")
print(f"- {os.path.join(repo_dir, 'supabase_setup.sql')}")
print(f"Logos directory created: {logos_dir}")
print("Please copy logo files to the logos directory if not already present.")
