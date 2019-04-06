include AccountPayablesHelper
include PurchaseReturnsHelper
include AccountPayablePaymentsHelper
include AccountPayableCouriersHelper
include AccountPayableCourierPaymentsHelper
include ApplicationHelper
class DuosMailer < ApplicationMailer
  def payment_email(account_payable_payment, recipient, type="vendor")
    subject = ""
    template_name = ""
    if type.eql?("vendor")      
      @account_payable_payment = account_payable_payment
      subject = "AP Payment Document (Vendor)"
      template_name = "payment_email"
    else
      @account_payable_courier_payment = account_payable_payment
      subject = "AP Payment Document (Courier)"
      template_name = "payment_email_courier"
    end
    mail to: recipient, subject: subject, template_name: template_name
  end
  
  def ar_invoice_email(accounts_receivable_invoice, recipient)
    @company = Company.select(:id, :name, :address, :phone, :fax).first
    @accounts_receivable_invoice = accounts_receivable_invoice
    @customer = Customer.select(:name, :phone, :facsimile, :is_taxable_entrepreneur, :value_added_tax, :discount).joins(order_bookings: :shipment).where(["shipments.id = ?", @accounts_receivable_invoice.shipment_id]).first
    @shipment = Shipment.select(:delivery_order_number).find(@accounts_receivable_invoice.shipment_id)
    mail to: recipient, subject: "Invoice"
  end

  #  def closing_cashier_report_email(cashier_opening_id, recipient)
  #    @cashier_opening = @cashier_opening = CashierOpening.joins(:warehouse, user: :sales_promotion_girl).where(id: cashier_opening_id).
  #      select("sales_promotion_girls.name AS cashier_name, warehouses.code, warehouses.name, cashier_openings.id, cashier_openings.created_at, station, shift, beginning_cash, cash_balance, closed_at, cashier_openings.warehouse_id, opened_by").first
  #    send_email("no-reply@duos.com", recipient, 'Closing Report', render_to_string(template: "duos_mailer/closing_cashier_report_email"))
  #  end
  
  #  def cash_disbursement_report_email(cashier_opening_id, recipient)
  #    @cashier_opening = CashierOpening.joins(:warehouse, user: :sales_promotion_girl).where(id: cashier_opening_id).
  #      select("sales_promotion_girls.name AS cashier_name, warehouses.code, warehouses.name, cashier_openings.id, cashier_openings.created_at, station, shift, beginning_cash, cash_balance, closed_at, cashier_openings.warehouse_id, opened_by").first
  #    send_email("no-reply@duos.com", recipient, 'Cash Disbursement Report', render_to_string(template: "duos_mailer/cash_disbursement_report_email"))
  #  end

  def cash_disbursement_report_and_sales_general_summary_email(cashier_opening_id, recipient)
    @cashier_opening = CashierOpening.joins(:warehouse, user: :sales_promotion_girl).where(id: cashier_opening_id).
      select("sales_promotion_girls.name AS cashier_name, warehouses.code, warehouses.name, cashier_openings.id, cashier_openings.created_at, station, shift, beginning_cash, cash_balance, closed_at, cashier_openings.warehouse_id, opened_by, gross_sales, net_sales, total_quantity, total_gift_quantity, cash_payment, card_payment, debit_card_payment, credit_card_payment").first
    mail to: recipient, subject: "Cash Disbursement Report and General Sales Summary"
  end

  def sales_general_summary_email(cashier_opening_id, recipient)
    @cashier_opening = CashierOpening.joins(:warehouse, user: :sales_promotion_girl).where(id: cashier_opening_id).
      select("sales_promotion_girls.name AS cashier_name, warehouses.code, warehouses.name, cashier_openings.id, cashier_openings.created_at, station, shift, beginning_cash, cash_balance, closed_at, cashier_openings.warehouse_id, opened_by, gross_sales, net_sales, total_quantity, total_gift_quantity, cash_payment, card_payment, debit_card_payment, credit_card_payment").first
    mail to: recipient, subject: "General Sales Summary"
  end

  def import_data_email(type, errors, xls_error_index)
    @type = type
    @errors = errors
    @xls_error_index = xls_error_index
    send_email("no-reply@1s.com", "bombertroop@gmail.com", type, render_to_string(template: "duos_mailer/import_data_email"))
  end
  
  def import_product_error_email(message)
    @message = message
    mail to: "rizkinoorlaksana@gmail.com", subject: "Import Product Job"
  end

end
