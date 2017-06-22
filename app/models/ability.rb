class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    if user.has_role? :superadmin
      can :manage, :all
    elsif user.has_role? :administrator
      (User::MENUS.clone << "User").each do |user_menu|
        if user_menu.eql?("User") || AvailableMenu.select("1 AS one").where(active: true, name: user_menu).present?
          class_name = if user_menu.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.eql?("Stock Balance")
            "Stock"
          elsif user_menu.eql?("Cost & Price")
            "CostList"
          elsif user_menu.eql?("Receiving")
            "ReceivedPurchaseOrder"
          else
            user_menu
          end
          can :manage, class_name.gsub(/\s+/, "").constantize
        end
      end
    elsif user.roles.first.present? && SalesPromotionGirl::ROLES.select{|a, b| b.eql?(user.roles.first.name)}.present?
      user.user_menus.each do |user_menu|
        if user_menu.ability != 0 && AvailableMenu.select("1 AS one").where(active: true, name: user_menu.name).present?
          ability = User::ABILITIES.select{|name, value| value == user_menu.ability}.first.first.downcase.to_sym rescue nil
          class_name = if user_menu.name.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.name.eql?("Stock Balance")
            "Stock"
          elsif user_menu.name.eql?("Cost & Price")
            "CostList"
          elsif user_menu.name.eql?("Receiving")
            "ReceivedPurchaseOrder"
          else
            user_menu.name
          end
          if ability && class_name.eql?("Supervisor")
            can ability, class_name.gsub(/\s+/, "").constantize
            can :get_warehouses, class_name.gsub(/\s+/, "").constantize
          elsif ability && class_name.eql?("Sales Promotion Girl")
            can :read, class_name.gsub(/\s+/, "").constantize
          elsif ability
            can ability, class_name.gsub(/\s+/, "").constantize
          end        
        end        
      end
    else
      user.user_menus.each do |user_menu|
        if user_menu.ability != 0 && AvailableMenu.select("1 AS one").where(active: true, name: user_menu.name).present?
          ability = User::ABILITIES.select{|name, value| value == user_menu.ability}.first.first.downcase.to_sym rescue nil
          class_name = if user_menu.name.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.name.eql?("Stock Balance")
            "Stock"
          elsif user_menu.name.eql?("Cost & Price")
            "CostList"
          elsif user_menu.name.eql?("Receiving")
            "ReceivedPurchaseOrder"
          else
            user_menu.name
          end
          if ability && class_name.eql?("Supervisor")
            can ability, class_name.gsub(/\s+/, "").constantize
            can :get_warehouses, class_name.gsub(/\s+/, "").constantize
          elsif ability
            can ability, class_name.gsub(/\s+/, "").constantize
          end        
        end        
      end
    end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
