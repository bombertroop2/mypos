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
      can :manage, Notification
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
          elsif ability.eql?(:manage) && class_name.eql?("Shipment")
            # cegah non manager keatas untuk menghapus shipment
            alias_action :new, :create, :generate_ob_detail, to: :undelete_action
            can [:read, :undelete_action], class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Product") || class_name.eql?("Purchase Order")
            # cegah spg user untuk manage product
            can :read, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("CostList")
            # cegah spg user untuk manage Cost dan Price
            can :read, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Stock Mutation")
            if ability.eql?(:read)
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations], class_name.gsub(/\s+/, "").constantize
            else
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :new_store_to_warehouse_mutation, :create_store_to_warehouse_mutation, :generate_form, to: :manage_store_to_warehouse_mutation
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations, :manage_store_to_warehouse_mutation], class_name.gsub(/\s+/, "").constantize              
            end
          elsif ability
            can ability, class_name.gsub(/\s+/, "").constantize
          end        
        end        
      end
      can :manage, Notification
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
          elsif ability.eql?(:manage) && class_name.eql?("Shipment") && user.roles.first.name.eql?("staff")
            # cegah non manager keatas untuk menghapus shipment
            alias_action :new, :create, :generate_ob_detail, to: :undelete_action
            can [:read, :undelete_action], class_name.gsub(/\s+/, "").constantize
          elsif (class_name.eql?("Product") || class_name.eql?("Purchase Order")) && !user.has_managerial_role?
            # cegah staff untuk manage product
            can :read, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("CostList") && !user.has_managerial_role?
            # cegah staff untuk manage Cost dan Price
            can :read, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Shipment Receipt")
            # cegah staff dan manager untuk manage shipment receipt
            can :read, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Stock Mutation")
            if ability.eql?(:read)
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations], class_name.gsub(/\s+/, "").constantize
            else
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :new, :create, :get_products, :generate_form, to: :manage_store_to_store_mutation
              can [:read_store_to_store_mutations, :manage_store_to_store_mutation, :read_store_to_warehouse_mutations], class_name.gsub(/\s+/, "").constantize              
            end
          elsif ability
            can ability, class_name.gsub(/\s+/, "").constantize
          end        
        end        
      end
      can :manage, Notification unless user.new_record?
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
