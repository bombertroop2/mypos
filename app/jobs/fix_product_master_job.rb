# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class FixProductMasterJob < ApplicationJob
  queue_as :default

  def perform
    products = Product.joins(:size_group).where("size_groups.code = 'A'")
    products.each do |product|
      product.product_colors.each do |pc|
        product.product_details.pluck(:size_id).uniq.each do |size_id|
          product_barcode = ProductBarcode.where(product_color_id: pc.id, size_id: size_id).first
          if product_barcode.blank?
            pb = ProductBarcode.where(["barcode LIKE ?", "1S%"]).select(:barcode).order("barcode DESC").first
            barcode = if pb.present?
              "1S#{pb.barcode.split("1S")[1].succ}"
            else
              "1S00001"
            end
            product_barcode = ProductBarcode.new(product_color_id: pc.id, size_id: size_id, barcode: barcode)
            product_barcode.save
          end
        end
      end
    end
  end
end
