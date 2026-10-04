class CreateOutboxEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :outbox_events do |t|
      t.string :subject, null: false
      t.bigint :entity_id, null: false
      t.jsonb :payload, null: false
      t.datetime :occurred_at, null: false
      t.datetime :published_at
      t.datetime :created_at, null: false
    end
    add_index :outbox_events, :id, where: "published_at IS NULL", name: "index_outbox_events_unpublished"
    add_index :outbox_events, :published_at, where: "published_at IS NOT NULL"
  end
end
