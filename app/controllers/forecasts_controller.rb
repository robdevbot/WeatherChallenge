require 'net/http'

class ForecastsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  # GMAPS_API_KEY = ENV['GMAPS_API_KEY']
  GMAPS_API_KEY = 'AIzaSyByaGdeBI225Qtx1E_0KA4AF_lm6wefpH0'
  
  def index; end

  def create
    @location = params['location']

    @weather = get_weather(@location)

    render 'show'
  end

  def show; end
  
  def get_weather(location)
    # https://open-meteo.com/en/docs#api-documentation
    longitude, latitude, @location_name = get_coordinates(location)

    open_meteo_url = "https://api.open-meteo.com/v1/forecast?latitude=#{latitude}&longitude=#{longitude}&current_weather=true&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch"
    
    response_body = make_json_api_request(open_meteo_url)

    return response_body    
  end

  def get_coordinates(location)
    # https://developers.google.com/maps/documentation/geocoding/get-api-key
    gmaps_formatted_address = location.gsub(' ', '+')
    gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{gmaps_formatted_address}&key=#{GMAPS_API_KEY}"

    response_body = make_json_api_request(gmaps_url)

    location = response_body["results"].first["geometry"]["location"]
    location_name = parse_location_name(response_body)

    longitude = location["lng"]
    latitude = location["lat"]

    puts "lat: #{latitude}, lng: #{longitude}, location_name: #{location_name}"
    
    return longitude, latitude, location_name
  end

  # def get_location_type(location)
  #   if location.match(/^\d{5}/)
  #     return "zip_code"
  #   end
  # end

  def parse_location_name(response_body)
    address_components = response_body["results"].first["address_components"]

    locality_component = address_components.detect do |address_component|
      address_component["types"].include?("locality")
    end
    locality = locality_component["long_name"]
    
    area_level_1_component = address_components.detect do |address_component|
      address_component["types"].include?("administrative_area_level_1")
    end
    area_level_1 = area_level_1_component["short_name"]

    country_component = address_components.detect do |address_component|
      address_component["types"].include?("country")
    end
    country = country_component["short_name"]

    return [locality, area_level_1, country].join(", ")
  end

  def make_json_api_request(url)
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request["Content-Type"] = "text/json"
    
    response = https.request(request)

    response_body = JSON.parse(response.body)

    return response_body
  end
end
