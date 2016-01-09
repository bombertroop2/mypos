class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable
  
  attr_accessor :spg_role
       
  belongs_to :sales_promotion_girl
  
  after_save :add_user_role
  
  def add_user_role
    add_role spg_role.to_sym if spg_role.present?
  end
end
