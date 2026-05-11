# frozen_string_literal: true

class RetainManufacturerLogoUploads < ActiveRecord::Migration[7.0]
  def up
    # Retain all existing manufacturer logo uploads so they aren't cleaned up
    upload_ids = DB.query_single("SELECT logo_upload_id FROM des_manufacturers WHERE logo_upload_id IS NOT NULL")
    Upload.where(id: upload_ids).update_all(retain_hours: nil, access_control_post_id: 1)
  end

  def down; end
end
