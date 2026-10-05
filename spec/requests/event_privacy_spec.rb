# frozen_string_literal: true

RSpec.describe "Event privacy" do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:organiser, :user)
  fab!(:other_organiser, :user)
  fab!(:inactive_organiser, :user)
  fab!(:racer) do
    Fabricate(:user, name: "Racer Fullname").tap do |user|
      user.custom_fields["brca_membership_number"] = "BRCA-12345"
      user.save_custom_fields
    end
  end

  fab!(:admin_position) { DesPosition.create!(name: "Spec chair", is_admin: true) }
  fab!(:organisation) do
    DesOrganisation.create!(
      name: "Spec RC Club",
      status: "approved",
      created_by: organiser.id,
      paypal_email: "treasurer@example.com",
    )
  end
  fab!(:other_organisation) do
    DesOrganisation.create!(
      name: "Other RC Club",
      status: "approved",
      created_by: other_organiser.id,
    )
  end
  fab!(:memberships) do
    [
      [organisation, organiser, "active"],
      [organisation, inactive_organiser, "inactive"],
      [other_organisation, other_organiser, "active"],
    ].map do |org, user, status|
      DesOrganisationMember.create!(
        organisation: org,
        user: user,
        position: admin_position,
        status: status,
      )
    end
  end
  fab!(:event_type) { DesEventType.create!(name: "Spec meeting") }

  fab!(:event) do
    DesEvent.create!(
      title: "Spec round",
      organisation: organisation,
      event_type: event_type,
      created_by: organiser.id,
      start_date: 10.days.from_now,
      status: "published",
    )
  end
  fab!(:draft_event) do
    DesEvent.create!(
      title: "Secret draft",
      organisation: organisation,
      event_type: event_type,
      created_by: organiser.id,
      start_date: 20.days.from_now,
      status: "draft",
    )
  end
  fab!(:event_class) do
    DesEventClass.create!(event: event, name: "Buggy", capacity: 10, status: "active")
  end
  fab!(:booking) do
    DesEventBooking
      .create!(event: event, user: racer, status: "confirmed")
      .tap do |booking|
        DesEventBookingClass.create!(
          booking: booking,
          event_class: event_class,
          status: "confirmed",
          transponder_number: "1234567",
        )
      end
  end
  fab!(:waitlisted) do
    Fabricate(:user, name: "Waiting Fullname").tap do |user|
      DesEventWaitlist.create!(
        event: event,
        event_class: event_class,
        user: user,
        position: 1,
        status: "waiting",
      )
    end
  end

  def personal_fields
    %w[name transponder brca_number]
  end

  def entrants
    response.parsed_body["classes"].flat_map { |cls| cls["entrants"] }
  end

  def get_as(user, path)
    sign_in(user) if user
    get path
  end

  describe "GET /des/events/:id" do
    it "returns 404 for drafts to anonymous users, members and inactive or other organisers" do
      [nil, member, inactive_organiser, other_organiser].each do |user|
        get_as(user, "/des/events/#{draft_event.id}.json")
        expect(response.status).to eq(404), "expected 404 for #{user&.username || "anon"}"
      end
    end

    it "returns drafts to the event's organisers and site admins" do
      [organiser, admin].each do |user|
        get_as(user, "/des/events/#{draft_event.id}.json")
        expect(response.status).to eq(200)
        expect(response.parsed_body["is_admin"]).to eq(true)
      end
    end

    it "returns published events to everyone" do
      get "/des/events/#{event.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["is_admin"]).to eq(false)
    end
  end

  describe "GET /des/events/by-topic/:topic_id" do
    it "returns 404 for a draft's topic to non-organisers" do
      draft_event.update_columns(topic_id: Fabricate(:topic).id)

      get_as(member, "/des/events/by-topic/#{draft_event.topic_id}.json")
      expect(response.status).to eq(404)

      get_as(organiser, "/des/events/by-topic/#{draft_event.topic_id}.json")
      expect(response.status).to eq(200)
    end
  end

  describe "GET /des/events/:id/public-entrants" do
    it "returns 404 for drafts to non-organisers" do
      get_as(member, "/des/events/#{draft_event.id}/public-entrants.json")
      expect(response.status).to eq(404)
    end

    it "is forbidden to anonymous users before race day" do
      get "/des/events/#{event.id}/public-entrants.json"
      expect(response.status).to eq(403)
    end

    it "shows anonymous users the list on race day without personal details" do
      freeze_time(event.start_date.change(hour: 12)) do
        get "/des/events/#{event.id}/public-entrants.json"
      end

      expect(response.status).to eq(200)
      expect(entrants.map { |e| e["username"] }).to contain_exactly(
        racer.username,
        waitlisted.username,
      )
      expect(entrants.flat_map(&:keys)).not_to include(*personal_fields)
    end

    it "strips personal details for members and inactive organisers" do
      [member, inactive_organiser, other_organiser].each do |user|
        get_as(user, "/des/events/#{event.id}/public-entrants.json")

        expect(response.status).to eq(200)
        expect(entrants.flat_map(&:keys)).not_to include(*personal_fields)
        expect(response.body).not_to include(racer.name, "1234567", "BRCA-12345", waitlisted.name)
      end
    end

    it "includes personal details for the event's organisers and site admins" do
      [organiser, admin].each do |user|
        get_as(user, "/des/events/#{event.id}/public-entrants.json")

        racer_entry = entrants.find { |e| e["username"] == racer.username }
        expect(racer_entry).to include(
          "name" => racer.name,
          "transponder" => "1234567",
          "brca_number" => "BRCA-12345",
        )
        expect(entrants.find { |e| e["username"] == waitlisted.username }["name"]).to eq(
          waitlisted.name,
        )
      end
    end
  end

  describe "GET /des/events/:id/results" do
    fab!(:result) do
      DesEventResult
        .create!(event: event, status: "pending_match")
        .tap do |result|
          race = DesEventResultRace.create!(event_result: result, race_name: "A Final")
          DesEventResultEntry.create!(
            race: race,
            position: 1,
            driver_name: "R Fullname",
            user: racer,
          )
        end
    end

    it "only tells members that unpublished results are being processed" do
      get_as(member, "/des/events/#{event.id}/results.json")
      expect(response.parsed_body).to eq("status" => "pending_match")
    end

    it "gives organisers unpublished results" do
      get_as(organiser, "/des/events/#{event.id}/results.json")
      expect(response.parsed_body["races"].size).to eq(1)
    end

    it "shows members published results without matched users' full names" do
      result.update!(status: "published")

      get_as(member, "/des/events/#{event.id}/results.json")
      entry_user = response.parsed_body["races"].first["entries"].first["user"]
      expect(entry_user["username"]).to eq(racer.username)
      expect(entry_user["name"]).to be_nil
    end
  end

  describe "GET /des/garage/:username/public" do
    fab!(:manufacturer) { DesManufacturer.create!(name: "Spec Motors", status: "approved") }
    fab!(:car_model) do
      DesCarModel.create!(manufacturer: manufacturer, name: "SR1", status: "approved")
    end
    fab!(:car) do
      DesUserCar.create!(
        user: racer,
        manufacturer: manufacturer,
        car_model: car_model,
        transponder_number: "7654321",
      )
    end

    it "hides transponder numbers from everyone but the owner and admins" do
      [nil, member].each do |user|
        get_as(user, "/des/garage/#{racer.username}/public.json")
        expect(response.parsed_body["cars"].map { |c| c["transponder_number"] }).to eq([nil])
      end

      [racer, admin].each do |user|
        get_as(user, "/des/garage/#{racer.username}/public.json")
        expect(response.parsed_body["cars"].map { |c| c["transponder_number"] }).to eq(["7654321"])
      end
    end

    it "lists car model racers without full names" do
      get_as(member, "/des/car-models/#{car_model.id}.json")
      expect(response.parsed_body["racers"].map { |r| r["username"] }).to eq([racer.username])
      expect(response.parsed_body["racers"].flat_map(&:keys)).not_to include("name")
    end
  end

  describe "GET /des/transponders/user/:user_id" do
    it "lets an official see transponders only of people who booked their organisation's events" do
      get_as(other_organiser, "/des/transponders/user/#{racer.id}.json")
      expect(response.status).to eq(403)

      get_as(organiser, "/des/transponders/user/#{racer.id}.json")
      expect(response.status).to eq(200)
    end
  end

  describe "organisation payout email" do
    it "is only returned to the organisation's admins" do
      get_as(member, "/des/organisations/#{organisation.id}.json")
      expect(response.parsed_body["paypal_email"]).to be_nil

      get_as(member, "/des/organisations.json")
      listed = response.parsed_body["organisations"].find { |o| o["id"] == organisation.id }
      expect(listed["paypal_email"]).to be_nil

      get_as(organiser, "/des/organisations/#{organisation.id}.json")
      expect(response.parsed_body["paypal_email"]).to eq("treasurer@example.com")
    end

    it "omits draft events from the organisation page for non-admins" do
      get_as(member, "/des/organisations/#{organisation.id}.json")
      expect(response.parsed_body["events"].map { |e| e["id"] }).to contain_exactly(event.id)

      get_as(organiser, "/des/organisations/#{organisation.id}.json")
      expect(response.parsed_body["events"].map { |e| e["id"] }).to contain_exactly(
        event.id,
        draft_event.id,
      )
    end
  end
end
