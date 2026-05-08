require "rails_helper"

RSpec.describe "PWA" do
  describe "GET /manifest.json" do
    it "renders the web app manifest" do
      get pwa_manifest_path(format: :json)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("name")).to eq("Nutry.fit")
      expect(response.parsed_body.fetch("display")).to eq("standalone")
    end
  end

  describe "GET /service-worker" do
    it "renders the service worker script" do
      get pwa_service_worker_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("self.addEventListener")
    end
  end
end
