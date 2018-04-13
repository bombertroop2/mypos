class ApplicationMailer < ActionMailer::Base
  company_code = Company.pluck(:code).first
  default from: "admin@#{company_code}.com"
  layout 'mailer'
end

