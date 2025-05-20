import React, { useState, useEffect, useRef } from 'react';
import { createRoot } from 'react-dom/client';
import L from 'leaflet';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://yuamroqhxrflusxeyylp.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1YW1yb3FoeHJmbHVzeGV5eWxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NjA2ODgsImV4cCI6MjA2MTQzNjY4OH0.GOzgzWLxQnT6YzS8z2D4OKrsHkBnS55L7oRTMsEKs8U'
);

const App = () => {
  const [map, setMap] = useState(null);
  const [measurements, setMeasurements] = useState([]);
  const markersRef = useRef({});

  // Térkép inicializálása
  useEffect(() => {
    console.log('Starting map initialization');
    if (!document.getElementById('map')) {
      console.error('Map container not found');
      return;
    }
    try {
      const mapInstance = L.map('map').setView([48.097, 20.729], 11);
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
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

  // Kezdeti adatok lekérése a nézetből
  useEffect(() => {
    const fetchData = async () => {
      console.log('Fetching initial air quality data');
      const { data, error } = await supabase
        .from('air_quality_with_coords')
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
          long,
          lat
        `)
        .limit(100);

      if (error) {
        console.error('Error fetching data:', error);
        return;
      }

      if (data) {
        const validData = data.filter(m => m.lat != null && m.long != null);
        console.log('Fetched data:', validData);
        setMeasurements(validData);
      }
    };
    fetchData();
  }, []);

  // Valós idejű Supabase előfizetés
  useEffect(() => {
    console.log('Setting up Supabase Realtime subscription');
    const channel = supabase
      .channel('realtime-air-quality')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'air_quality',
        },
        async (payload) => {
          console.log('Received INSERT event:', payload);
          // Lekérdezzük az új rekord koordinátáit a nézetből
          const { data, error } = await supabase
            .from('air_quality_with_coords')
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
              long,
              lat
            `)
            .eq('id', payload.new.id)
            .single();

          if (error) {
            console.error('Error fetching coordinates for new record:', error);
            return;
          }

          if (data && data.lat != null && data.long != null) {
            setMeasurements((prev) => [...prev, data]);
          } else {
            console.warn('Invalid coordinates in realtime update:', data);
          }
        }
      )
      .subscribe((status) => {
        console.log('Subscription status:', status);
      });

    return () => {
      console.log('Unsubscribing from Supabase Realtime');
      supabase.removeChannel(channel);
    };
  }, []);

  // Markerek hozzáadása a térképhez
  useEffect(() => {
    if (!map) return;

    console.log('Updating markers:', measurements);
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
};

// React 18 createRoot
const root = createRoot(document.getElementById('root'));
root.render(<App />);
