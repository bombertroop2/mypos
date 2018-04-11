class Supervisor < ApplicationRecord
  audited on: [:create, :update]
  has_many :sales_promotion_girls, through: :warehouses
  has_many :warehouses, dependent: :restrict_with_error
  has_one :warehouse_relation, -> {select("1 AS one")}, class_name: "Warehouse"

  validates :code, :name, :address, :mobile_phone, presence: true
  validates :code, :mobile_phone, uniqueness: true
  validates :email, uniqueness: true, if: proc { |spv| spv.email.present? }
    validate :code_not_changed

    before_save :convert_email_value_to_nil

    before_validation :upcase_code, :replace_underline_from_mobile_phone, :strip_string_values
    
    before_destroy :delete_tracks

    private
    
    def delete_tracks
      audits.destroy_all
    end

    def strip_string_values
      self.code = code.strip
    end
    
    def replace_underline_from_mobile_phone
      self.mobile_phone = mobile_phone.gsub("_", "")
    end
    
    def code_not_changed
      errors.add(:code, "change is not allowed!") if code_changed? && persisted? && warehouse_relation.present?
    end
    
    def convert_email_value_to_nil
      self.email = nil unless email.present?
    end

    #    def titleize_name
    #      self.name = name.titleize
    #    end

    def upcase_code
      self.code = code.upcase.gsub(" ","")
    end
  end
