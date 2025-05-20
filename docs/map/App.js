const { useState, useEffect, useRef } = React;

const supabase = window.supabase.createClient(
  'https://yuamroqhxrflusxeyylp.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1YW1yb3FoeHJmbHVzeGV5eWxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NjA2ODgsImV4cCI6MjA2MTQzNjY4OH0.GOzgzWLxQnT6YzS8z2D4OKrsHkBnS55L7oRTMsEKs8U'
);

function App() {
  const [map, setMap] = useState(null);
  const [measurements, setMeasurements] = useState([]);
  const markersRef = useRef({});

  // Térkép inicializálása
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

  // Adatok lekérése
  useEffect(() => {
    const fetchData = async () => {
      const { data, error } = await supabase
        .from('air_quality')
        .select(`
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
          st_x(location::geometry) as long,
          st_y(location::geometry) as lat
        `)
        .limit(10);

      if (error) {
        console.error('Error fetching data:', error);
        return;
      }

      if (data) {
        // Szűrjük ki az érvénytelen koordinátájú adatokat
        const validData = data.filter(m => m.lat != null && m.long != null);
        setMeasurements(validData);
      }
    };
    fetchData();
  }, []);

  // Valós idejű frissítések
  useEffect(() => {
    const channel = supabase
      .channel('realtime-air-quality')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'air_quality',
        },
        (payload) => {
          const newMeasurement = {
            ...payload.new,
            long: payload.new.st_x,
            lat: payload.new.st_y,
          };

          // Csak érvényes koordinátájú adatokat adjunk hozzá
          if (newMeasurement.lat == null || newMeasurement.long == null) {
            console.warn('Invalid coordinates in realtime update:', newMeasurement);
            return;
          }

          setMeasurements((prev) => [...prev, newMeasurement]);
        }
      )
      .subscribe();

    return () => supabase.removeChannel(channel);
  }, []);

  // Markerek kezelése
  useEffect(() => {
    if (!map) return;

    // Régi markerek törlése
    Object.values(markersRef.current).forEach((marker) => marker.remove());
    markersRef.current = {};

    // Új markerek hozzáadása
    measurements.forEach((m) => {
      if (m.lat == null || m.long == null) {
        console.warn('Skipping marker due to invalid coordinates:', m);
        return;
      }

      const marker = L.marker([m.lat, m.long])
        .bindPopup(`
          <div style="padding: 8px;">
            <p><b>Idő:</b> ${new Date(m.timestamp).toLocaleString('hu-HU')}</p>
            <p><b>PM2.5:</b> ${m.pm2_5 != null ? m.pm2_5.toFixed(2) : 'N/A'} µg/m³</p>
            <p><b>Hőmérséklet:</b> ${m.temperature != null ? m.temperature.toFixed(2) : 'N/A'}°C</p>
            <p><b>Páratartalom:</b> ${m.humidity != null ? m.humidity.toFixed(2) : 'N/A'}%</p>
            <p><b>CO₂:</b> ${m.co2 != null ? m.co2 : 'N/A'} ppm</p>
          </div>
        `)
        .addTo(map);

      markersRef.current[m.id] = marker;
    });
  }, [map, measurements]);

  return null;
}

// React 18 createRoot
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);