class ForecastsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def index; end

  def create
    puts 'PARAMS: XXXXXXX'
    puts params

    @location = params['location']

    render 'show'
  end

  def show; end
end
