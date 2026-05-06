class CreateChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :challenges do |t|
      t.string :name
      t.text :description
      t.date :start_date
      t.date :end_date
      t.string :timezone, null: false, default: "America/Sao_Paulo"
      t.string :status, null: false, default: "draft"
      t.string :challenge_code, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :challenges, :challenge_code, unique: true
  end
end
