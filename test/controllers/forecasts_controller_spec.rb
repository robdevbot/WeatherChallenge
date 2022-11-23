describe ForecastsController, type: :controller do
  let(:forecast) { Forecast.create }

  describe 'index' do
    it 'returns a 200' do
      get 'index', params: nil
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'show' do
    it 'returns a 200' do
      get '/forecast', params: { id: forecast.id }
      expect(response).to have_http_status(:ok)
    end
  end
end
