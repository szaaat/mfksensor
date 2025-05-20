# Valós Idejű Térképalkalmazás

Ez egy valós idejű térképalkalmazás, amely Supabase Realtime és MapLibre GL JS használatával készült. Az alkalmazás helyadatokat jelenít meg egy interaktív térképen.

## Telepítés és futtatás

1. **Függőségek telepítése**:
   ```bash
   npm install
   ```

2. **Alkalmazás futtatása**:
   - Helyezz egy egyszerű HTTP szervert (pl. `http-server` vagy `live-server`) a mappába, és indítsd el:
     ```bash
     npx http-server
     ```
   - Nyisd meg a böngészőben a kapott URL-t (általában `http://localhost:8080`).

## Supabase beállítás

- **Tábla létrehozása**: Hozz létre egy `locations` táblát a Supabase projektedben:
   ```sql
   CREATE TABLE locations (
     id SERIAL PRIMARY KEY,
     user_id INTEGER NOT NULL,
     lat DOUBLE PRECISION NOT NULL,
     long DOUBLE PRECISION NOT NULL,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```
- **Jogosultságok beállítása**: Engedélyezd az anon szerepkör számára a `SELECT` és `INSERT` műveleteket:
   ```sql
   CREATE POLICY "Allow anon to read locations" ON locations FOR SELECT TO anon USING (true);
   CREATE POLICY "Allow anon to insert locations" ON locations FOR INSERT TO anon WITH CHECK (true);
   ```

- **Valós idejű engedélyezés**: Engedélyezd a Realtime-ot a `locations` táblán a Supabase dashboardon.

## Adatok hozzáadása

Manuálisan adhatsz hozzá helyadatokat a `locations` táblához a Supabase dashboardon keresztül:
```sql
INSERT INTO locations (user_id, lat, long) VALUES (1, 48.097, 20.729);
```

## Fejlesztés

- A térkép Miskolc középpontjára van állítva (`20.729, 48.097`).
- Az OSM csempéket használja a térkép alapjául.
- A helyadatok valós idejű frissítése Supabase Realtime segítségével történik.
