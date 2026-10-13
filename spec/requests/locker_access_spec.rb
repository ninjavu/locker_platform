require "rails_helper"

# The core requirement of the assignment: data separation between companies
# and teams must really work, for reads and for open/close actions alike.
RSpec.describe "Locker access", type: :request do
  let(:amazon)       { create(:company, name: "Amazon") }
  let(:amazon_night) { create(:team, company: amazon, name: "Night Shift") }
  let(:amazon_day)   { create(:team, company: amazon, name: "Day Shift") }
  let(:dpd_north)    { create(:team, name: "North Crew") } # another company

  let(:alice)   { create(:user, team: amazon_night, name: "Alice") }
  let(:support) { create(:user, :support, name: "Sam") }

  let!(:own_locker)      { create(:locker, team: amazon_night, name: "AMZ-N-01") }
  let!(:same_co_locker)  { create(:locker, team: amazon_day, name: "AMZ-D-01") }
  let!(:other_co_locker) { create(:locker, :open, team: dpd_north, name: "DPD-N-01") }

  describe "as an employee" do
    before { sign_in_as alice }

    it "lists only the lockers of their team" do
      get lockers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AMZ-N-01")
      expect(response.body).not_to include("AMZ-D-01") # other team, same company
      expect(response.body).not_to include("DPD-N-01") # other company
    end

    it "shows their team's locker page with its history" do
      get locker_path(own_locker)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Action history")
    end

    it "404s on a locker of another team in the same company" do
      get locker_path(same_co_locker)

      expect(response).to have_http_status(:not_found)
    end

    it "404s on a locker of another company" do
      get locker_path(other_co_locker)

      expect(response).to have_http_status(:not_found)
    end

    it "opens and closes their team's locker, logging both actions" do
      expect {
        post open_locker_path(own_locker)
        expect(response).to have_http_status(:redirect)
        expect(own_locker.reload).to be_open

        post close_locker_path(own_locker)
        expect(response).to have_http_status(:redirect)
        expect(own_locker.reload).to be_closed
      }.to change { own_locker.locker_events.count }.by(2)

      expect(own_locker.locker_events.recent_first.limit(2).pluck(:action)).to eq(%w[close open])
      expect(own_locker.locker_events.recent_first.first.user).to eq(alice)
    end

    it "cannot operate a locker of another team or company" do
      [ same_co_locker, other_co_locker ].each do |locker|
        [ open_locker_path(locker), close_locker_path(locker) ].each do |path|
          state_before = locker.state

          expect { post path }.not_to change(LockerEvent, :count)

          expect(response).to have_http_status(:not_found)
          expect(locker.reload.state).to eq(state_before)
        end
      end
    end
  end

  describe "opening an already open locker" do
    let(:daria) { create(:user, team: dpd_north, name: "Daria") }

    before { sign_in_as daria }

    it "redirects with an alert and logs nothing" do
      expect { post open_locker_path(other_co_locker) }.not_to change(LockerEvent, :count)

      expect(response).to redirect_to(locker_path(other_co_locker))
      expect(other_co_locker.reload).to be_open
      follow_redirect!
      expect(response.body).to include("already open")
    end
  end

  describe "as a support engineer" do
    before { sign_in_as support }

    it "sees every locker on the platform" do
      get lockers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AMZ-N-01", "AMZ-D-01", "DPD-N-01")
    end

    it "can operate any locker" do
      post open_locker_path(same_co_locker)

      expect(response).to have_http_status(:redirect)
      expect(same_co_locker.reload).to be_open
      expect(same_co_locker.locker_events.recent_first.first.user).to eq(support)
    end
  end
end
