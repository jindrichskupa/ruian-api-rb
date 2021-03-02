SET datestyle = "ISO, DMY";

CREATE EXTENSION IF NOT EXISTS "unaccent";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE OR REPLACE FUNCTION to_ascii (bytea, name)
  RETURNS text STRICT
  AS 'to_ascii_encname'
  LANGUAGE internal;

CREATE OR REPLACE FUNCTION lower (text)
  RETURNS text
  LANGUAGE internal
  IMMUTABLE STRICT
  AS $function$lower$function$;

CREATE OR REPLACE FUNCTION lower (anyrange)
  RETURNS anyelement
  LANGUAGE internal
  IMMUTABLE STRICT
  AS $function$range_lower$function$;

CREATE OR REPLACE FUNCTION to_search (text)
  RETURNS text
  LANGUAGE SQL
  IMMUTABLE STRICT
  AS $$
  SELECT
    regexp_replace(regexp_replace(regexp_replace(lower(to_ascii(convert_to($1, 'latin2'), 'latin2')), '-', ' '), '\.', ' ', 'g'), '\s+', ' ', 'g')
$$;

-- odstraneni tabulky pro adresni mista primo z CSV
DROP TABLE IF EXISTS import_address_places CASCADE;

-- vytvoreni tabulky pro adresni mista primo z CSV
CREATE TABLE import_address_places (
  place_id integer,
  city_id integer,
  city_name varchar(255),
  momc_id integer,
  momc_name varchar(255),
  mop_id integer,
  mop_name varchar(255),
  city_part_id integer,
  city_part_name varchar(255),
  street_id integer,
  street_name varchar(255),
  place_type varchar(30),
  house_number integer,
  street_number integer,
  street_number_char varchar(10),
  zip varchar(255),
  x real,
  y real,
  valid_from timestamp without time zone
);

-- nahrani dat z CSV
COPY import_address_places
FROM
  '/import/UI_ADRESNI_MISTA.csv' (DELIMITER ';', FORMAT CSV, NULL '', ENCODING 'WIN1250');

-- odstraneni view pro mesta
DROP MATERIALIZED VIEW IF EXISTS view_address_cities;

-- vytvoreni view pro mesta
CREATE MATERIALIZED VIEW view_address_cities AS
SELECT
  import_address_places.city_id AS id,
  import_address_places.city_name AS name,
  to_search (import_address_places.city_name) AS name_search
FROM
  import_address_places
GROUP BY
  city_id,
  city_name;

-- odstraneni view pro mestske casti
DROP MATERIALIZED VIEW IF EXISTS view_address_city_parts;

-- vytvoreni view pro mestske casti
CREATE MATERIALIZED VIEW view_address_city_parts AS
SELECT
  import_address_places.city_part_id AS id,
  import_address_places.city_part_name AS name,
  to_search (import_address_places.city_part_name) AS name_search,
  import_address_places.city_id
FROM
  import_address_places
GROUP BY
  import_address_places.city_part_id,
  import_address_places.city_part_name,
  import_address_places.city_id;

-- odstraneni view pro ulice
DROP MATERIALIZED VIEW IF EXISTS view_address_streets;

-- vytvoreni view pro ulice
CREATE MATERIALIZED VIEW view_address_streets AS
SELECT
  import_address_places.street_id AS id,
  import_address_places.street_name AS name,
  to_search (import_address_places.street_name) AS name_search,
  import_address_places.city_id,
  import_address_places.city_part_id,
  import_address_places.zip
FROM
  import_address_places
GROUP BY
  import_address_places.street_id,
  import_address_places.street_name,
  import_address_places.city_id,
  import_address_places.city_part_id,
  zip;

-- odstraneni view pro adresni mista
DROP MATERIALIZED VIEW IF EXISTS view_address_places;

-- vytvoreni view pro adresni mista
CREATE MATERIALIZED VIEW view_address_places AS
SELECT
  place_id AS id,
  street_id AS streets_id,
  CASE WHEN place_type = 'č.p.' THEN
    NULL
  ELSE
    house_number
  END AS e,
  CASE WHEN place_type = 'č.p.' THEN
    house_number
  ELSE
    NULL
  END AS p,
  CASE WHEN street_number_char IS NULL THEN
    street_number::varchar
  ELSE
    street_number::varchar || street_number_char
  END AS o,
  import_address_places.city_id AS cities_id,
  import_address_places.city_part_id AS city_parts_id,
  import_address_places.zip
FROM
  import_address_places
  LEFT JOIN view_address_streets ON view_address_streets.id = import_address_places.street_id;

