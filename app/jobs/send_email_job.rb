class SendEmailJob < ApplicationJob
  queue_as :default

  def perform(object, type="account payable payment")
    if type.eql?("account payable payment")
      DuosMailer.payment_email(object, object.vendor.email).deliver if object.vendor.email.present?
      Email.account_payable_officers.each do |account_payable_officer_email|
        DuosMailer.payment_email(object, account_payable_officer_email.address).deliver
      end
      #    elsif type.eql?("closing report")
      #      Email.sales_officers.each do |sales_officer_email|        
      #        DuosMailer.closing_cashier_report_email(object, sales_officer_email.address).deliver
      #      end
      #    elsif type.eql?("cash disbursement report")
      #      Email.account_receivable_officers.each do |account_receivable_officer_email|        
      #        DuosMailer.cash_disbursement_report_email(object, account_receivable_officer_email.address).deliver
      #      end
    elsif type.eql?("cash disbursement report and sales general summary")
      Email.account_receivable_officers.each do |account_receivable_officer_email|        
        DuosMailer.cash_disbursement_report_and_sales_general_summary_email(object, account_receivable_officer_email.address).deliver
      end
    elsif type.eql?("sales general summary")
      Email.sales_officers.each do |sales_officer_email|        
        DuosMailer.sales_general_summary_email(object, sales_officer_email.address).deliver
      end
    elsif type.eql?("account payable courier payment")
      Email.account_payable_officers.each do |account_payable_officer_email|
        DuosMailer.payment_email(object, account_payable_officer_email.address, "courier").deliver
      end
    elsif type.eql?("AR invoice")      
      recipient = Customer.select(:email).joins(order_bookings: :shipment).where(["shipments.id = ?", object.shipment_id]).first
      DuosMailer.ar_invoice_email(object, recipient.email).deliver
    end
  end
end
