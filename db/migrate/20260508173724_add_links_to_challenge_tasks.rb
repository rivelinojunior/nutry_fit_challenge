class AddLinksToChallengeTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :challenge_tasks, :links, :jsonb
  end
end
