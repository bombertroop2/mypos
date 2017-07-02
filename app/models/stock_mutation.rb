class StockMutation < ApplicationRecord
  attr_accessor :mutation_type
  
  audited on: :create

  belongs_to :courier
  belongs_to :origin_warehouse, class_name: "Warehouse", foreign_key: :origin_warehouse_id
  belongs_to :destination_warehouse, class_name: "Warehouse", foreign_key: :destination_warehouse_id
  has_many :stock_mutation_products, dependent: :destroy

  accepts_nested_attributes_for :stock_mutation_products

  validates :delivery_date, :courier_id, :origin_warehouse_id, :destination_warehouse_id, presence: true
  validates :delivery_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|shpmnt| shpmnt.delivery_date.present?}
    validate :courier_available, :origin_warehouse_available, :destination_warehouse_available

    before_create :generate_number
    before_destroy :delete_tracks
    after_create :notify_origin_store, :notify_destination_store, unless: proc {|sm| sm.destination_warehouse.warehouse_type.eql?("central")}
      after_create :notify_warehouse, if: proc {|sm| sm.destination_warehouse.warehouse_type.eql?("central")}
    
        private
  
        def notify_origin_store
          notification = Notification.new(event: "New Notification", body: "Please send #{destination_warehouse.name} a stock mutation #{number}", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
          origin_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
            notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
          end
          notification.save
        end

        def notify_destination_store
          notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
          destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
            notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
          end
          notification.save
        end

        def notify_warehouse
          notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
          User.joins(:roles).where("roles.name = 'staff' OR roles.name = 'manager'").select(:id).each do |user|
            notification.recipients.build user_id: user.id, notified: false, read: false
          end
          notification.save
        end
    
        def delete_tracks
          audits.destroy_all
        end
    
        def courier_available
          errors.add(:courier_id, "does not exist!") if courier_id.present? && Courier.where(id: courier_id).select("1 AS one").blank?
        end

        def origin_warehouse_available
          errors.add(:origin_warehouse_id, "does not exist!") if (origin_warehouse_id.present? && Warehouse.not_central.where(id: origin_warehouse_id).select("1 AS one").blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
        end

        def destination_warehouse_available
          if (!mutation_type.eql?("store to warehouse") && destination_warehouse_id.present? && Warehouse.not_central.where(id: destination_warehouse_id).select("1 AS one").blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
            errors.add(:destination_warehouse_id, "does not exist!")
          elsif (mutation_type.eql?("store to warehouse") && destination_warehouse_id.present? && Warehouse.central.where(id: destination_warehouse_id).select("1 AS one").blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
            errors.add(:destination_warehouse_id, "does not exist!")
          end
        end
    
        def generate_number
          number_id = if mutation_type.eql?("store to warehouse")
            "RW"
          else
            "RGO"
          end
          
          warehouse_code = Warehouse.select(:code).where(id: origin_warehouse_id).first.code
          today = Date.current
          current_month = today.month.to_s.rjust(2, '0')
          current_year = today.strftime("%y").rjust(2, '0')
          existed_numbers = StockMutation.where("number LIKE '#{warehouse_code}#{number_id}#{current_month}#{current_year}%'").select(:number).order(:number)
          if existed_numbers.blank?
            new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
          else
            if existed_numbers.length == 1
              seq_number = existed_numbers[0].number.split("#{warehouse_code}#{number_id}#{current_month}#{current_year}").last
              if seq_number.to_i > 1
                new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
              else
                new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{seq_number.succ}"
              end
            else
              last_seq_number = ""
              existed_numbers.each_with_index do |existed_number, index|
                seq_number = existed_number.number.split("#{warehouse_code}#{number_id}#{current_month}#{current_year}").last
                if seq_number.to_i > 1 && index == 0
                  new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
                  break                              
                elsif last_seq_number.eql?("")
                  last_seq_number = seq_number
                elsif (seq_number.to_i - last_seq_number.to_i) > 1
                  new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{last_seq_number.succ}"
                  break
                elsif index == existed_numbers.length - 1
                  new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{seq_number.succ}"
                else
                  last_seq_number = seq_number
                end
              end
            end                        
          end

          self.number = new_number
        end
      end
