SET datestyle = "ISO, DMY";

TRUNCATE TABLE import_address_places;
COPY import_address_places FROM
  '/import/UI_ADRESNI_MISTA.csv' (DELIMITER ';', FORMAT CSV, NULL '', ENCODING 'WIN1250');

DROP INDEX IF EXISTS index_address_cities_on_id;
DROP INDEX IF EXISTS index_address_city_parts_on_id;
DROP INDEX IF EXISTS index_address_streets_on_id;
DROP INDEX IF EXISTS index_address_places_on_id;
DROP INDEX IF EXISTS index_address_places_on_streets_id;
DROP INDEX IF EXISTS index_address_places_on_city_part_id;
DROP INDEX IF EXISTS index_address_places_on_city_id;
DROP INDEX IF EXISTS index_address_places_on_lat_lng;
DROP INDEX IF EXISTS index_address_places_on_point;
DROP INDEX IF EXISTS index_address_cities_on_name_search;
DROP INDEX IF EXISTS index_address_city_parts_on_name_search;
DROP INDEX IF EXISTS index_address_street_names_on_name_search;
DROP INDEX IF EXISTS index_view_address_search_address_search;


REFRESH MATERIALIZED VIEW view_address_cities;
REFRESH MATERIALIZED VIEW view_address_city_parts;
REFRESH MATERIALIZED VIEW view_address_streets;
REFRESH MATERIALIZED VIEW view_address_places;
REFRESH MATERIALIZED VIEW view_address_search;


CREATE INDEX index_address_cities_on_id ON view_address_cities USING btree (id);
CREATE INDEX index_address_city_parts_on_id ON view_address_city_parts USING btree (id);
CREATE INDEX index_address_streets_on_id ON view_address_streets USING btree (id);
CREATE INDEX index_address_places_on_id ON view_address_places USING btree (id);
CREATE INDEX index_address_places_on_streets_id ON view_address_places USING btree (streets_id);
CREATE INDEX index_address_places_on_city_part_id ON view_address_places USING btree (city_parts_id);
CREATE INDEX index_address_places_on_city_id ON view_address_places USING btree (cities_id);
CREATE INDEX index_address_places_on_lat_lng ON view_address_places USING gist (ll_to_earth (latitude, longitude));
CREATE INDEX index_address_places_on_point ON view_address_places USING gist (point(latitude, longitude));
CREATE INDEX index_address_cities_on_name_search ON view_address_cities USING gin (name_search gin_trgm_ops);
CREATE INDEX index_address_city_parts_on_name_search ON view_address_city_parts USING gin (name_search gin_trgm_ops);
CREATE INDEX index_address_street_names_on_name_search ON view_address_streets USING gin (name_search gin_trgm_ops);
CREATE INDEX index_view_address_search_address_search ON view_address_search USING gin (address_search gin_trgm_ops);

SET datestyle = "ISO, MDY";