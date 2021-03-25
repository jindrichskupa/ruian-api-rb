require 'sinatra'
require 'json'
require 'i18n'
require 'pg'

class RuianAPI < Sinatra::Base

  def postgres
    @postgres ||= PG.connect(
               host: ENV.fetch('POSTGRES_HOST', 'postgres'),
               port: ENV.fetch('POSTGRES_PORT', 5432),
               dbname: ENV.fetch('POSTGRES_DB', 'ruian'),
               user: ENV.fetch('POSTGRES_USER', 'postgres'),
               password: ENV.fetch('POSTGRES_PASS', 'password')
             )
  end

  def places_search_query(query, limit=10)
    result = postgres.exec( "SELECT
            id,
            street_name as street,
            p as p,
            o as o,
            e as e,
            city_part_name as city_part,
            city_name as city,
            zip as zip,
            lat as lat,
            long as long,
            address as address
    FROM view_address_search WHERE address_search LIKE '#{query}' LIMIT #{limit}").map(&:to_h)
  end

  def place_by_coordinates(lat, long, limit=10, range=50)
    result = postgres.exec( "SELECT
            id,
            street_name as street,
            p as p,
            o as o,
            e as e,
            city_part_name as city_part,
            city_name as city,
            zip as zip,
            lat as lat,
            long as long,
            address as address,
            earth_distance( ll_to_earth(lat, long), ll_to_earth(#{lat}, #{long})) as distance
      FROM view_address_search
      WHERE earth_box(ll_to_earth(#{lat}, #{long}), #{range}) @> ll_to_earth(lat, long)
      ORDER BY 12 LIMIT #{limit}").map(&:to_h)
  end

  def record_expire
    @record_expire ||= ENV.fetch('CACHE_TTL', 3600)
  end

  before do
    content_type 'application/json'
  end

  set :json_encoder, :to_json

  get '/places' do
    I18n.config.available_locales = :cs
    I18n.locale = :cs

    query = '%' + I18n.transliterate(params[:search]).to_s.downcase.gsub(/[^a-z0-9]/,' ').gsub(/\s+/, '%') + '%'
    limit = params[:limit].to_i || 10
    result = places_search_query(query, limit)
    status (result.empty? ? 404 : 200)
    result.to_json
  end

  get '/location' do
    lat = params[:lat]
    long = params[:long]
    limit = params[:limit].to_i || 10
    range = params[:range].to_i || 50

    result place_by_coordinates(lat, long, limit, range)
    status (result.empty? ? 404 : 200)
    result.to_json
  end

  get '/openapi.yml' do
    File.read("openapi.yml")
  end

  get '/' do
    File.read("index.html")
  end

  get '/healtz' do
    status 200
    { status: "OK", message: "I'm alive" }.to_json
  end

end
