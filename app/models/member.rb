class Member < ApplicationRecord
  audited on: [:create, :update]
  
  has_many :sales, dependent: :restrict_with_error

  before_validation :strip_string_values

  validates :name, :address, :gender, :mobile_phone, :email, :discount, presence: true
  validates :discount, numericality: {greater_than: 0, less_than: 100}, if: proc {|m| m.discount.present?}
    validates :mobile_phone, uniqueness: true, if: proc {|mbr| mbr.mobile_phone.present?}
      validates :email, uniqueness: true, if: proc {|mbr| mbr.email.present?}
        validate :gender_available, :member_product_event_not_changed, :discount_not_changed
  
        before_create :generate_member_id
  
        before_destroy :delete_tracks
  
        GENDERS = [
          ["Male", "male"],
          ["Female", "female"],
        ]
  
        private
        
        def discount_not_changed
          if discount_changed? && persisted?
            cashier_opened = CashierOpening.select("1 AS one").where("closed_at IS NULL").present?
            errors.add(:discount, "change is not allowed!") if cashier_opened
          end
        end
        
        def member_product_event_not_changed
          if member_product_event_changed? && persisted?
            cashier_opened = CashierOpening.select("1 AS one").where("closed_at IS NULL").present?
            errors.add(:base, "Please close the cashier first") if cashier_opened
          end
        end
      
        def delete_tracks
          audits.destroy_all
        end
   
        def strip_string_values
          self.name = name.strip
          self.address = address.strip
          self.email = email.strip
          self.mobile_phone = mobile_phone.delete("_").strip
        end
  
        def gender_available
          GENDERS.select{ |x| x[1] == gender }.first.first
        rescue
          errors.add(:gender, "does not exist!") if gender.present?
        end
  
        def generate_member_id
          self.member_id = Member.select(:member_id).last.member_id.succ rescue "000001"
        end
      end
