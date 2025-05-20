import React, { useState, useEffect, useRef } from 'react';
import ReactDOM from 'react-dom';
import maplibregl from 'maplibre-gl';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://yuamroqhxrflusxeyylp.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1YW1yb3FoeHJmbHVzeGV5eWxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NjA2ODgsImV4cCI6MjA2MTQzNjY4OH0.GOzgzWLxQnT6YzS8z2D4OKrsHkBnS55L7oRTMsEKs8U'
);

const App = () => {
  const [map, setMap] = useState(null);
  const [locations, setLocations] = useState({});
  const locationsRef = useRef(locations);
  locationsRef.current = locations;

  // Térkép inicializálása
  useEffect(() => {
    console.log('Starting map initialization');
    if (!document.getElementById('map')) {
      console.error('Map container not found');
      return;
    }
    try {
      const mapInstance = new maplibregl.Map({
        container: 'map',
        style: {
          version: 8,
          sources: {
            osm: {
              type: 'raster',
              tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
              tileSize: 256,
              attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            }
          },
          layers: [{
            id: 'osm-tiles',
            type: 'raster',
            source: 'osm',
            minzoom: 0,
            maxzoom: 19
          }]
        },
        center: [20.729, 48.097], // Miskolc középpontja
        zoom: 11
      });
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

  // Valós idejű Supabase előfizetés
  useEffect(() => {
    console.log('Setting up Supabase Realtime subscription');
    const subscription = supabase
      .channel('schema-db-changes')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'locations'
        },
        (payload) => {
          console.log('Received INSERT event:', payload);
          const loc = payload.new;
          const updated = {
            ...locationsRef.current,
            [loc.user_id.toString()]: loc
          };
          setLocations(updated);
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
    if (map && Object.keys(locations).length > 0) {
      console.log('Adding markers to map:', locations);
      Object.entries(locations).forEach(([userId, loc]) => {
        if (loc.lat && loc.long) {
          new maplibregl.Marker({ color: 'red' })
            .setLngLat([loc.long, loc.lat])
            .addTo(map);
        } else {
          console.warn(`Invalid coordinates for user ${userId}:`, loc);
        }
      });
    }
  }, [map, locations]);

  return null;
};

ReactDOM.render(<App />, document.getElementById('root'));
