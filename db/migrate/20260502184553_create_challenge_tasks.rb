class CreateChallengeTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :challenge_tasks do |t|
      t.references :challenge, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.integer :points
      t.date :scheduled_on
      t.time :allowed_start_time
      t.time :allowed_end_time

      t.timestamps
    end

    add_index :challenge_tasks, [ :challenge_id, :scheduled_on ]
  end
end
