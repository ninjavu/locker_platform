class CreateLockers < ActiveRecord::Migration[8.1]
  def change
    create_table :lockers do |t|
      t.string :name, null: false
      t.string :state, null: false, default: "closed"
      t.references :team, null: false, foreign_key: true, index: false
      # Optimistic locking: concurrent open/close on the same locker must not
      # both succeed, or the audit log desyncs from the actual state.
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
    # Names are unique per team, not globally: locker naming is a tenant's
    # business, and a global constraint would couple tenants to each other.
    add_index :lockers, [ :team_id, :name ], unique: true
  end
end
