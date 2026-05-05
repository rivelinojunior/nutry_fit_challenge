class AddChallengeCodeToChallenges < ActiveRecord::Migration[8.1]
  class ChallengeRecord < ActiveRecord::Base
    self.table_name = "challenges"
  end

  CODE_LENGTH = 6

  def up
    add_column :challenges, :challenge_code, :string

    ChallengeRecord.reset_column_information
    ChallengeRecord.find_each do |challenge|
      challenge.update_columns(challenge_code: generate_unique_challenge_code)
    end

    change_column_null :challenges, :challenge_code, false
    add_index :challenges, :challenge_code, unique: true
  end

  def down
    remove_index :challenges, :challenge_code
    remove_column :challenges, :challenge_code
  end

  private

  def generate_unique_challenge_code
    loop do
      code = SecureRandom.alphanumeric(CODE_LENGTH).upcase

      return code unless ChallengeRecord.exists?(challenge_code: code)
    end
  end
end
