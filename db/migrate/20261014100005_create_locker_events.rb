class CreateLockerEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :locker_events do |t|
      t.references :locker, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false

      t.datetime :created_at, null: false
    end
    add_index :locker_events, :created_at
  end
end
