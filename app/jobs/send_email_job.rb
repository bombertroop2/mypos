class SendEmailJob < ApplicationJob
  queue_as :default

  def perform(account_payable)
    DuosMailer.payment_email(account_payable, account_payable.vendor.email).deliver
    Email.account_payable_officers.each do |account_payable_officer_email|
      DuosMailer.payment_email(account_payable, account_payable_officer_email.address).deliver
    end
  end
end
