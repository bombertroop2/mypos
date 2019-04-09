# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class FixProductMasterJob < ApplicationJob
  queue_as :default

  def perform
    begin
      products = Product.joins(:size_group).where("size_groups.code = 'A'")
      products.each do |product|
        product.product_colors.each do |pc|
          product.product_details.pluck(:size_id).uniq.each do |size_id|
            product_barcode = ProductBarcode.where(product_color_id: pc.id, size_id: size_id).first
            if product_barcode.blank?
              first_three_digits_company_code = Company.order(:id).pluck(:code).first.first(3)
              pb = ProductBarcode.where(["barcode LIKE ?", "#{first_three_digits_company_code}1S%"]).select(:barcode).order("barcode DESC").first
              barcode = if pb.present?
                "#{first_three_digits_company_code}1S#{pb.barcode.split("#{first_three_digits_company_code}1S")[1].succ}"
              else
                "#{first_three_digits_company_code}1S00001"
              end
              product_barcode = ProductBarcode.new(product_color_id: pc.id, size_id: size_id, barcode: barcode)
              product_barcode.save
            end
          end
        end
      end
    end
    DuosMailer.import_product_error_email("BERES ANJING").deliver
  rescue    
    DuosMailer.import_product_error_email("ERROR GOBLOG").deliver
  end
end
