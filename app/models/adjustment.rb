class Adjustment < ApplicationRecord
  belongs_to :warehouse
  has_many :adjustment_products, dependent: :destroy
  
  accepts_nested_attributes_for :adjustment_products
  
  audited on: :create

  validates :warehouse_id, :adj_type, :adj_date, presence: true
  validates :adj_date, date: {before_or_equal_to: proc { Date.current }, message: 'must be before or equal to today' }, if: proc {|adj| adj.adj_date.present?}
    validate :type_available, :check_min_product_per_adjustment, :transaction_open

    before_create :generate_number
    before_destroy :delete_tracks

    TYPES = [
      ["In", "In"],
      ["Out", "Out"]
    ]
    
    private
    
    def transaction_open
      errors.add(:base, "Sorry, you can't perform this transaction") if adj_date.present? && FiscalYear.joins(:fiscal_months).where(year: adj_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[adj_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
    end
    
    def delete_tracks
      audits.destroy_all
    end
    
    def check_min_product_per_adjustment
      errors.add(:base, "Adjustment must have at least one product") if adjustment_products.blank?
    end
    
    def type_available
      Adjustment::TYPES.select{ |x| x[1] == adj_type }.first.first
    rescue
      errors.add(:adj_type, "does not exist!") if adj_type.present?
    end
    
    def generate_number
      full_warehouse_code = Warehouse.select(:code).where(id: warehouse_id, is_active: true).first.code
      warehouse_code = full_warehouse_code.split("-")[0]
      current_month = adj_date.month.to_s.rjust(2, '0')
      current_year = adj_date.strftime("%y").rjust(2, '0')
      existed_numbers = Adjustment.where("number LIKE '#{warehouse_code}ADJ#{current_month}#{current_year}%'").select(:number).order(:number)
      if existed_numbers.blank?
        new_number = "#{warehouse_code}ADJ#{current_month}#{current_year}00001"
      else
        if existed_numbers.length == 1
          seq_number = existed_numbers[0].number.split("#{warehouse_code}ADJ#{current_month}#{current_year}").last
          if seq_number.to_i > 1
            new_number = "#{warehouse_code}ADJ#{current_month}#{current_year}00001"
          else
            new_number = "#{warehouse_code}ADJ#{current_month}#{current_year}#{seq_number.succ}"
          end
        else
          last_seq_number = ""
          existed_numbers.each_with_index do |existed_number, index|
            seq_number = existed_number.number.split("#{warehouse_code}ADJ#{current_month}#{current_year}").last
            if seq_number.to_i > 1 && index == 0
              new_number = "#{warehouse_code}ADJ#{current_month}#{current_year}00001"
              break                              
            elsif last_seq_number.eql?("")
              last_seq_number = seq_number
            elsif (seq_number.to_i - last_seq_number.to_i) > 1
              new_number = "#{warehouse_code}ADJ#{current_month}#{current_year}#{last_seq_number.succ}"
              break
            elsif index == existed_numbers.length - 1
              new_number = "#{warehouse_code}ADJ#{current_month}#{current_year}#{seq_number.succ}"
            else
              last_seq_number = seq_number
            end
          end
        end                        
      end
      self.number = new_number
    end
  end
