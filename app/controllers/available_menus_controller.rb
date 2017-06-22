class AvailableMenusController < ApplicationController
  load_and_authorize_resource except: :create

  # GET /available_menus/new
  def new
    @available_menus = []
    AvailableMenu::MENUS.each do |menu|
      available_menu = AvailableMenu.new name: menu, active: (AvailableMenu.select(:active).where(name: menu).first.active rescue true)
      @available_menus << available_menu
    end
  end

  # POST /available_menus
  # POST /available_menus.json
  def create
    invalid = false
    ActiveRecord::Base.transaction do
      array_index = 0
      params[:available_menus].each do |available_menu_index|
        AvailableMenu.destroy_all if array_index == 0
        available_menu = AvailableMenu.new(available_menu_params(params[:available_menus][available_menu_index]))
        authorize! :manage, available_menu
        unless available_menu.save
          invalid = true
          redirect_to new_available_menu_url, alert: 'Some of menus are invalid.'
          raise ActiveRecord::Rollback
        end
        array_index += 1
      end
    end
    
    redirect_to new_available_menu_url, notice: 'Available menus were successfully created.' unless invalid
  end

  private
  
  def available_menu_params(params)
    params.permit(:name, :active)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  #  def available_menu_params
  #    params.fetch(:available_menu, {})
  #  end
end
