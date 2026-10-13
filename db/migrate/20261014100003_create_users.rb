class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :role, null: false, default: "employee"
      t.references :team, foreign_key: true

      t.timestamps
    end
  end
end
