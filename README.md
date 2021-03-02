# RUIAN API server

API to search RUIAN via REST/JSON API

## Technology

* redis
* postgres + postgis
* sinatra
* puma

## Configuration

The only configuration is REDIS and PostgreSQL access:

* `REDIS_HOST`: redis
* `REDIS_PORT`: 6379
* `REDIS_DB`: 0
* `CACHE_TTL`: 3600
* `POSTGRES_HOST`: postgres
* `POSTGRES_PORT`: 5432
* `POSTGRES_DB`: ruian
* `POSTGRES_USER`: postgres
* `POSTGRES_PASS`: password

## Usage

Start puma server on server and call via HTTP, method is allways GET:

* URL: `http[s]://<server>/places?search=<address string>`
* URL example: `https://ruian2.eman.dev/places?search=sko%20zruc`

### Run via docker-compose

```bash
docker-compose build && docker-compose up -d
```

## Import

1. Download Import CSV <https://vdp.cuzk.cz/vymenny_format/csv/20140630_OB_ADR_csv.zip> (change the date)
2. Join import files using `import/prepare_places.sh`
3. Run `sql/import.sql`
4. Enjoy

## Update

1. Download Import CSV <https://vdp.cuzk.cz/vymenny_format/csv/20140630_OB_ADR_csv.zip> (change the date)
2. Join import files using `import/prepare_places.sh`
3. Run `sql/update.sql`

