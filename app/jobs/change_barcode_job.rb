# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class ChangeBarcodeJob < ApplicationJob
  queue_as :default

  def perform
    first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
    last_barcode = "#{first_three_digits_company_code}1S00001"
    ActiveRecord::Base.transaction do
      ProductBarcode.order(:id).each do |pb|
        pb.update_column(:barcode, last_barcode)
        last_barcode = "#{first_three_digits_company_code}1S#{last_barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
      end
    end
  end
end