DROP MATERIALIZED VIEW view_address_search;

CREATE MATERIALIZED VIEW view_address_search AS
SELECT
  view_address_places.id,
  view_address_places.p::varchar as p,
  view_address_places.o as o,
  view_address_places.e::varchar as e,
  view_address_places.streets_id as street_id,
  view_address_streets.name as street_name,
  view_address_places.city_parts_id as city_part_id,
  view_address_city_parts.name as city_part_name,
  view_address_places.cities_id as city_id,
  view_address_cities.name as city_name,
  view_address_places.zip as zip,
  CASE
    WHEN view_address_streets.name is NULL THEN
      view_address_city_parts.name
    ELSE
      view_address_streets.name
  END || ' ' ||
  CASE
    WHEN view_address_places.e::varchar IS NULL THEN
      CASE
        WHEN view_address_places.o is NULL THEN
          view_address_places.p::varchar
        ELSE
          view_address_places.p::varchar || '/' || view_address_places.o
        END
    ELSE
      view_address_places.e::varchar
  END || ', ' ||
  CASE
    WHEN view_address_cities.name = view_address_city_parts.name THEN
      ''
    ELSE
      view_address_city_parts.name || ', '
  END ||
  view_address_cities.name || ', ' ||
  view_address_places.zip as address,
  to_search (
    CASE
      WHEN view_address_streets.name is NULL THEN
        view_address_city_parts.name
      ELSE
        view_address_streets.name
    END || ' ' ||
    CASE
      WHEN view_address_places.e::varchar IS NULL THEN
        CASE
          WHEN view_address_places.o is NULL THEN
            view_address_places.p::varchar
          ELSE
            view_address_places.p::varchar || '/' || view_address_places.o
          END
      ELSE
        view_address_places.e::varchar
    END || ' ' ||
    CASE
      WHEN view_address_cities.name = view_address_city_parts.name THEN
        ''
      ELSE
        view_address_city_parts.name || ' '
    END ||
    view_address_cities.name || ' ' ||
    view_address_places.zip
  ) as address_search
from view_address_places
  left join view_address_streets on view_address_places.streets_id = view_address_streets.id
  left join view_address_cities on view_address_places.cities_id = view_address_cities.id
  left join view_address_city_parts on view_address_places.city_parts_id = view_address_city_parts.id;

DROP INDEX IF EXISTS index_address_cities_on_id;

CREATE INDEX index_address_cities_on_id ON view_address_cities USING btree (id);

DROP INDEX IF EXISTS index_address_city_parts_on_id;

CREATE INDEX index_address_city_parts_on_id ON view_address_city_parts USING btree (id);

DROP INDEX IF EXISTS index_address_streets_on_id;

CREATE INDEX index_address_streets_on_id ON view_address_streets USING btree (id);

DROP INDEX IF EXISTS index_address_places_on_id;

CREATE INDEX index_address_places_on_id ON view_address_places USING btree (id);

DROP INDEX IF EXISTS index_address_places_on_streets_id;

CREATE INDEX index_address_places_on_streets_id ON view_address_places USING btree (streets_id);

DROP INDEX IF EXISTS index_address_places_on_city_part_id;

CREATE INDEX index_address_places_on_city_part_id ON view_address_places USING btree (city_parts_id);

DROP INDEX IF EXISTS index_address_places_on_city_id;

CREATE INDEX index_address_places_on_city_id ON view_address_places USING btree (cities_id);

DROP INDEX IF EXISTS index_address_places_on_lat_lng;

CREATE INDEX index_address_places_on_lat_lng ON view_address_places USING gist (ll_to_earth (latitude, longitude));

DROP INDEX IF EXISTS index_address_places_on_point;

CREATE INDEX index_address_places_on_point ON view_address_places USING gist (point(latitude, longitude));

DROP INDEX IF EXISTS index_address_cities_on_name_search;

CREATE INDEX index_address_cities_on_name_search ON view_address_cities USING gin (name_search gin_trgm_ops);

DROP INDEX IF EXISTS index_address_city_parts_on_name_search;

CREATE INDEX index_address_city_parts_on_name_search ON view_address_city_parts USING gin (name_search gin_trgm_ops);

DROP INDEX IF EXISTS index_address_street_names_on_name_search;

CREATE INDEX index_address_street_names_on_name_search ON view_address_streets USING gin (name_search gin_trgm_ops);

DROP INDEX IF EXISTS index_view_address_search_address_search;

CREATE INDEX index_view_address_search_address_search ON view_address_search USING gin (address_search gin_trgm_ops);

SET datestyle = "ISO, MDY";