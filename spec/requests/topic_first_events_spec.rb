# frozen_string_literal: true

RSpec.describe "Topic-first events" do
  fab!(:admin)
  fab!(:member, :user)
  fab!(:organiser, :user)
  fab!(:other_organiser, :user)

  # The plugin creates this category at boot, so it may already exist in the test database.
  fab!(:meetings_category) do
    DesEvent.meetings_category ||
      Fabricate(
        :category,
        slug: SiteSetting.discourse_event_system_category_slug.presence || "rc-meetings",
      )
  end
  fab!(:admin_position) { DesPosition.create!(name: "Spec chair", is_admin: true) }
  fab!(:organisation) do
    DesOrganisation.create!(name: "Spec RC Club", status: "approved", created_by: organiser.id)
  end
  fab!(:other_organisation) do
    DesOrganisation.create!(
      name: "Other RC Club",
      status: "approved",
      created_by: other_organiser.id,
    )
  end
  fab!(:memberships) do
    [[organisation, organiser], [other_organisation, other_organiser]].map do |org, user|
      DesOrganisationMember.create!(
        organisation: org,
        user: user,
        position: admin_position,
        status: "active",
      )
    end
  end
  fab!(:club_meeting) { DesEventType.create!(name: "Spec club meeting") }
  fab!(:championship) { DesEventType.create!(name: "Spec championship round") }

  def create_event(
    start_date: 10.days.from_now,
    event_type: club_meeting,
    with_topic: true,
    **attrs
  )
    DesEvent.create!(
      title: "Spec event #{SecureRandom.hex(3)}",
      organisation: organisation,
      event_type: event_type,
      created_by: organiser.id,
      start_date: start_date,
      status: "published",
      topic_id: with_topic ? Fabricate(:topic, category: meetings_category).id : nil,
      **attrs,
    )
  end

  describe "GET /events" do
    it "redirects anonymous users and members to the RC Meetings category" do
      get "/events"
      expect(response).to redirect_to(meetings_category.url)

      sign_in(member)
      get "/events"
      expect(response).to redirect_to(meetings_category.url)
    end

    it "serves the back office to organisers and admins" do
      [organiser, other_organiser, admin].each do |user|
        sign_in(user)
        get "/events"
        expect(response.status).to eq(200), "expected 200 for #{user.username}"
      end
    end
  end

  describe "GET /events/:id" do
    fab!(:event) { create_event }

    it "redirects anonymous users, members and other organisations' officials to the topic" do
      [nil, member, other_organiser].each do |user|
        sign_in(user) if user
        get "/events/#{event.id}"
        expect(response).to redirect_to(event.topic.relative_url)
      end
    end

    it "serves the back-office page to the event's organisers and admins" do
      [organiser, admin].each do |user|
        sign_in(user)
        get "/events/#{event.id}"
        expect(response.status).to eq(200)
      end
    end

    it "returns 404 to members for drafts and events without a topic" do
      draft = create_event(status: "draft", with_topic: false)
      topicless = create_event(with_topic: false)
      sign_in(member)

      [draft, topicless].each do |hidden|
        get "/events/#{hidden.id}"
        expect(response.status).to eq(404)
      end

      sign_in(organiser)
      get "/events/#{draft.id}"
      expect(response.status).to eq(200)
    end

    it "keeps the new-event, manage and PayPal return pages" do
      sign_in(member)
      [
        "/events/new",
        "/events/#{event.id}/manage",
        "/events/booking/1/confirm",
        "/events/booking/1/cancel",
      ].each do |path|
        get path
        expect(response.status).to eq(200), "expected #{path} to be served"
      end
    end
  end

  describe "current user and site serializers" do
    it "flags organisers and exposes the RC Meetings URL" do
      sign_in(organiser)
      get "/session/current.json"
      expect(response.parsed_body["current_user"]["des_event_organiser"]).to eq(true)

      sign_in(member)
      get "/session/current.json"
      expect(response.parsed_body["current_user"]["des_event_organiser"]).to eq(false)

      get "/site.json"
      expect(response.parsed_body["des_meetings_url"]).to eq(meetings_category.url)
    end
  end

  describe "widget lifecycle state (GET /des/events/by-topic/:topic_id)" do
    def state_of(event)
      get "/des/events/by-topic/#{event.topic_id}.json"
      response.parsed_body["lifecycle_state"]
    end

    def add_result(event, status)
      DesEventResult
        .create!(event: event, status: status)
        .tap do |result|
          race = DesEventResultRace.create!(event_result: result, race_name: "A Final")
          DesEventResultEntry.create!(race: race, position: 1, driver_name: "Driver", user: member)
        end
    end

    it "is upcoming before the event and cancelled once cancelled" do
      event = create_event
      expect(state_of(event)).to eq("upcoming")

      event.update!(status: "cancelled")
      expect(state_of(event)).to eq("cancelled")
    end

    it "is race_day on the day of a multi-day event" do
      event = create_event(start_date: 1.day.ago, end_date: 1.day.from_now)
      expect(state_of(event)).to eq("race_day")
    end

    it "awaits results after a championship round or an event with an RC Results meeting" do
      championship_round = create_event(start_date: 3.days.ago, event_type: championship)
      with_meeting_id = create_event(start_date: 3.days.ago, rc_results_meeting_id: 123)

      expect(state_of(championship_round)).to eq("awaiting_results")
      expect(state_of(with_meeting_id)).to eq("awaiting_results")
    end

    it "expects no results from past club meetings or external events" do
      club = create_event(start_date: 3.days.ago)
      external =
        create_event(start_date: 3.days.ago, event_type: championship, booking_type: "external")

      expect(state_of(club)).to eq("no_results_expected")
      expect(state_of(external)).to eq("no_results_expected")
    end

    it "is processing while results are unpublished, and results once published" do
      event = create_event(start_date: 3.days.ago, event_type: championship)
      result = add_result(event, "pending_match")
      expect(state_of(event)).to eq("processing")

      result.update!(status: "published")
      expect(state_of(event)).to eq("results")
    end

    it "lets anonymous users read published results, but only the status of unpublished ones" do
      event = create_event(start_date: 3.days.ago, event_type: championship)
      result = add_result(event, "pending_match")

      get "/des/events/#{event.id}/results.json"
      expect(response.parsed_body).to eq("status" => "pending_match")

      result.update!(status: "published")
      get "/des/events/#{event.id}/results.json"
      expect(response.parsed_body["races"].first["entries"].first["user"]).to include(
        "username" => member.username,
        "name" => nil,
      )
    end
  end

  describe "GET /des/rc-events-topic-list" do
    it "keeps cancelled events listed until their date passes" do
      upcoming_cancelled = create_event(status: "cancelled")
      past_cancelled = create_event(status: "cancelled", start_date: 3.days.ago)

      get "/des/rc-events-topic-list.json", params: { time_filter: "all" }
      listed = response.parsed_body["topics"].to_h { |topic| [topic["id"], topic["status"]] }

      expect(listed).to include(upcoming_cancelled.id => "cancelled")
      expect(listed).not_to include(past_cancelled.id)
    end
  end
end
