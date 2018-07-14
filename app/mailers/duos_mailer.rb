include AccountPayablesHelper
include PurchaseReturnsHelper
class DuosMailer < ApplicationMailer
  def payment_email(account_payable, recipient, company_code)
    @account_payable = account_payable
    send_email("admin@#{company_code}.com", recipient, 'Account Payable Document', render_to_string(template: "duos_mailer/payment_email"))
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

  def cash_disbursement_report_and_sales_general_summary_email(cashier_opening_id, recipient, company_code)
    @cashier_opening = CashierOpening.joins(:warehouse, user: :sales_promotion_girl).where(id: cashier_opening_id).
      select("sales_promotion_girls.name AS cashier_name, warehouses.code, warehouses.name, cashier_openings.id, cashier_openings.created_at, station, shift, beginning_cash, cash_balance, closed_at, cashier_openings.warehouse_id, opened_by, gross_sales, net_sales, total_quantity, total_gift_quantity, cash_payment, card_payment, debit_card_payment, credit_card_payment").first
    send_email("no-reply@#{company_code}.com", recipient, 'Cash Disbursement Report and General Sales Summary', render_to_string(template: "duos_mailer/cash_disbursement_report_and_sales_general_summary_email"))
  end

  def sales_general_summary_email(cashier_opening_id, recipient, company_code)
    @cashier_opening = CashierOpening.joins(:warehouse, user: :sales_promotion_girl).where(id: cashier_opening_id).
      select("sales_promotion_girls.name AS cashier_name, warehouses.code, warehouses.name, cashier_openings.id, cashier_openings.created_at, station, shift, beginning_cash, cash_balance, closed_at, cashier_openings.warehouse_id, opened_by, gross_sales, net_sales, total_quantity, total_gift_quantity, cash_payment, card_payment, debit_card_payment, credit_card_payment").first
    send_email("no-reply@#{company_code}.com", recipient, 'General Sales Summary', render_to_string(template: "duos_mailer/sales_general_summary_email"))
  end

  def import_data_email(type, errors, xls_error_index)
    @type = type
    @errors = errors
    @xls_error_index = xls_error_index
    send_email("no-reply@1s.com", "bombertroop@gmail.com", type, render_to_string(template: "duos_mailer/import_data_email"))
  end

  private
  
  def send_email(from, to, subject, html)
    mg_client = Mailgun::Client.new "key-765df2e148aad35a693745a833d7e18f"
    message_params = {
      from: from,
      to: to,
      subject: subject,
      html: html
    }
    mg_client.send_message "sandboxc1b2e3edd37b498eaddf847f38e8cbaa.mailgun.org", message_params
  end
end
