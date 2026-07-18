module Plugins
  class WeatherUnion < Base
    BASE_URL = 'https://www.weatherunion.com/gw/weather/external/v0'.freeze
    LOCALITIES_PATH = File.expand_path('data/localities.json', __dir__).freeze

    def locals
      {
        temperature:,
        humidity:,
        wind_speed:,
        wind_direction:,
        wind_cardinal:,
        rain_intensity:,
        rain_accumulation:,
        conditions:,
        weather_image:,
        location_label:,
        city_name:,
        locality_name:,
        device_type_label:,
        device_type:,
        units:,
        error:,
        refreshed_at:
      }
    end

    private

    def weather_data
      @weather_data ||= fetch_weather
    end

    def fetch_weather
      return error_payload('API key is required. Get one free at weatherunion.com') if api_key.blank?
      return error_payload('Provide latitude/longitude or a locality ID') if latitude.blank? && longitude.blank? && locality_id.blank?

      response = if locality_id.present?
                   HTTParty.get(
                     "#{BASE_URL}/get_locality_weather_data",
                     query: { locality_id: locality_id },
                     headers: headers
                   )
                 else
                   HTTParty.get(
                     "#{BASE_URL}/get_weather_data",
                     query: { latitude: latitude, longitude: longitude },
                     headers: headers
                   )
                 end

      body = parse_body(response)
      status = body['status'].to_s
      message = body['message'].to_s

      if response.code == 403 || status == '403'
        return error_payload('Could not authenticate. Check your Weather Union API key.')
      end

      if response.code == 429 || status == '429'
        return error_payload('Daily API quota exhausted for this key.')
      end

      if status == '200' && message.present? && !message.casecmp('successful response fetched').zero?
        return error_payload(humanize_api_message(message))
      end

      unless response.success? && status == '200'
        return error_payload(humanize_api_message(message.presence || "HTTP #{response.code}"))
      end

      {
        error: nil,
        device_type: body['device_type'],
        locality_weather_data: body['locality_weather_data'] || {}
      }
    rescue StandardError => e
      error_payload("Unable to fetch weather: #{e.message}")
    end

    def parse_body(response)
      return {} if response.body.blank?

      JSON.parse(response.body)
    rescue JSON::ParserError
      {}
    end

    def error_payload(message)
      { error: message, device_type: nil, locality_weather_data: {} }
    end

    def humanize_api_message(message)
      case message.downcase
      when /not supported/
        'Location not supported. Weather Union covers select Indian cities within ~2 km of a station.'
      when /temporarily unavailable/
        'Weather data temporarily unavailable for this location.'
      when /coordinates are invalid/
        'Invalid coordinates. Latitude must be -90 to 90, longitude -180 to 180.'
      when /check the locality id/
        'Invalid locality ID. Use a ZWLxxxxxx value from the Weather Union locality list.'
      else
        message
      end
    end

    def headers
      {
        'content-type' => 'application/json',
        'x-zomato-api-key' => api_key
      }
    end

    def locality_weather
      weather_data[:locality_weather_data] || {}
    end

    def error = weather_data[:error]

    def device_type = weather_data[:device_type]

    def temperature
      return nil if locality_weather['temperature'].nil?

      convert_temperature(locality_weather['temperature'].to_f)
    end

    def humidity
      return nil if locality_weather['humidity'].nil?

      locality_weather['humidity'].to_f.round
    end

    def wind_speed
      return nil if locality_weather['wind_speed'].nil?

      convert_wind_speed(locality_weather['wind_speed'].to_f)
    end

    def wind_direction
      return nil if locality_weather['wind_direction'].nil?

      locality_weather['wind_direction'].to_f.round
    end

    def wind_cardinal
      return nil if wind_direction.nil?

      directions = %w[N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW]
      index = ((wind_direction % 360) / 22.5).round % 16
      directions[index]
    end

    def rain_intensity
      return nil if locality_weather['rain_intensity'].nil?

      locality_weather['rain_intensity'].to_f.round(2)
    end

    def rain_accumulation
      return nil if locality_weather['rain_accumulation'].nil?

      locality_weather['rain_accumulation'].to_f.round(1)
    end

    def conditions
      return 'Unavailable' if error.present?
      return 'Rain gauge' if device_type.to_i == 2 && temperature.nil?

      if rain_intensity.to_f.positive?
        intensity = rain_intensity.to_f
        return 'Heavy rain' if intensity >= 2.5
        return 'Moderate rain' if intensity >= 0.5

        return 'Light rain'
      end

      return 'Humid' if humidity.to_i >= 80
      return 'Dry' if humidity.to_i.positive? && humidity.to_i <= 30
      return 'Windy' if wind_speed.to_f >= wind_threshold_for_windy

      'Clear'
    end

    def weather_image
      case conditions
      when 'Heavy rain', 'Moderate rain' then 'wi-rain'
      when 'Light rain' then 'wi-showers'
      when 'Windy' then 'wi-strong-wind'
      when 'Humid' then 'wi-humidity'
      when 'Dry' then 'wi-day-sunny'
      when 'Rain gauge' then 'wi-raindrops'
      else 'wi-day-cloudy'
      end
    end

    def nearest_locality
      @nearest_locality ||= begin
        if locality_id.present?
          localities.find { |l| l['locality_id'] == locality_id }
        elsif latitude.present? && longitude.present?
          find_nearest_locality(latitude.to_f, longitude.to_f)
        end
      end
    end

    def find_nearest_locality(lat, lon)
      localities.min_by do |locality|
        haversine_km(lat, lon, locality['latitude'].to_f, locality['longitude'].to_f)
      end
    end

    def haversine_km(lat1, lon1, lat2, lon2)
      radius = 6371.0
      dlat = to_rad(lat2 - lat1)
      dlon = to_rad(lon2 - lon1)
      a = Math.sin(dlat / 2)**2 +
          Math.cos(to_rad(lat1)) * Math.cos(to_rad(lat2)) * Math.sin(dlon / 2)**2
      2 * radius * Math.asin(Math.sqrt(a))
    end

    def to_rad(degrees) = degrees * Math::PI / 180.0

    def localities
      @localities ||= JSON.parse(File.read(LOCALITIES_PATH))
    end

    def location_label
      return settings['location_label'] if settings['location_label'].present?
      return "#{locality_name}, #{city_name}" if locality_name.present? && city_name.present?
      return locality_name if locality_name.present?
      return "#{latitude}, #{longitude}" if latitude.present? && longitude.present?

      locality_id.presence || 'Weather Union'
    end

    def city_name = nearest_locality&.dig('city')

    def locality_name = nearest_locality&.dig('locality')

    def device_type_label
      case device_type.to_i
      when 1 then 'AWS station'
      when 2 then 'Rain gauge'
      else 'Station'
      end
    end

    def convert_temperature(celsius)
      return celsius.round(1) if metric?

      ((celsius * 9.0 / 5.0) + 32).round
    end

    def convert_wind_speed(meters_per_second)
      if metric?
        (meters_per_second * 3.6).round(1) # km/h
      else
        (meters_per_second * 2.23694).round(1) # mph
      end
    end

    def wind_threshold_for_windy
      metric? ? 20.0 : 12.0
    end

    def units
      {
        temperature: metric? ? 'C' : 'F',
        wind: metric? ? 'km/h' : 'mph',
        rain: 'mm'
      }
    end

    def metric?
      units_setting != 'imperial'
    end

    def units_setting
      (settings['units'].presence || 'metric').downcase
    end

    def api_key = settings['api_key'].to_s.strip

    def locality_id = settings['locality_id'].to_s.strip.presence

    def latitude
      @latitude ||= parsed_coordinates[:latitude] || settings['latitude'].presence
    end

    def longitude
      @longitude ||= parsed_coordinates[:longitude] || settings['longitude'].presence
    end

    def parsed_coordinates
      @parsed_coordinates ||= begin
        raw = settings['lat_lon'].to_s.strip
        return { latitude: nil, longitude: nil } if raw.blank?

        parts = if raw.include?(',')
                  raw.split(',')
                elsif raw.include?('/')
                  raw.split('/')
                else
                  raw.split
                end.map(&:strip)

        { latitude: parts[0], longitude: parts[1] }
      end
    end

    def refreshed_at
      return nil unless plugin_setting.respond_to?(:previous_refresh_at) && plugin_setting.previous_refresh_at.present?

      I18n.l(plugin_setting.previous_refresh_at.in_time_zone(user.tz), format: :short, locale: user.locale).split[-1]
    rescue StandardError
      nil
    end
  end
end
