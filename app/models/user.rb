class User < ApplicationRecord
  rolify
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable
  
  attr_accessor :role, :login, :creating_spg_user, :updating_spg_user#:spg_role
       
  audited on: [:create, :update], except: ["current_sign_in_at", "last_sign_in_at", "current_sign_in_ip", "last_sign_in_ip", "sign_in_count", "current_sign_in_token"]
  has_associated_audits

  belongs_to :sales_promotion_girl
  has_many :created_audits, dependent: :restrict_with_error, class_name: "Audit"
  has_many :user_menus, dependent: :destroy
  has_many :recipients, dependent: :destroy

  accepts_nested_attributes_for :user_menus, reject_if: proc{|attributes| attributes[:ability].blank? || attributes[:name].blank?}
  
  #  before_validation :prevent_system_creating_user
  validates :name, :gender, :role, presence: true, if: proc{|user| !user.creating_spg_user && !user.updating_spg_user}
    validates :username, presence: true
    validates :username, uniqueness: {case_sensitive: false}
    # Only allow letter, number, underscore and punctuation.
    validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
    validate :gender_available, :role_available, if: proc{|user| !user.creating_spg_user && !user.updating_spg_user}
      validates_confirmation_of :password, on: :update
      validate :sales_promotion_girl_available, if: proc{|user| user.creating_spg_user}
        validate :spg_not_changed, if: proc{|user| user.updating_spg_user}

          after_save :add_user_role, if: proc{|user| (user.role.present? && !user.updating_spg_user) || user.creating_spg_user}
            before_destroy :delete_tracks
  
            GENDERS = [
              ["Male", "male"],
              ["Female", "female"],
            ]
  
            NON_SPG_ROLES = [
              ["Administrator", "administrator"],
              ["Staff", "staff"],
              ["Manager", "manager"],
              ["Accountant", "accountant"]
            ]
    
            SPG_ROLES = [
              ["SPG", "spg"],
              ["Cashier", "cashier"],
              ["Supervisor", "supervisor"],
            ]
    
            ABILITIES = [
              ["Manage", 1],
              ["Read", 2],
              ["None", 0]
            ]
    
            MENUS = ["Brand", "Color", "Model", "Goods Type", "Region", "Vendor", "Product",
              "Size Group", "Sales Promotion Girl", "Area Manager", "Warehouse", "Purchase Order",
              "Receiving", "Stock Balance", "Purchase Return", "Cost & Price", "Email", "Account Payable",
              "Order Booking", "Courier", "Shipment", "Stock Mutation", "Goods In Transit", "Fiscal Reopening/Closing"]

            #  def name
            #    sales_promotion_girl.name    
            #  end
  
            # supaya user bisa update datanya tanpa harus memasukkan password
            def password_required?
              if new_record?
                super
              else
                false
              end
            end
  
            def has_managerial_role?
              has_role?(:manager) || has_role?(:administrator) || has_role?(:superadmin) 
            end
            
            def has_non_spg_role?
              has_role?(:staff) || has_role?(:manager) || has_role?(:administrator) || has_role?(:superadmin) || has_role?(:accountant)
            end

            private
                      
            def spg_not_changed
              errors.add(:base, "Sorry, you can't change existing SPG") if sales_promotion_girl_id_changed?
            end
    
            def sales_promotion_girl_available
              spg = SalesPromotionGirl.select(:id).where(id: sales_promotion_girl_id).first rescue nil
              errors.add(:base, "Selected SPG doesn't exist") if spg.nil? || spg.user.present?
            end
    
            def add_user_role
              unless creating_spg_user
                unless has_role? role.to_sym
                  roles.each do |role|
                    remove_role role.name.to_sym
                  end
    
                  if roles.blank?
                    add_role role.to_sym#, sales_promotion_girl
                  end
                end
              else
                unless has_role? sales_promotion_girl.role.to_sym
                  roles.each do |role|
                    remove_role role.name.to_sym
                  end
    
                  if roles.blank?
                    add_role sales_promotion_girl.role.to_sym#, sales_promotion_girl
                  end
                end
              end
            end
    
            def delete_tracks
              audits.destroy_all
            end
  
            def self.find_for_database_authentication warden_conditions
              conditions = warden_conditions.dup
              login = conditions.delete(:login)
              where(conditions).where(["(lower(username) = :value OR lower(email) = :value) AND active = :active_value", {value: login.strip.downcase, active_value: true}]).first
            end
  
            # method ini untuk membatalkan user object dari proses creating,
            # karena reject_if di spg model meloloskan user meskipun spg_role nya kosong atau spg
            #    def prevent_system_creating_user
            #      throw :abort if spg_role.blank? || spg_role.eql?("spg")
            #    end
    
            def gender_available
              GENDERS.select{ |x| x[1] == gender }.first.first
            rescue
              errors.add(:gender, "does not exist!") if gender.present?
            end
  
            def role_available
              begin
                NON_SPG_ROLES.select{ |x| x[1] == role }.first.first
              rescue
                errors.add(:role, "does not exist!") if role.present?
              end
            end

          end
