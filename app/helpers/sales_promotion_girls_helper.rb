module SalesPromotionGirlsHelper
  def is_user_cant_change_role?
    return false 
#    if @sales_promotion_girl.new_record?
#    !(current_user.sales_promotion_girl.role.eql?("cashier") or
#        (current_user.sales_promotion_girl.role.eql?("supervisor") and
#          (@sales_promotion_girl.role.eql?("cashier") or @sales_promotion_girl.role.eql?("spg"))))
  end
  
  def user_roles
    roles = SalesPromotionGirl::ROLES.clone
#    if current_user.sales_promotion_girl and current_user.sales_promotion_girl.role.eql?("supervisor") and
#        (@sales_promotion_girl.role.eql?("cashier") or @sales_promotion_girl.role.eql?("spg") or
#          @sales_promotion_girl.new_record?)
#      roles.pop
#    end
#    roles
  end
end
