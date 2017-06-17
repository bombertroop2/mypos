class User < ApplicationRecord
  rolify
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable
  
  attr_accessor :role, :login#:spg_role
       
  audited on: [:create, :update]
  has_associated_audits

  #  belongs_to :sales_promotion_girl
  has_many :user_menus, dependent: :destroy

  accepts_nested_attributes_for :user_menus, reject_if: proc{|attributes| attributes[:ability].blank? || attributes[:name].blank?}
  
  #  before_validation :prevent_system_creating_user
  validates :name, :gender, :role, :username, presence: true
  validates :username, uniqueness: {case_sensitive: false}
  # Only allow letter, number, underscore and punctuation.
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
  validate :gender_available, :role_available
  validates_confirmation_of :password, on: :update

  after_save :add_user_role, if: proc{|user| user.role.present?}
    before_destroy :delete_tracks
  
    GENDERS = [
      ["Male", "male"],
      ["Female", "female"],
    ]
  
    ROLES = [
      ["Staff", "staff"],
      ["Manager", "manager"],
      ["SPG", "spg"],
      ["Cashier", "cashier"],
      ["Supervisor", "supervisor"],
    ]
    
    ABILITIES = [
      ["Manage", 1],
      ["Read", 2],
      ["None", 0]
    ]
    
    MENUS = ["Brand", "Color", "Model", "Goods Type", "Region", "Price Code", "Vendor", "Product",
      "Size Group", "Sales Promotion Girl", "Area Manager", "Warehouse", "Purchase Order",
      "Receiving", "Stock Balance", "Purchase Return", "Cost & Price", "Email", "Account Payable",
      "Order Booking", "Courier", "Shipment"]

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
  
    def add_user_role
      unless has_role? role.to_sym
        roles.each do |role|
          remove_role role.name.to_sym
        end
    
        if roles.blank?
          add_role role.to_sym#, sales_promotion_girl
        end
      end
    end
  

    private
    
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
      ROLES.select{ |x| x[1] == role }.first.first
    rescue
      errors.add(:role, "does not exist!") if role.present?
    end

  end
