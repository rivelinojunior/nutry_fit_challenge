class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.datetime :joined_at

      t.timestamps
    end

    add_index :participants, [ :user_id, :challenge_id ], unique: true
  end
end
