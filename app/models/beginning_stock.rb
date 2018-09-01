class BeginningStock < ApplicationRecord
  belongs_to :warehouse
  has_many :beginning_stock_months, dependent: :destroy
  has_one :journal, as: :transactionable

  validate :warehouse_is_active
  after_create :beginning_stock_journal

  def get_gross_cost
    products = BeginningStock.get_products(self.id)
    gross_cost = 0
    products.each do |p|
      product = Product.find(p.id)
      if product.present?
        gross_cost = gross_cost + (product.active_cost.cost.to_i * p.quantity)
      else
        return nil
      end
    end
    return gross_cost
  end

  def get_gross_price
    product_details = BeginningStock.get_product_details(self.id)
    gross_price = 0
    product_details.each do |pd|
      product_detail = ProductDetail.find(pd.id)
      if product_detail.present?
        gross_price = gross_price + (product_detail.active_price.price.to_i * pd.quantity)
      else
        return nil
      end
    end
    return gross_price
  end

  private

  def warehouse_is_active
    errors.add(:base, "Sorry, warehouse is not active") if Warehouse.select("1 AS one").where(id: warehouse_id).where(["warehouses.is_active = ?", true]).blank?
  end

  def self.get_products(id)
    BeginningStock.find_by_sql [' SELECT products.id, SUM(beginning_stock_product_details.quantity) AS quantity FROM beginning_stocks INNER JOIN beginning_stock_months ON beginning_stock_months.beginning_stock_id = beginning_stocks.id INNER JOIN beginning_stock_products ON beginning_stock_products.beginning_stock_month_id = beginning_stock_months.id INNER JOIN beginning_stock_product_details ON beginning_stock_product_details.beginning_stock_product_id = beginning_stock_products.id INNER JOIN products ON products.id = beginning_stock_products.product_id WHERE (beginning_stocks.id = :id) GROUP BY products.id', {id: id}]
  end

  def self.get_product_details(id)
    BeginningStock.find_by_sql [' SELECT product_details.id, SUM(beginning_stock_product_details.quantity) AS quantity FROM beginning_stocks INNER JOIN warehouses ON warehouses.id = beginning_stocks.warehouse_id INNER JOIN beginning_stock_months ON beginning_stock_months.beginning_stock_id = beginning_stocks.id INNER JOIN beginning_stock_products ON beginning_stock_products.beginning_stock_month_id = beginning_stock_months.id INNER JOIN beginning_stock_product_details ON beginning_stock_product_details.beginning_stock_product_id = beginning_stock_products.id INNER JOIN products ON products.id = beginning_stock_products.product_id INNER JOIN product_details ON product_details.product_id = products.id WHERE (product_details.size_id = beginning_stock_product_details.size_id AND product_details.price_code_id = warehouses.price_code_id AND beginning_stocks.id = :id) GROUP BY product_details.id', {id: id}]
  end

  def beginning_stock_journal
    gross_cost =self.get_gross_cost
    cost_ppn = gross_cost.to_i * 10 /100
    cost_nett = gross_cost - cost_ppn
    gross_price =self.get_gross_price
    ppn = gross_price.to_i * 10 /100
    nett = gross_price - ppn
    coa = Coa.find_by_transaction_type('DO')
    warehouse = self.warehouse_id
    journal = self.build_journal(
      coa_id: coa.id,
      gross: gross_price.to_f,
      gross_after_discount: gross_price.to_f,
      discount: 0,
      ppn: ppn.to_f,
      nett: nett.to_f,
      transaction_date: self.created_at.to_date,
      activity: nil,
      warehouse_id: self.warehouse_id,
      cost_gross_price: gross_cost.to_f,
      cost_gross_after_discount: gross_cost.to_f,
      cost_discount: 0,
      cost_ppn: cost_ppn.to_f,
      cost_nett: cost_nett.to_f
    )
    journal.save
  end

end
