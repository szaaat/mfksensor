const { useState, useEffect, useRef } = React;

// Supabase kliens inicializálása
const supabase = Supabase.createClient(
  '[invalid url, do not cite]',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1YW1yb3FoeHJmbHVzeGV5eWxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NjA2ODgsImV4cCI6MjA2MTQzNjY4OH0.GOzgzWLxQnT6YzS8z2D4OKrsHkBnS55L7oRTMsEKs8U'
);

function App() {
  const [map, setMap] = useState(null);
  const [measurements, setMeasurements] = useState({});
  const measurementsRef = useRef(measurements);
  measurementsRef.current = measurements;

  // Leaflet térkép inicializálása
  useEffect(() => {
    console.log('Starting map initialization');
    if (!document.getElementById('map')) {
      console.error('Map container not found');
      return;
    }
    if (typeof L === 'undefined') {
      console.error('Leaflet is not loaded');
      return;
    }
    try {
      const mapInstance = L.map('map').setView([48.097, 20.729], 11); // Miskolc középpontja
      L.tileLayer('[invalid url, do not cite] {
        attribution: '© <a href="[invalid url, do not cite] contributors',
        maxZoom: 19,
      }).addTo(mapInstance);
      console.log('Map initialized successfully');
      setMap(mapInstance);

      return () => {
        console.log('Removing map instance');
        mapInstance.remove();
      };
    } catch (e) {
      console.error('Error initializing map:', e);
    }
  }, []);

  // Kezdeti adatok lekérése az air_quality táblából
  useEffect(() => {
    async function fetchInitialData() {
      console.log('Fetching initial air_quality data');
      try {
        const { data, error } = await supabase
          .from('air_quality')
          .select('id, timestamp, ST_AsGeoJSON(location) AS location, pm2_5, temperature, humidity, co2')
          .limit(10);
        if (error) {
          console.error('Supabase error:', error.message, error.status);
          return;
        }
        console.log('Initial data fetched:', data);
        if (!data || data.length === 0) {
          console.warn('No data found in air_quality table');
          return;
        }
        const initialMeasurements = {};
        data.forEach((measurement) => {
          try {
            console.log('Processing measurement:', measurement);
            if (measurement.location) {
              const geojson = JSON.parse(measurement.location);
              if (geojson && geojson.coordinates) {
                measurement.long = geojson.coordinates[0];
                measurement.lat = geojson.coordinates[1];
                console.log('Parsed coordinates:', measurement.long, measurement.lat);
                initialMeasurements[measurement.id] = measurement;
              } else {
                console.warn('Invalid GeoJSON coordinates:', measurement.location);
              }
            } else {
                console.warn('No location data for measurement:', measurement.id);
            }
          } catch (e) {
            console.error('Error parsing GeoJSON for initial measurement:', measurement.id, e);
          }
        });
        console.log('Processed measurements:', initialMeasurements);
        setMeasurements(initialMeasurements);
      } catch (e) {
        console.error('Detailed fetch error:', {
          message: e.message,
          stack: e.stack,
          name: e.name,
          cause: e.cause
        });
      }
    }
    fetchInitialData();
  }, []);

  // Valós idejű Supabase előfizetés az air_quality táblára
  useEffect(() => {
    console.log('Setting up Supabase Realtime subscription for air_quality');
    const subscription = supabase
      .channel('schema-db-changes')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'air_quality'
        },
        (payload) => {
          console.log('Received INSERT event:', payload);
          const measurement = payload.new;
          try {
            if (measurement.location) {
              const geojson = JSON.parse(measurement.location);
              if (geojson && geojson.coordinates) {
                measurement.long = geojson.coordinates[0];
                measurement.lat = geojson.coordinates[1];
              } else {
                console.warn('Invalid GeoJSON coordinates for measurement:', measurement.id, geojson);
                return;
              }
            } else {
              console.warn('No location data for measurement:', measurement.id);
              return;
            }
          } catch (e) {
            console.error('Error parsing GeoJSON for measurement:', measurement.id, e);
            return;
          }
          const updated = {
            ...measurementsRef.current,
            [measurement.id.toString()]: measurement
          };
          setMeasurements(updated);
        }
      )
      .subscribe((status) => {
        console.log('Subscription status:', status);
      });

    return () => {
      console.log('Unsubscribing from Supabase Realtime');
      subscription.unsubscribe();
    };
  }, []);

  // Markerek hozzáadása a térképhez
  useEffect(() => {
    if (map && Object.keys(measurements).length > 0) {
      console.log('Adding markers to map:', measurements);
      Object.entries(measurements).forEach(([id, measurement]) => {
        if (measurement.lat && measurement.long) {
          const marker = L.marker([measurement.lat, measurement.long]).addTo(map);
          marker.bindPopup(
            `<div style="padding: 0.5rem; background-color: #f3f4f6; border-radius: 0.25rem;">
              <table style="width: 100%; font-size: 0.875rem;">
                <tr><td style="font-weight: bold;">Időpont:</td><td>${measurement.timestamp ? new Date(measurement.timestamp).toLocaleString('hu-HU') : 'N/A'}</td></tr>
                <tr><td style="font-weight: bold;">PM2.5:</td><td>${measurement.pm2_5 ? measurement.pm2_5.toFixed(2) : 'N/A'} µg/m³</td></tr>
                <tr><td style="font-weight: bold;">Hőmérséklet:</td><td>${measurement.temperature ? measurement.temperature.toFixed(2) : 'N/A'}°C</td></tr>
                <tr><td style="font-weight: bold;">Páratartalom:</td><td>${measurement.humidity ? measurement.humidity.toFixed(2) : 'N/A'}%</td></tr>
                <tr><td style="font-weight: bold;">CO₂:</td><td>${measurement.co2 || 'N/A'} ppm</td></tr>
              </table>
            </div>`
          ).openPopup();
        } else {
          console.warn(`Invalid coordinates for measurement ${id}:`, measurement);
        }
      });
    }
  }, [map, measurements]);
}

ReactDOM.render(App(), document.getElementById('root'));
