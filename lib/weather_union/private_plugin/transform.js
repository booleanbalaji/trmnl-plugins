// Flatten Weather Union response + derive display fields for Liquid templates.
// Input shape: { status, message, device_type, locality_weather_data: {...} }
function transform(input) {
  if (!input || typeof input !== 'object') return input;

  const wx = input.locality_weather_data || {};
  const rainIntensity = wx.rain_intensity == null ? null : Number(wx.rain_intensity);
  const humidity = wx.humidity == null ? null : Number(wx.humidity);
  const windMs = wx.wind_speed == null ? null : Number(wx.wind_speed);
  const windDir = wx.wind_direction == null ? null : Number(wx.wind_direction);
  const tempC = wx.temperature == null ? null : Number(wx.temperature);
  const rainToday = wx.rain_accumulation == null ? null : Number(wx.rain_accumulation);

  let conditions = 'Clear';
  if (rainIntensity != null && rainIntensity > 0) {
    if (rainIntensity >= 2.5) conditions = 'Heavy rain';
    else if (rainIntensity >= 0.5) conditions = 'Moderate rain';
    else conditions = 'Light rain';
  } else if (humidity != null && humidity >= 80) {
    conditions = 'Humid';
  } else if (humidity != null && humidity > 0 && humidity <= 30) {
    conditions = 'Dry';
  } else if (windMs != null && windMs * 3.6 >= 20) {
    conditions = 'Windy';
  }

  const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  let windCardinal = null;
  if (windDir != null && !Number.isNaN(windDir)) {
    windCardinal = directions[Math.round(((windDir % 360) + 360) % 360 / 22.5) % 16];
  }

  const deviceType = input.device_type == null ? null : Number(input.device_type);
  const apiMessage = (input.message || '').toString();
  const status = (input.status == null ? '' : String(input.status));
  const error =
    status === '200' && apiMessage && apiMessage.toLowerCase() !== 'successful response fetched'
      ? apiMessage
      : status && status !== '200'
        ? apiMessage || `Status ${status}`
        : null;

  return {
    status,
    error,
    device_type: deviceType,
    device_type_label: deviceType === 1 ? 'AWS station' : deviceType === 2 ? 'Rain gauge' : 'Station',
    temperature: tempC == null || Number.isNaN(tempC) ? null : Math.round(tempC * 10) / 10,
    humidity: humidity == null || Number.isNaN(humidity) ? null : Math.round(humidity),
    wind_speed_kmh: windMs == null || Number.isNaN(windMs) ? null : Math.round(windMs * 3.6 * 10) / 10,
    wind_direction: windDir == null || Number.isNaN(windDir) ? null : Math.round(windDir),
    wind_cardinal: windCardinal,
    rain_intensity: rainIntensity == null || Number.isNaN(rainIntensity) ? null : Math.round(rainIntensity * 100) / 100,
    rain_accumulation: rainToday == null || Number.isNaN(rainToday) ? null : Math.round(rainToday * 10) / 10,
    conditions,
    // Keep raw nest for debugging / fallbacks
    locality_weather_data: wx
  };
}
