module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def account_update_params
      params.require(:user).permit(:name)
    end

    def update_resource(resource, params)
      resource.update_without_password(params)
    end
  end
end
