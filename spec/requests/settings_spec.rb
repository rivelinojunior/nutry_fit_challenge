require "rails_helper"

RSpec.describe "Settings" do
  let(:user) { create(:user, name: "Rivelino Junior") }

  describe "GET /settings" do
    context "when the user is not signed in" do
      it "redirects to sign in" do
        get settings_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the user is signed in" do
      before do
        sign_in user
      end

      it "renders successfully" do
        get settings_path

        expect(response).to have_http_status(:ok)
      end

      it "renders account actions" do
        get settings_path

        expect(response.body).to include("Senha")
        expect(response.body).to include("Editar conta")
        expect(response.body).to include("Cancelar conta")
      end

      it "links password settings to the password edit screen" do
        get settings_path

        password_link = Nokogiri::HTML(response.body).at_css("a[href='#{edit_settings_password_path}']")

        expect(password_link.text).to include("Senha")
      end

      it "links account cancellation to the cancellation screen" do
        get settings_path

        cancellation_link = Nokogiri::HTML(response.body).at_css("a[href='#{settings_account_cancellation_path}']")

        expect(cancellation_link.text).to include("Cancelar conta")
      end

      it "links the drawer settings item to the settings page" do
        get settings_path

        settings_link = Nokogiri::HTML(response.body).at_css("a[href='#{settings_path}']")

        expect(settings_link.text).to include("Configurações")
      end

      it "renders the signed in user name" do
        get settings_path

        expect(response.body).to include("Rivelino Junior")
      end
    end
  end

  describe "GET /settings/account_cancellation" do
    context "when the user is not signed in" do
      it "redirects to sign in" do
        get settings_account_cancellation_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the user is signed in" do
      before do
        sign_in user
      end

      it "renders the cancellation explanation" do
        get settings_account_cancellation_path

        expect(response.body).to include("remove seu acesso")
        expect(response.body).to include("encerra sua sessão")
        expect(response.body).to include("criar uma nova conta")
      end

      it "shows a back arrow instead of the burger menu button" do
        get settings_account_cancellation_path

        document = Nokogiri::HTML(response.body)

        expect(document.at_css("a[aria-label='Voltar para configurações']")).to be_present
        expect(response.body).not_to include("Abrir menu")
      end

      it "renders a delete account button" do
        get settings_account_cancellation_path

        document = Nokogiri::HTML(response.body)
        form = document.at_css("form[action='#{user_registration_path}']")

        expect(form.text).to include("Cancelar minha conta")
        expect(form.at_css("input[name='_method'][value='delete']")).to be_present
      end
    end
  end

  describe "GET /settings/password/edit" do
    context "when the user is not signed in" do
      it "redirects to sign in" do
        get edit_settings_password_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when the user is signed in" do
      before do
        sign_in user
      end

      it "renders only password fields" do
        get edit_settings_password_path

        expect(response.body).to include("Senha atual")
        expect(response.body).to include("Nova senha")
        expect(response.body).to include("Confirmar nova senha")
        expect(response.body).not_to include("E-mail")
      end

      it "shows a back arrow instead of the burger menu button" do
        get edit_settings_password_path

        document = Nokogiri::HTML(response.body)

        expect(document.at_css("a[aria-label='Voltar para configurações']")).to be_present
        expect(response.body).not_to include("Abrir menu")
      end
    end
  end

  describe "PATCH /settings/password" do
    before do
      sign_in user
    end

    it "updates the password" do
      patch settings_password_path, params: {
        user: {
          current_password: "password123",
          password: "new-password123",
          password_confirmation: "new-password123"
        }
      }

      expect(response).to redirect_to(settings_path)
      expect(user.reload.valid_password?("new-password123")).to be(true)

      follow_redirect!

      expect(response.body).to include("Senha atualizada.")
    end

    it "renders errors when the current password is invalid" do
      patch settings_password_path, params: {
        user: {
          current_password: "wrong-password",
          password: "new-password123",
          password_confirmation: "new-password123"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.valid_password?("password123")).to be(true)
    end
  end

  describe "GET /users/edit" do
    before do
      sign_in user
    end

    it "renders name as the only editable account field" do
      get edit_user_registration_path

      document = Nokogiri::HTML(response.body)

      expect(document.at_css("input[name='user[name]']")).to be_present
      expect(document.at_css("input[name='user[email]'][disabled]")).to be_present
      expect(response.body).not_to include("Senha atual")
      expect(response.body).not_to include("Nova senha")
    end

    it "uses the settings sub-screen header" do
      get edit_user_registration_path

      document = Nokogiri::HTML(response.body)

      expect(document.at_css("a[aria-label='Voltar para configurações']")).to be_present
      expect(response.body).not_to include("Abrir menu")
    end

    it "does not render the brand or cancel account block" do
      get edit_user_registration_path

      document = Nokogiri::HTML(response.body)
      main_content = document.at_css("main").to_html

      expect(main_content).not_to include("/icon.svg")
      expect(main_content).not_to include("Nutry.fit")
      expect(main_content).not_to include("Cancelar conta")
    end
  end

  describe "PUT /users" do
    before do
      sign_in user
    end

    it "updates the name without requiring the current password" do
      put user_registration_path, params: {
        user: {
          name: "Novo Nome"
        }
      }

      expect(response).to be_redirect
      expect(user.reload.name).to eq("Novo Nome")
    end

    it "ignores submitted email changes" do
      original_email = user.email

      put user_registration_path, params: {
        user: {
          name: "Novo Nome",
          email: "changed@example.com"
        }
      }

      expect(user.reload.email).to eq(original_email)
    end
  end
end
