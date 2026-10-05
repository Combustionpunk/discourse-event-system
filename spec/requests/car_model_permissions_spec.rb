# frozen_string_literal: true

RSpec.describe "Car model permissions" do
  fab!(:admin)
  fab!(:moderator)
  fab!(:member, :user)
  fab!(:other_member, :user)

  fab!(:manufacturer) { DesManufacturer.create!(name: "Carten", status: "approved") }
  fab!(:pending_manufacturer) do
    DesManufacturer.create!(name: "Pending Motors", status: "pending", created_by: other_member.id)
  end
  fab!(:approved_model) do
    DesCarModel.create!(
      manufacturer: manufacturer,
      name: "T410 Rally",
      status: "approved",
      created_by: other_member.id,
    )
  end
  fab!(:other_model) do
    DesCarModel.create!(manufacturer: manufacturer, name: "M210", status: "approved")
  end
  fab!(:others_pending_model) do
    DesCarModel.create!(
      manufacturer: manufacturer,
      name: "Secret Prototype",
      status: "pending",
      created_by: other_member.id,
    )
  end
  fab!(:own_pending_model) do
    DesCarModel.create!(
      manufacturer: manufacturer,
      name: "My Suggestion",
      status: "pending",
      created_by: member.id,
    )
  end
  fab!(:own_rejected_model) do
    DesCarModel.create!(
      manufacturer: manufacturer,
      name: "My Rejected",
      status: "rejected",
      created_by: member.id,
    )
  end
  fab!(:rejected_model) do
    DesCarModel.create!(
      manufacturer: manufacturer,
      name: "Rejected Model",
      status: "rejected",
      created_by: other_member.id,
    )
  end
  fab!(:image_suggestion) do
    DesCarModelImageSuggestion.create!(
      car_model: approved_model,
      user: other_member,
      upload: Fabricate(:image_upload, user: other_member),
    )
  end

  write_endpoints = {
    "PUT /des/admin/models/:id" => -> do
      put "/des/admin/models/#{approved_model.id}.json", params: { name: "Renamed" }
    end,
    "POST /des/admin/models" => -> do
      post "/des/admin/models.json", params: { manufacturer_id: manufacturer.id, name: "New Model" }
    end,
    "DELETE /des/admin/models/:id" => -> { delete "/des/admin/models/#{other_model.id}.json" },
    "POST /des/admin/models/:id/approve" => -> do
      post "/des/admin/models/#{others_pending_model.id}/approve.json"
    end,
    "POST /des/admin/models/:id/reject" => -> do
      post "/des/admin/models/#{others_pending_model.id}/reject.json"
    end,
    "GET /des/admin/models/:id/merge-preview" => -> do
      get "/des/admin/models/#{other_model.id}/merge-preview.json",
          params: {
            target_id: approved_model.id,
          }
    end,
    "POST /des/admin/models/:id/merge" => -> do
      post "/des/admin/models/#{other_model.id}/merge.json",
           params: {
             target_id: approved_model.id,
           }
    end,
    "GET /des/admin/models/name-tidy" => -> { get "/des/admin/models/name-tidy.json" },
    "POST /des/admin/models/name-tidy" => -> do
      post "/des/admin/models/name-tidy.json", params: { ids: [] }
    end,
    "POST /des/admin/image-suggestions/:id/approve" => -> do
      post "/des/admin/image-suggestions/#{image_suggestion.id}/approve.json"
    end,
    "POST /des/admin/image-suggestions/:id/reject" => -> do
      post "/des/admin/image-suggestions/#{image_suggestion.id}/reject.json"
    end,
    "POST /des/admin/manufacturers/:id/approve" => -> do
      post "/des/admin/manufacturers/#{pending_manufacturer.id}/approve.json"
    end,
    "POST /des/admin/manufacturers/:id/reject" => -> do
      post "/des/admin/manufacturers/#{pending_manufacturer.id}/reject.json"
    end,
    "PUT /des/admin/manufacturers/:id" => -> do
      put "/des/admin/manufacturers/#{manufacturer.id}.json", params: { name: "Carten RC" }
    end,
    "DELETE /des/admin/manufacturers/:id" => -> do
      delete "/des/admin/manufacturers/#{pending_manufacturer.id}.json"
    end,
    "POST /des/admin/scales" => -> { post "/des/admin/scales.json", params: { name: "1/5" } },
    "POST /des/admin/chassis-types" => -> do
      post "/des/admin/chassis-types.json", params: { name: "Crawler" }
    end,
  }

  describe "admin-only write endpoints" do
    write_endpoints.each do |name, perform|
      it "#{name} is forbidden to anonymous users, members and moderators, and allowed for admins" do
        instance_exec(&perform)
        expect(response.status).to eq(403)

        [member, moderator].each do |user|
          sign_in(user)
          instance_exec(&perform)
          expect(response.status).to eq(403),
          "expected 403 for #{user.username}, got #{response.status}"
        end

        sign_in(admin)
        instance_exec(&perform)
        expect(response.status).to be_between(200, 201),
        "expected success for admin, got #{response.status}: #{response.body}"
      end
    end
  end

  describe "POST /des/car-models/:id/box-art" do
    def suggest_box_art(user, model = approved_model)
      sign_in(user) if user
      post "/des/car-models/#{model.id}/box-art.json",
           params: {
             upload_id: user && Fabricate(:image_upload, user: user).id,
           }
    end

    it "requires login" do
      suggest_box_art(nil)
      expect(response.status).to eq(403)
    end

    it "only queues a suggestion for members and moderators" do
      [member, moderator].each do |user|
        suggest_box_art(user)
        expect(response.status).to eq(201)
        expect(response.parsed_body["applied"]).to eq(false)
      end
      expect(approved_model.reload.box_art_upload_id).to be_nil
    end

    it "applies the box art directly for admins" do
      suggest_box_art(admin)
      expect(response.parsed_body["applied"]).to eq(true)
      expect(approved_model.reload.box_art_upload_id).to be_present
    end

    it "returns 404 for a pending model suggested by someone else" do
      suggest_box_art(member, others_pending_model)
      expect(response.status).to eq(404)
    end
  end

  describe "POST /des/car-models/suggest-manufacturer" do
    it "returns 403 for anonymous users" do
      post "/des/car-models/suggest-manufacturer.json", params: { name: "New Brand" }
      expect(response.status).to eq(403)
    end

    it "creates a pending manufacturer for members" do
      sign_in(member)
      post "/des/car-models/suggest-manufacturer.json", params: { name: "New Brand" }
      expect(response.status).to eq(201)
      expect(DesManufacturer.find_by(name: "New Brand").status).to eq("pending")
    end
  end

  describe "GET /des/car-models" do
    # Migrations seed manufacturers into the test database, so check membership rather than exact sets.
    def listed_model_ids
      listed_models.map { |m| m["id"] }
    end

    def listed_models
      response.parsed_body["models_by_manufacturer"].flat_map { |group| group["models"] }
    end

    def listed_manufacturer_ids
      response.parsed_body["manufacturers"].map { |m| m["id"] }
    end

    def creator_of(model)
      listed_models.find { |m| m["id"] == model.id }["created_by"]
    end

    it "shows anonymous users only approved models and manufacturers, without creators" do
      get "/des/car-models.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["can_edit"]).to eq(false)
      expect(listed_model_ids).to include(approved_model.id, other_model.id)
      expect(listed_model_ids).not_to include(
        others_pending_model.id,
        own_pending_model.id,
        own_rejected_model.id,
        rejected_model.id,
      )
      expect(listed_models.map { |m| m["created_by"] }).to all(be_nil)
      expect(listed_manufacturer_ids).to include(manufacturer.id)
      expect(listed_manufacturer_ids).not_to include(pending_manufacturer.id)
    end

    it "adds a member's own pending suggestions, and names the creator only on those" do
      sign_in(member)
      get "/des/car-models.json"

      expect(listed_model_ids).to include(approved_model.id, other_model.id, own_pending_model.id)
      expect(listed_model_ids).not_to include(
        others_pending_model.id,
        own_rejected_model.id,
        rejected_model.id,
      )
      expect(creator_of(own_pending_model)).to eq(member.username)
      expect(creator_of(approved_model)).to be_nil
      expect(response.parsed_body["can_edit"]).to eq(false)
    end

    it "treats moderators like members" do
      sign_in(moderator)
      get "/des/car-models.json"

      expect(response.parsed_body["can_edit"]).to eq(false)
      expect(listed_model_ids).to include(approved_model.id, other_model.id)
      expect(listed_model_ids).not_to include(
        others_pending_model.id,
        own_pending_model.id,
        rejected_model.id,
      )
      expect(listed_manufacturer_ids).to include(manufacturer.id)
      expect(listed_manufacturer_ids).not_to include(pending_manufacturer.id)
    end

    it "shows admins every model and manufacturer with creators" do
      sign_in(admin)
      get "/des/car-models.json"

      expect(response.parsed_body["can_edit"]).to eq(true)
      expect(listed_model_ids).to include(
        approved_model.id,
        other_model.id,
        others_pending_model.id,
        own_pending_model.id,
        own_rejected_model.id,
        rejected_model.id,
      )
      expect(creator_of(approved_model)).to eq(other_member.username)
      expect(listed_manufacturer_ids).to include(manufacturer.id, pending_manufacturer.id)
    end
  end

  describe "GET /des/car-models/:id" do
    it "returns 404 for pending and rejected models to anonymous users, other members and moderators" do
      [nil, member, moderator].each do |user|
        sign_in(user) if user
        [others_pending_model, rejected_model].each do |model|
          get "/des/car-models/#{model.id}.json"
          expect(response.status).to eq(404),
          "expected 404 for #{user&.username || "anon"} on #{model.name}"
        end
      end
    end

    it "lets suggesters open their own pending and rejected models" do
      sign_in(member)
      [own_pending_model, own_rejected_model].each do |model|
        get "/des/car-models/#{model.id}.json"
        expect(response.status).to eq(200)
        expect(response.parsed_body["model"]["created_by"]).to eq(member.username)
      end
    end

    it "hides the creator and edit options from non-admins" do
      sign_in(moderator)
      get "/des/car-models/#{approved_model.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["model"]["created_by"]).to be_nil
      expect(response.parsed_body["can_edit"]).to eq(false)
      expect(response.parsed_body["edit_options"]).to be_nil
    end

    it "gives admins any model with the creator and edit options" do
      sign_in(admin)
      get "/des/car-models/#{rejected_model.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["model"]["created_by"]).to eq(other_member.username)
      expect(response.parsed_body["can_edit"]).to eq(true)
      expect(response.parsed_body["edit_options"]["manufacturers"].map { |m| m["id"] }).to include(
        manufacturer.id,
      )
    end
  end

  describe "garage model lookups" do
    it "lists only approved models and the member's own pending ones" do
      sign_in(member)
      get "/des/garage/models.json", params: { manufacturer_id: manufacturer.id }

      model_ids = response.parsed_body["models"].map { |m| m["id"] }
      expect(model_ids).to include(approved_model.id, other_model.id, own_pending_model.id)
      expect(model_ids).not_to include(others_pending_model.id, rejected_model.id)
    end

    it "does not reveal another member's pending model when suggesting the same name" do
      sign_in(member)
      post "/des/garage/suggest-model.json",
           params: {
             manufacturer_id: manufacturer.id,
             name: others_pending_model.name,
           }

      expect(response.status).to eq(201)
      expect(response.parsed_body["id"]).not_to eq(others_pending_model.id)
    end
  end
end
