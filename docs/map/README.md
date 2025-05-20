# Valós Idejű Térképalkalmazás

Ez egy valós idejű térképalkalmazás, amely Supabase Realtime és MapLibre GL JS használatával készült. Az alkalmazás az `air_quality` tábla adatait jeleníti meg egy interaktív térképen.

## Telepítés és futtatás

1. **Alkalmazás futtatása**:
   - Helyezz egy egyszerű HTTP szervert (pl. `http-server` vagy `live-server`) a mappába, és indítsd el:
     ```bash
     npx http-server
     ```
   - Nyisd meg a böngészőben a kapott URL-t (általában `http://localhost:8080`).

## Supabase beállítás

- **Tábla ellenőrzése**: Győződj meg róla, hogy az `air_quality` tábla létezik a Supabase projektedben, és tartalmazza a `location` oszlopot GeoJSON formátumban:
   ```sql
   SELECT * FROM air_quality LIMIT 1;
   ```
- **Jogosultságok beállítása**: Engedélyezd az anon szerepkör számára a `SELECT` műveletet:
   ```sql
   CREATE POLICY "Allow anon to read air_quality" ON air_quality FOR SELECT TO anon USING (true);
   CREATE POLICY "Allow anon to insert air_quality" ON air_quality FOR INSERT TO anon WITH CHECK (true);
   ```

- **Valós idejű engedélyezés**: Engedélyezd a Realtime-ot az `air_quality` táblán a Supabase dashboardon.

## Adatok hozzáadása

Manuálisan adhatsz hozzá adatokat az `air_quality` táblához a Supabase dashboardon keresztül, például:
```sql
INSERT INTO air_quality (timestamp, location, pm2_5, temperature, humidity, co2) VALUES (
  NOW(),
  ST_SetSRID(ST_MakePoint(20.729, 48.097), 4326),
  25.5,
  22.3,
  45,
  400
);
```

## Fejlesztés

- A térkép Miskolc középpontjára van állítva (`20.729, 48.097`).
- Az OSM csempéket használja a térkép alapjául.
- A levegőminőségi adatok valós idejű frissítése Supabase Realtime segítségével történik.
