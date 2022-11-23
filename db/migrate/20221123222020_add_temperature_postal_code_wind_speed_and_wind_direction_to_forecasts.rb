class AddTemperaturePostalCodeWindSpeedAndWindDirectionToForecasts < ActiveRecord::Migration[7.0]
  def change
    add_column :forecasts, :temperature, :string
    add_column :forecasts, :postal_code, :string
    add_column :forecasts, :wind_speed, :string
    add_column :forecasts, :wind_direction, :string
  end
end
