require 'net/http'

class ForecastsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  GMAPS_API_KEY = ENV['GMAPS_API_KEY']

  def index; end

  def create
    location_input = params['location']
    location = get_location(location_input)

    longitude = location['longitude']
    latitude = location['latitude']
    @location_name = location['location_name']
    postal_code = location['postal_code']

    thirty_minutes_ago = Time.now - 30.minutes

    existing_forecasts = Forecast.where('created_at >= :time AND postal_code == :found_code', time: thirty_minutes_ago, found_code: postal_code)
        
    if existing_forecasts.any?
      @cached_forecast = true
      @forecast = existing_forecasts.last
    else
      @cached_forecast = false
      @forecast = get_weather(longitude, latitude)
    end

    render 'show'
  end

  def show; end

  def get_location(location_input)
    # https://developers.google.com/maps/documentation/geocoding/get-api-key
    gmaps_formatted_address = location_input.gsub(' ', '+')
    gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{gmaps_formatted_address}&key=#{GMAPS_API_KEY}"

    response_body = make_json_api_request(gmaps_url)
    location = response_body['results'].first['geometry']['location']

    longitude = location['lng']
    latitude = location['lat']
    location_name = parse_location_name(response_body)

    postal_code_component = response_body['results'].first['address_components'].detect do |address_component|
      address_component['types'].include?('postal_code')
    end

    @postal_code = postal_code_component['long_name']

    location = {
      'longitude' => longitude,
      'latitude' => latitude,
      'location_name' => location_name,
      'postal_code' => @postal_code
    }

    location
  end

  def get_weather(longitude, latitude)
    # https://open-meteo.com/en/docs#api-documentation

    open_meteo_url = "https://api.open-meteo.com/v1/forecast?latitude=#{latitude}&longitude=#{longitude}&current_weather=true&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch"

    response_body = make_json_api_request(open_meteo_url)

    current_weather = response_body['current_weather']

    forecast = Forecast.create(
      postal_code: @postal_code,
      conditions: parse_weather_code(current_weather['weathercode']),
      temperature: current_weather['temperature'],
      wind_speed: current_weather['windspeed'],
      wind_direction: parse_wind_direction(current_weather['winddirection'])
    )

    forecast
  end

  def parse_wind_direction(direction_number)
    val = ((direction_number / 22.5) + 0.5)
    directions = %w[N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW]
    directions[(val % 16)]
  end

  def parse_weather_code(code)
    wmo_weather_codes = {
      0 => 'Clear sky',
      1 => 'Mainly clear',
      2 => 'Partly cloudy',
      3 => 'Overcast',
      45 => 'Fog',
      48 => 'Depositing rime fog',
      51 => 'Light drizzle',
      53 => 'Moderate drizzle',
      55 => 'Dense drizzle',
      56 => 'Light freezing drizzle',
      57 => 'Dense freezing drizzle',
      61 => 'Slight rain',
      63 => 'Moderate rain',
      65 => 'Heavy rain',
      66 => 'Light freezing rain',
      67 => 'Heavy freezing rain',
      71 => 'Slight snow',
      73 => 'Moderate snow',
      75 => 'Heavy snow',
      77 => 'Snow grains',
      80 => 'Slight rain showers',
      81 => 'Moderate rain showers',
      82 => 'Violent rain showers',
      85 => 'Slight snow showers',
      86 => 'Heavy snow showers',
      95 => 'Thunderstorm',
      96 => 'Thunderstorm with slight hail',
      99 => 'Thunderstorm with heavy hail'
    }

    wmo_weather_codes[code]
  end

  def parse_location_name(response_body)
    address_components = response_body['results'].first['address_components']

    locality_component = address_components.detect do |address_component|
      address_component['types'].include?('locality')
    end
    locality = locality_component['long_name']

    area_level_1_component = address_components.detect do |address_component|
      address_component['types'].include?('administrative_area_level_1')
    end
    area_level_1 = area_level_1_component['short_name']

    country_component = address_components.detect do |address_component|
      address_component['types'].include?('country')
    end
    country = country_component['short_name']

    [locality, area_level_1, country].join(', ')
  end

  def make_json_api_request(url)
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Content-Type'] = 'text/json'

    response = https.request(request)

    response_body = JSON.parse(response.body)

    response_body
  end
end
