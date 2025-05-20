const { useState, useEffect, useRef } = React;

// Supabase kliens inicializálása
const supabase = window.supabase.createClient(
  'https://yuamroqhxrflusxeyylp.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1YW1yb3FoeHJmbHVzeGV5eWxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NjA2ODgsImV4cCI6MjA2MTQzNjY4OH0.GOzgzWLxQnT6YzS8z2D4OKrsHkBnS55L7oRTMsEKs8U'
);

function App() {
  const [map, setMap] = useState(null);
  const [measurements, setMeasurements] = useState([]);
  const markersRef = useRef({});

  // 1. Térkép inicializálása
  useEffect(() => {
    if (!document.getElementById('map') || typeof L === 'undefined') return;

    const mapInstance = L.map('map').setView([48.097, 20.729], 11);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(mapInstance);

    setMap(mapInstance);

    return () => mapInstance.remove();
  }, []);

  // 2. Kezdeti adatok lekérése
  useEffect(() => {
    const fetchData = async () => {
      const { data, error } = await supabase
        .from('air_quality')
        .select(`
          id,
          timestamp,
          pm2_5,
          temperature,
          humidity,
          co2,
          st_x(location::geometry) as long,
          st_y(location::geometry) as lat
        `)
        .limit(10);

      if (!error) setMeasurements(data || []);
    };

    fetchData();
  }, []);

  // 3. Valós idejű frissítések
  useEffect(() => {
    const channel = supabase
      .channel('realtime')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'air_quality'
      }, (payload) => {
        const newData = {
          ...payload.new,
          long: payload.new.location?.coordinates?.[0],
          lat: payload.new.location?.coordinates?.[1]
        };
        setMeasurements(prev => [...prev, newData]);
      })
      .subscribe();

    return () => supabase.removeChannel(channel);
  }, []);

  // 4. Markerek kezelése
  useEffect(() => {
    if (!map) return;

    // Régi markerek törlése
    Object.values(markersRef.current).forEach(marker => marker.remove());
    markersRef.current = {};

    // Új markerek hozzáadása
    measurements.forEach(measurement => {
      if (!measurement.lat || !measurement.long) return;

      const marker = L.marker([measurement.lat, measurement.long])
        .bindPopup(`
          <div class="popup-content">
            <p><b>Idő:</b> ${new Date(measurement.timestamp).toLocaleString('hu-HU')}</p>
            <p><b>PM2.5:</b> ${measurement.pm2_5?.toFixed(2)} µg/m³</p>
            <p><b>Hőmérséklet:</b> ${measurement.temperature?.toFixed(2)}°C</p>
            <p><b>Páratartalom:</b> ${measurement.humidity?.toFixed(2)}%</p>
            <p><b>CO₂:</b> ${measurement.co2 || 'N/A'} ppm</p>
          </div>
        `)
        .addTo(map);

      markersRef.current[measurement.id] = marker;
    });
  }, [map, measurements]);

  return null;
}

// React 18 root inicializálás
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);