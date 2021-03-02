require 'sinatra'
require 'json'
require 'redis'
require 'i18n'
require 'pg'

class RuianAPI < Sinatra::Base
  def redis
    @redis ||= Redis.new(
               host: ENV.fetch('REDIS_HOST', 'localhost'),
               port: ENV.fetch('REDIS_PORT', 6379),
               db: ENV.fetch('REDIS_DB', 0),
               password: ENV.fetch('REDIS_PASS', nil)
             )
  end

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
            address as address
    FROM view_address_search WHERE address_search LIKE '#{query}' limit #{limit}").map(&:to_h)
  end

  def record_expire
    @record_expire ||= ENV.fetch('CACHE_TTL', 3600)
  end

  set :json_encoder, :to_json

  get '/places' do
    I18n.config.available_locales = :cs
    I18n.locale = :cs

    query = '%' + I18n.transliterate(params[:search]).to_s.downcase.gsub(/[^a-z0-9]/,' ').gsub(/\s+/, '%') + '%'
    limit = params[:limit].to_i || 30

    return places_search_query(query, limit).to_json
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
