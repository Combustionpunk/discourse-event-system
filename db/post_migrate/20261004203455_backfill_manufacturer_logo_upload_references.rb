# frozen_string_literal: true

class BackfillManufacturerLogoUploadReferences < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE des_manufacturers
      SET logo_upload_id = NULL
      WHERE logo_upload_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM uploads WHERE uploads.id = des_manufacturers.logo_upload_id)
    SQL

    # Undo the earlier retention workaround, which tied logos to post 1's access control.
    execute <<~SQL
      UPDATE uploads
      SET access_control_post_id = NULL
      WHERE access_control_post_id = 1
        AND id IN (SELECT logo_upload_id FROM des_manufacturers WHERE logo_upload_id IS NOT NULL)
    SQL

    execute <<~SQL
      INSERT INTO upload_references (upload_id, target_type, target_id, created_at, updated_at)
      SELECT logo_upload_id, 'DesManufacturer', id, NOW(), NOW()
      FROM des_manufacturers
      WHERE logo_upload_id IS NOT NULL
      ON CONFLICT DO NOTHING
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
