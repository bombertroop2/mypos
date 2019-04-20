class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    user ||= User.new # guest user (not logged in)
    user_roles = user.roles.pluck :name
    if user_roles.include? "superadmin"
      can :manage, :all
      cannot :manage, CashierOpening
      cannot :manage, CashDisbursement
      cannot :manage, Sale
      can [:read, :export], Sale
      cannot :manage, SalesReturn
      cannot [:approve, :unapprove], ConsignmentSale
      can :read, SalesReturn
    elsif user_roles.include? "administrator"
      available_menus = AvailableMenu.where(active: true).pluck(:name)
      (User::MENUS.clone << "User").each do |user_menu|
        if user_menu.eql?("User") || available_menus.include?(user_menu)
          class_name = if user_menu.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.eql?("Stock Balance")
            "Stock"
          elsif user_menu.eql?("Cost & Price")
            "CostList"
          elsif user_menu.eql?("Receiving")
            "ReceivedPurchaseOrder"
          elsif user_menu.eql?("Fiscal Reopening/Closing")
            "FiscalYear"
          elsif user_menu.eql?("Listing Stocks")
            "ListingStock"
          elsif user_menu.eql?("Bank Master")
            "Bank"
          elsif user_menu.eql?("Consignment")
            "ConsignmentSale"
          elsif user_menu.eql?("Pie Chart of Qty Sold")
            "QuantitySoldChart"
          elsif user_menu.eql?("Sell Thru Report")
            "SellThru"
          elsif user_menu.eql?("Print Barcode")
            "PrintBarcodeTemp"
          else
            user_menu
          end
          if class_name.eql?("Goods In Transit")
            can :manage, Shipment
            can :manage, StockMutation
          elsif class_name.eql?("Event")
            can :manage, Event
            can :manage, CounterEvent
          elsif class_name.eql?("ConsignmentSale")
            can :manage, ConsignmentSale
            cannot [:approve, :unapprove], ConsignmentSale
          else
            if user_menu.eql?("Account Payable (Vendor)")
              can :manage, AccountPayable
              can :manage, AccountPayablePayment
            elsif user_menu.eql?("Account Payable (Courier)")
              can :manage, AccountPayableCourier
              can :manage, AccountPayableCourierPayment
            elsif user_menu.eql?("Accounts Receivable (Direct Sales)")
              can :manage, AccountsReceivableInvoice
              can :manage, AccountsReceivablePayment
            else
              if user_menu.eql?("Point of Sale")
                can [:read, :export], Sale
                can :read, SalesReturn
              elsif !user_menu.eql?("Company")
                can :manage, class_name.gsub(/\s+/, "").constantize
              end
            end
          end
        end
      end
      can :manage, Notification
    elsif user_roles.first.present? && SalesPromotionGirl::ROLES.select{|a, b| b.eql?(user_roles.first)}.present?
      available_menus = AvailableMenu.where(active: true).pluck(:name)
      user.user_menus.each do |user_menu|
        if user_menu.ability != 0 && available_menus.include?(user_menu.name) && !user_menu.name.eql?("Account Payable (Vendor)") && !user_menu.name.eql?("Fiscal Reopening/Closing") && !user_menu.name.eql?("Account Payable (Courier)") && !user_menu.name.eql?("Packing List") && !user_menu.name.eql?("General Variable") && !user_menu.name.eql?("Target") && !user_menu.name.eql?("Accounts Receivable (Direct Sales)") && !user_menu.name.eql?("Print Barcode")
          ability = User::ABILITIES.select{|name, value| value == user_menu.ability}.first.first.downcase.to_sym rescue nil
          class_name = if user_menu.name.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.name.eql?("Stock Balance")
            "Stock"
          elsif user_menu.name.eql?("Cost & Price")
            "CostList"
          elsif user_menu.name.eql?("Receiving")
            "ReceivedPurchaseOrder"
          elsif user_menu.name.eql?("Listing Stocks")
            "ListingStock"
          elsif user_menu.name.eql?("Bank Master")
            "Bank"
          else
            user_menu.name
          end
          if class_name.eql?("Supervisor") || class_name.eql?("Warehouse") ||
              class_name.eql?("Region") || class_name.eql?("ReceivedPurchaseOrder") ||
              class_name.eql?("Purchase Order") || class_name.eql?("Vendor") ||
              class_name.eql?("Purchase Return") ||
              class_name.eql?("Courier") || class_name.eql?("Event") ||
              class_name.eql?("Email") || class_name.eql?("Bank") ||
              class_name.eql?("Growth Report") || class_name.eql?("Pie Chart of Qty Sold") ||
              class_name.eql?("Sell Thru Report") || class_name.eql?("Adjustment") ||
              class_name.eql?("Company")
            #            can :read, class_name.gsub(/\s+/, "").constantize
            #            can :get_warehouses, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Shipment")
            # cegah non manager keatas untuk menghapus shipment
            alias_action :inventory_receipts, :show, :index, to: :read_action
            can :read_action, class_name.gsub(/\s+/, "").constantize
            can [:receive, :search_do], class_name.gsub(/\s+/, "").constantize if ability.eql?(:manage)
          elsif class_name.eql?("Stock Mutation")
            if ability.eql?(:read)
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :store_to_store_inventory_receipts, :show_store_to_store_receipt, to: :read_store_to_store_inventory_receipts
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations, :read_store_to_store_inventory_receipts], class_name.gsub(/\s+/, "").constantize
            else
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :new_store_to_warehouse_mutation,
                :create_store_to_warehouse_mutation, :generate_form, :edit_store_to_warehouse,
                :update_store_to_warehouse, :delete_store_to_warehouse, :get_products, :print_return_doc, to: :manage_store_to_warehouse_mutation
              alias_action :store_to_store_inventory_receipts, :show_store_to_store_receipt, to: :read_store_to_store_inventory_receipts
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations, :manage_store_to_warehouse_mutation, :approve, :receive, :read_store_to_store_inventory_receipts, :search], class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Goods In Transit")
            alias_action :shipment_goods, :show_shipment_goods, to: :read_shipment_goods
            alias_action :mutation_goods, :returned_goods, :show_mutation_goods, :show_returned_goods, to: :read_mutation_goods
            can :read_shipment_goods, Shipment
            can :read_mutation_goods, StockMutation
          elsif user_menu.name.eql?("Point of Sale")
            showroom_present = Warehouse.joins(:sales_promotion_girls).select("1 AS one").where(is_active: true, warehouse_type: "showroom", :"sales_promotion_girls.id" => user.sales_promotion_girl_id).present? unless user.new_record?
            if user_roles.include?("cashier") && !user.new_record? && showroom_present
              can ability, CashierOpening
              can ability, CashDisbursement
              can ability, Sale
              can ability, SalesReturn
            end
          elsif user_menu.name.eql?("Consignment")
            counter_present = Warehouse.joins(:sales_promotion_girls).counter.select("1 AS one").where(is_active: true, :"sales_promotion_girls.id" => user.sales_promotion_girl_id).present? unless user.new_record?
            if counter_present
              can ability, ConsignmentSale
            end
          elsif class_name.eql?("Member")
            can :read, Member
          else
            can :read, class_name.gsub(/\s+/, "").constantize
          end
        end
      end
      can :manage, Notification
    else
      available_menus = AvailableMenu.where(active: true).pluck(:name)
      user.user_menus.each do |user_menu|
        if user_menu.ability != 0 && available_menus.include?(user_menu.name)
          ability = User::ABILITIES.select{|name, value| value == user_menu.ability}.first.first.downcase.to_sym rescue nil
          class_name = if user_menu.name.eql?("Area Manager")
            "Supervisor"
          elsif user_menu.name.eql?("Stock Balance")
            "Stock"
          elsif user_menu.name.eql?("Cost & Price")
            "CostList"
          elsif user_menu.name.eql?("Receiving")
            "ReceivedPurchaseOrder"
          elsif user_menu.name.eql?("Fiscal Reopening/Closing")
            "FiscalYear"
          elsif user_menu.name.eql?("Listing Stocks")
            "ListingStock"
          elsif user_menu.name.eql?("Bank Master")
            "Bank"
          elsif user_menu.name.eql?("Consignment")
            "ConsignmentSale"
          elsif user_menu.name.eql?("Pie Chart of Qty Sold")
            "QuantitySoldChart"
          elsif user_menu.name.eql?("Sell Thru Report")
            "SellThru"
          elsif user_menu.name.eql?("Print Barcode")
            "PrintBarcodeTemp"
          else
            user_menu.name
          end
          if ability && class_name.eql?("Supervisor") && !user_roles.include?("area_manager")
            unless user_roles.include?("accountant")
              can ability, class_name.gsub(/\s+/, "").constantize
              can :get_warehouses, class_name.gsub(/\s+/, "").constantize
            else
              can :read, class_name.gsub(/\s+/, "").constantize
              can :get_warehouses, class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Event")
            if !user_roles.include?("area_manager")
              if user_roles.include?("accountant")
                unless ability.eql?(:none)
                  can :read, Event
                  can :read, CounterEvent
                end
              else
                unless ability.eql?(:none)
                  can ability, Event
                  can ability, CounterEvent
                end
              end
            end
          elsif class_name.eql?("Shipment") && !user_roles.include?("area_manager")
            # cegah non manager keatas untuk menghapus shipment
            alias_action :new, :create, :generate_ob_detail, :print, :change_receive_date, to: :undelete_action
            alias_action :index, :inventory_receipts, :show, :direct_sales, :show_direct_sale, to: :read_action_for_staff
            alias_action :edit, :update, :destroy, to: :edit_action
            if ability.eql?(:manage) && user_roles.first.eql?("staff")
              can [:read_action_for_staff, :undelete_action], class_name.gsub(/\s+/, "").constantize
            elsif user_roles.first.eql?("staff") || user_roles.include?("accountant")
              can :read_action_for_staff, class_name.gsub(/\s+/, "").constantize
            elsif ability.eql?(:read) && user_roles.first.eql?("manager")
              can :read_action_for_staff, class_name.gsub(/\s+/, "").constantize
            elsif user_roles.first.eql?("manager")
              can [:read_action_for_staff, :undelete_action, :edit_action], class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Purchase Order")
            if !user_roles.include?("area_manager") && !user_roles.include?("accountant")
              can ability, class_name.gsub(/\s+/, "").constantize
            elsif user_roles.include?("accountant")
              can :read, class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("CostList")            
            if !user_roles.include?("area_manager") && !user_roles.include?("accountant")
              can ability, class_name.gsub(/\s+/, "").constantize
            else
              can :read, class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Stock Mutation") && !user_roles.include?("area_manager")
            if ability.eql?(:read) || user_roles.include?("accountant")
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :store_to_store_inventory_receipts, :show_store_to_store_receipt, to: :read_store_to_store_inventory_receipts
              alias_action :store_to_warehouse_inventory_receipts, :show_store_to_warehouse_receipt, to: :read_store_to_warehouse_inventory_receipts
              can [:read_store_to_store_mutations, :read_store_to_warehouse_mutations, :read_store_to_store_inventory_receipts, :read_store_to_warehouse_inventory_receipts], class_name.gsub(/\s+/, "").constantize
            else
              alias_action :index, :show, to: :read_store_to_store_mutations
              alias_action :index_store_to_warehouse_mutation, :show_store_to_warehouse_mutation, to: :read_store_to_warehouse_mutations
              alias_action :new, :create, :get_products, :generate_form, :edit, :update, :destroy, :print_rolling_doc, :change_receive_date, to: :manage_store_to_store_mutation
              alias_action :store_to_store_inventory_receipts, :show_store_to_store_receipt, to: :read_store_to_store_inventory_receipts
              alias_action :store_to_warehouse_inventory_receipts, :show_store_to_warehouse_receipt, to: :read_store_to_warehouse_inventory_receipts
              can [:read_store_to_store_mutations, :manage_store_to_store_mutation, :read_store_to_warehouse_mutations, :read_store_to_store_inventory_receipts, :read_store_to_warehouse_inventory_receipts, :receive_to_warehouse], class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Goods In Transit")
            alias_action :shipment_goods, :show_shipment_goods, to: :read_shipment_goods
            alias_action :mutation_goods, :returned_goods, :show_mutation_goods, :show_returned_goods, to: :read_mutation_goods
            can :read_shipment_goods, Shipment
            can :read_mutation_goods, StockMutation
          elsif class_name.eql?("Account Payable (Vendor)")
            if user_roles.include?("staff")
              can :read, AccountPayable
              can :read, AccountPayablePayment
            elsif !user_roles.include?("area_manager")
              can ability, AccountPayable
              if user_roles.include?("accountant")
                can ability, AccountPayablePayment
              else
                can :read, AccountPayablePayment
              end
            end
          elsif class_name.eql?("Account Payable (Courier)")
            if user_roles.include?("staff")
              can :read, AccountPayableCourier
              can :read, AccountPayableCourierPayment
            elsif !user_roles.include?("area_manager")
              can ability, AccountPayableCourier
              if user_roles.include?("accountant")
                can ability, AccountPayableCourierPayment
              else
                can :read, AccountPayableCourierPayment
              end
            end
          elsif class_name.eql?("Accounts Receivable (Direct Sales)")
            if user_roles.include?("staff")
              can :read, AccountsReceivableInvoice
              can :read, AccountsReceivablePayment
            elsif !user_roles.include?("area_manager")
              can ability, AccountsReceivableInvoice
              if user_roles.include?("accountant")
                can ability, AccountsReceivablePayment
              else
                can :read, AccountsReceivablePayment
              end
            end
          elsif class_name.eql?("FiscalYear") && !user_roles.include?("area_manager")
            if user_roles.include?("staff")
              can :read, FiscalYear
            else
              can ability, FiscalYear
            end
          elsif class_name.eql?("Company") || class_name.eql?("Adjustment") || class_name.eql?("General Variable")
          elsif class_name.eql?("ConsignmentSale")
            if user_roles.include?("area_manager") && user.supervisor.warehouses.select("1 AS one").where(["warehouses.warehouse_type LIKE 'ctr%' AND warehouses.is_active = ?", true]).present?
              can ability, ConsignmentSale
            end
          elsif class_name.eql?("Member")
            if user_roles.include?("area_manager") || user_roles.include?("accountant")
              can :read, Member
            else
              can ability, Member
            end
          elsif class_name.eql?("Stock") && user_roles.include?("area_manager")
            can ability, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("Stock Movement") && user_roles.include?("area_manager")
            can ability, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("ListingStock") && user_roles.include?("area_manager")
            can ability, class_name.gsub(/\s+/, "").constantize
          elsif class_name.eql?("PackingList")
            if !user_roles.include?("area_manager")
              can ability, class_name.gsub(/\s+/, "").constantize
            else
              can :read, class_name.gsub(/\s+/, "").constantize
            end
          elsif class_name.eql?("Point of Sale")
            can [:read, :export], Sale
            can :read, CashDisbursement
            can :read, SalesReturn
          elsif class_name.eql?("ReceivedPurchaseOrder")
            if !user_roles.include?("area_manager")
              if ability.eql?(:read)
                can [:read, :goods_received_not_invoiced], class_name.constantize
              else
                can ability, class_name.constantize
              end
            end
          elsif class_name.eql?("PrintBarcodeTemp")
            can ability, class_name.constantize
          elsif ability && !user_roles.include?("accountant") && !user_roles.include?("area_manager")
            can ability, class_name.gsub(/\s+/, "").constantize
          elsif ability && user_roles.include?("accountant")
            can :read, class_name.gsub(/\s+/, "").constantize
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
