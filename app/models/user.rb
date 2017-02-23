class User < ApplicationRecord
  rolify
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable
  
  attr_accessor :spg_role
       
  belongs_to :sales_promotion_girl
  
  before_validation :prevent_system_creating_user
  
  after_save :add_user_role
  
  # supaya user bisa update datanya tanpa harus memasukkan password
  def password_required?
    if new_record?
      super
    else
      false
    end
  end
  
  def add_user_role
    if spg_role.present?
      roles.each do |role|
        remove_role role.name.to_sym
      end
    
      if roles.blank?
        add_role spg_role.to_sym, sales_promotion_girl
      end
    end
  end
  
  private
  
  # method ini untuk membatalkan user object dari proses creating,
  # karena reject_if di spg model meloloskan user meskipun spg_role nya kosong atau spg
  def prevent_system_creating_user
    throw :abort if spg_role.blank? || spg_role.eql?("spg")
  end
end
