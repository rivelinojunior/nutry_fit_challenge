class CreateCheckins < ActiveRecord::Migration[8.1]
  def change
    create_table :checkins do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :challenge_task, null: false, foreign_key: true
      t.datetime :checked_at

      t.timestamps
    end

    add_index :checkins, [ :participant_id, :challenge_task_id ], unique: true
  end
end
