class CreateForecasts < ActiveRecord::Migration[7.0]
  def change
    create_table :forecasts do |t|
      t.string :conditions
      t.string :high
      t.string :low

      t.timestamps
    end
  end
end
