include AccountPayablesHelper
include PurchaseReturnsHelper
class DuosMailer < ApplicationMailer
  def payment_email(account_payable, recipient)
    @account_payable = account_payable
    mg_client = Mailgun::Client.new "key-765df2e148aad35a693745a833d7e18f"
    message_params = {from: "admin@duos.com",
      to: recipient,
      subject: 'Account Payable Document',
      html: render_to_string(template: "duos_mailer/payment_email")
    }
    mg_client.send_message "sandboxc1b2e3edd37b498eaddf847f38e8cbaa.mailgun.org", message_params
  end
end
