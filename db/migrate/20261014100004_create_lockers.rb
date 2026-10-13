class CreateLockers < ActiveRecord::Migration[8.1]
  def change
    create_table :lockers do |t|
      t.string :name, null: false
      t.string :state, null: false, default: "closed"
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
    add_index :lockers, :name, unique: true
  end
end
