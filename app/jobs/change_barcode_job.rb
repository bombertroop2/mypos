# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class ChangeBarcodeJob < ApplicationJob
  queue_as :default

  def perform
    first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
    ProductBarcode.order(:id).each do |pb|
      if !pb.barcode.first(3).eql?(first_three_digits_company_code)
        last_barcode = ProductBarcode.where(["barcode LIKE ?", "#{first_three_digits_company_code}1S%"]).select(:barcode).order("barcode DESC").first
        barcode = if last_barcode.present?
          "#{first_three_digits_company_code}1S#{last_barcode.barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
        else
          "#{first_three_digits_company_code}1S00001"
        end
        pb.update_column(:barcode, barcode)
      end
    end
  end
end
