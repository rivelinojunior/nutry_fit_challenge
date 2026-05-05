require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it "is valid with a name, email, and password" do
    expect(user).to be_valid
  end

  it "requires a name" do
    user.name = nil

    expect(user).not_to be_valid
  end

  it "requires an email" do
    user.email = nil

    expect(user).not_to be_valid
  end

  it "requires a password with the default minimum length" do
    user.password = "12345"
    user.password_confirmation = "12345"

    expect(user).not_to be_valid
  end

  it "authenticates with the Devise password" do
    user = create(:user)

    expect(user.valid_password?("password123")).to be(true)
  end

  it "sends confirmation instructions when created unconfirmed" do
    ActionMailer::Base.deliveries.clear

    create(:user, confirmed_at: nil)

    expect(ActionMailer::Base.deliveries.map(&:subject)).to include(
      I18n.t("devise.mailer.confirmation_instructions.subject")
    )
  end

  it "has many challenges with dependent destroy" do
    association = described_class.reflect_on_association(:challenges)

    expect(association).to have_attributes(macro: :has_many, options: include(dependent: :destroy))
  end

  it "has many participants with dependent destroy" do
    association = described_class.reflect_on_association(:participants)

    expect(association).to have_attributes(macro: :has_many, options: include(dependent: :destroy))
  end

  describe "#admin?" do
    context "when the user role is admin" do
      subject(:user) { build(:user, :admin) }

      it "returns true" do
        expect(user.admin?).to be(true)
      end
    end

    context "when the user role is not admin" do
      it "returns false" do
        expect(user.admin?).to be(false)
      end
    end
  end
end
