class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_EMAIL", "support@nutry.fit")
  layout "mailer"
end
