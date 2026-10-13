require "rails_helper"

RSpec.describe "User switching", type: :request do
  let!(:alice) { create(:user, name: "Alice") }
  let!(:daria) { create(:user, name: "Daria") }

  let!(:alices_locker) { create(:locker, team: alice.team, name: "AMZ-N-01") }
  let!(:darias_locker) { create(:locker, team: daria.team, name: "DPD-N-01") }

  it "defaults to an employee when nobody is picked yet" do
    get lockers_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Lockers of")
  end

  it "404s when switching to an unknown user" do
    patch session_path, params: { user_id: 999_999 }

    expect(response).to have_http_status(:not_found)
  end

  it "falls back to the default employee when the session user was deleted" do
    sign_in_as daria
    daria.destroy!

    get lockers_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Lockers of") # acting as an employee again
  end

  it "changes what the list shows" do
    sign_in_as alice
    get lockers_path
    expect(response.body).not_to include("DPD-N-01")

    sign_in_as daria
    get lockers_path
    expect(response.body).to include("DPD-N-01")
    expect(response.body).not_to include("AMZ-N-01")
  end
end
