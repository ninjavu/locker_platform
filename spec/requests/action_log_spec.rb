require "rails_helper"

RSpec.describe "Action log", type: :request do
  let(:amazon)       { create(:company, name: "Amazon") }
  let(:amazon_night) { create(:team, company: amazon, name: "Night Shift") }
  let(:amazon_day)   { create(:team, company: amazon, name: "Day Shift") }
  let(:dpd_north)    { create(:team, name: "North Crew") }

  let(:alice)   { create(:user, team: amazon_night, name: "Alice") }
  let(:support) { create(:user, :support, name: "Sam") }

  before do
    create(:locker_event, locker: create(:locker, team: amazon_night, name: "AMZ-N-01"))
    create(:locker_event, locker: create(:locker, team: amazon_day, name: "AMZ-D-01"))
    create(:locker_event, locker: create(:locker, team: dpd_north, name: "DPD-N-01"))
  end

  it "shows an employee only events of their team's lockers" do
    sign_in_as alice
    get action_log_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AMZ-N-01")
    expect(response.body).not_to include("AMZ-D-01") # other team, same company
    expect(response.body).not_to include("DPD-N-01") # other company
  end

  it "shows a support engineer events across all companies" do
    sign_in_as support
    get action_log_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("AMZ-N-01", "AMZ-D-01", "DPD-N-01")
  end
end
