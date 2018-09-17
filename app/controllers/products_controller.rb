include SmartListing::Helper::ControllerExtensions
class ProductsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource except: :populate_detail_form
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    like_command = "ILIKE"
    products_scope = Product.joins(:brand, :vendor, :model, :goods_type).
      select("products.id, products.code, common_fields.name as brand_name, vendors.name as vendor_name, models_products.name as models_name, goods_types_products.name as goods_type_name")
    products_scope = products_scope.where(["products.code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(products_scope.where(["common_fields.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(products_scope.where(["vendors.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(products_scope.where(["models_products.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(products_scope.where(["goods_types_products.name #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @products = smart_listing_create(:products, products_scope, partial: 'products/listing', default_sort: {:"products.code" => "asc"})
  end

  # GET /products/1
  # GET /products/1.json
  def show
    @product_colors = @product.color_codes.pluck(:code).to_sentence
  end

  # GET /products/new
  def new
    @product = Product.new
    @product.cost_lists.build
    @colors = Color.select(:id, :code, :name).order(:code)
    @colors.each do |color|
      @product.product_colors.build color_id: color.id, code: color.code, name: color.name
    end
    if @colors.size == 0
      render js: "bootbox.alert({message: \"Please create color first\",size: 'small'});"
    elsif PriceCode.count(:id) == 0
      render js: "bootbox.alert({message: \"Please create price code first\",size: 'small'});"
    elsif SizeGroup.count(:id) == 0
      render js: "bootbox.alert({message: \"Please create size group first\",size: 'small'});"
    end
  end

  # GET /products/1/edit
  def edit
    #    @product.effective_date = @product.active_effective_date.strftime("%d/%m/%Y")
    @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size_order) : []
    @price_codes = PriceCode.select(:id, :code).order :code
    @colors = Color.select(:id, :code, :name).order(:code)
    @colors.each do |color|
      product_color = @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.first
      if product_color
        product_color.selected_color_id = color.id
        product_color.code = color.code
        product_color.name = color.name
      else
        @product.product_colors.build color_id: color.id, code: color.code, name: color.name
      end      
    end
  end

  # POST /products
  # POST /products.json
  def create
    add_additional_params_to_product_details(true)
    add_additional_params_to_price_lists("create")
    add_additional_param_to_cost_lists(true)
    convert_cost_price_to_numeric
    @product = Product.new(product_params)
    begin
      unless @product.save       
        size_group = SizeGroup.where(id: @product.size_group_id).select(:id).first
        @sizes = size_group ? size_group.sizes.select(:id, :size).order(:size_order) : []
        @price_codes = PriceCode.select(:id, :code).order :code
        @colors = Color.select(:id, :code, :name).order(:code)
        @colors.each do |color|
          @product.product_colors.build color_id: color.id, code: color.code, name: color.name unless @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.present?
        end
        render js: "bootbox.alert({message: \"#{@product.errors[:base].join("\\n")}\",size: 'small'});" if @product.errors[:base].present?        
      else
        @new_brand_name = Brand.select(:name).where(id: params[:product][:brand_id]).first.name
        @new_vendor_name = Vendor.select(:name).where(id: params[:product][:vendor_id]).first.name
        @new_model_name = Model.select(:name).where(id: params[:product][:model_id]).first.name
        @new_goods_type_name = GoodsType.select(:name).where(id: params[:product][:goods_type_id]).first.name
      end
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{products_url}'"
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    add_additional_params_to_product_details(false)
    add_additional_params_to_price_lists("update")
    add_additional_param_to_cost_lists(false)
    convert_cost_price_to_numeric
    begin        
      unless @product.update(product_params)
        if @product.errors[:"product_colors.base"].present?
          render js: "bootbox.alert({message: \"#{@product.errors[:"product_colors.base"].join("<br/>")}\",size: 'small'});"
        else
          @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size_order) : []
          @price_codes = PriceCode.select(:id, :code).order :code
          @colors = Color.select(:id, :code, :name).order(:code)
          @colors.each do |color|
            product_color = @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.first
            if product_color
              product_color.selected_color_id = color.id
              product_color.code = color.code
              product_color.name = color.name
            else
              @product.product_colors.build color_id: color.id, code: color.code, name: color.name
            end      
          end
        end
      else
        @new_brand_name = Brand.select(:name).where(id: params[:product][:brand_id]).first.name
        @new_vendor_name = Vendor.select(:name).where(id: params[:product][:vendor_id]).first.name
        @new_model_name = Model.select(:name).where(id: params[:product][:model_id]).first.name
        @new_goods_type_name = GoodsType.select(:name).where(id: params[:product][:goods_type_id]).first.name
      end
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{products_url}'"
    rescue ActiveRecord::RecordNotDestroyed => e
      render js: "bootbox.alert({message: \"Sorry, you can't change colors!\",size: 'small'});"
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy    
    @product.destroy    
    if @product.errors.present? and @product.errors.messages[:base].present?
      error_message = @product.errors.messages[:base].to_sentence
      error_message.slice! "products "
      flash[:alert] = error_message
      render js: "window.location = '#{products_url}'"
    end
  end
  
  def populate_detail_form
    @price_codes = PriceCode.select(:id, :code).order :code
    unless params[:product_id].present?
      @product = Product.new
      sg = SizeGroup.where(id: params[:id]).select(:id).first
      @sizes = sg.sizes.select(:id, :size).order(:size_order) if sg
      @price_codes.each do |price_code|
        @sizes.each do |size|
          product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id)
          product_detail.price_lists.build
        end
      end
    else
      @product = Product.where(id: params[:product_id]).select(:id, :size_group_id).first
      @product.size_group_id = params[:id]
      unless @product.size_group_id_changed?
        @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size_order) : []
      else        
        sg = SizeGroup.where(id: params[:id]).select(:id).first
        @sizes = sg.sizes.select(:id, :size).order(:size_order) if sg
        #        @price_codes.each do |price_code|
        #          @sizes.each do |size|
        #            product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id)
        #            product_detail.price_lists.build
        #          end
        #        end
      end
    end
    
    respond_to { |format| format.js }
  end
  
  def import
    if request.post?
      spreadsheet = Roo::Spreadsheet.open(params[:file].path)
      current_date = Date.current
      products = []
      error_message = ""
      added_spreadsheet_barcodes = []
      barcode = ""
      (3..spreadsheet.last_row).each do |i|
        product_code = spreadsheet.row(i)[0].strip rescue nil
        if product_code.blank?
          error_message = "Error for row (##{i}) : Article code cannot be empty"
          break
        end
        brand_code = spreadsheet.row(i)[2].strip rescue nil
        if brand_code.blank?
          error_message = "Error for row (##{i}) : Brand code cannot be empty"
          break
        end
        sex = spreadsheet.row(i)[3].strip.downcase rescue nil
        if sex.blank?
          error_message = "Error for row (##{i}) : Sex cannot be empty"
          break
        end
        vendor_code = spreadsheet.row(i)[4].strip rescue nil
        if vendor_code.blank?
          error_message = "Error for row (##{i}) : Vendor code cannot be empty"
          break
        end
        target = spreadsheet.row(i)[5].strip.downcase rescue nil
        if target.blank?
          error_message = "Error for row (##{i}) : Target cannot be empty"
          break
        end
        model_code = spreadsheet.row(i)[6].strip rescue nil
        if model_code.blank?
          error_message = "Error for row (##{i}) : Model code cannot be empty"
          break
        end
        goods_type_code = spreadsheet.row(i)[7].strip rescue nil
        if goods_type_code.blank?
          error_message = "Error for row (##{i}) : Goods type code cannot be empty"
          break
        end
        size_group_code = spreadsheet.row(i)[8].strip rescue nil
        if size_group_code.blank?
          error_message = "Error for row (##{i}) : Size group code cannot be empty"
          break
        end
        additional_information = spreadsheet.row(i)[9].strip.upcase rescue nil
        prdct = products.select{|p| p.code.eql?(product_code)}.first
        if prdct.blank?
          brand_id = Brand.where(code: brand_code).pluck(:id).first
          if brand_id.blank?
            error_message = "Error for row (##{i}) : Brand #{brand_code} doesn't exist"
            break
          end
          vendor_id = Vendor.where(code: vendor_code).pluck(:id).first
          if vendor_id.blank?
            error_message = "Error for row (##{i}) : Vendor #{vendor_code} doesn't exist"
            break
          end
          model_id = Model.where(code: model_code).pluck(:id).first
          if model_id.blank?
            error_message = "Error for row (##{i}) : Model #{model_code} doesn't exist"
            break
          end
          goods_type_id = GoodsType.where(code: goods_type_code).pluck(:id).first
          if goods_type_id.blank?
            error_message = "Error for row (##{i}) : Goods type #{goods_type_code} doesn't exist"
            break
          end
          size_group_id = SizeGroup.where(code: size_group_code).pluck(:id).first
          if size_group_id.blank?
            error_message = "Error for row (##{i}) : Size group #{size_group_code} doesn't exist"
            break
          end
          size_id = Size.joins(:size_group).where(size: spreadsheet.row(i)[11].strip).where(["size_groups.id = ?", size_group_id]).pluck(:id).first
          if size_id.blank?
            error_message = "Error for row (##{i}) : Size #{spreadsheet.row(i)[11].strip} doesn't exist"
            break
          end
          price_code_id = PriceCode.where(code: spreadsheet.row(i)[12].strip).pluck(:id).first
          if price_code_id.blank?
            error_message = "Error for row (##{i}) : Price code #{spreadsheet.row(i)[12].strip} doesn't exist"
            break
          end
          color_id = Color.where(code: spreadsheet.row(i)[14].strip).pluck(:id).first
          if color_id.blank?
            error_message = "Error for row (##{i}) : Color #{spreadsheet.row(i)[14].strip} doesn't exist"
            break
          end
          sex = if sex == "NULL"
            nil
          elsif sex == "Ledies"
            "Ladies"
          else
            sex
          end
          product = Product.new code: product_code, description: spreadsheet.row(i)[1], brand_id: brand_id, sex: sex, vendor_id: vendor_id, target: target, model_id: model_id, goods_type_id: goods_type_id, size_group_id: size_group_id, additional_information: additional_information, attr_importing_data_via_web: true
          product_detail = product.product_details.build size_id: size_id, price_code_id: price_code_id, size_group_id: size_group_id, attr_importing_data: true, user_is_adding_new_product: true
          product_detail.price_lists.build effective_date: current_date, price: spreadsheet.row(i)[10].to_f, user_is_adding_new_price: true, attr_importing_data: true
          product.cost_lists.build effective_date: current_date, cost: spreadsheet.row(i)[13].to_f, is_user_creating_product: true
          product_color = product.product_colors.build color_id: color_id, attr_importing_data: true
          if added_spreadsheet_barcodes.select{|ab| (ab[:product_code] != product_code || ab[:size_id] != size_id || ab[:color_id] != color_id) && ab[:barcode] == spreadsheet.row(i)[17].strip}.blank?
            product_color.product_barcodes.build size_id: size_id, barcode: spreadsheet.row(i)[17].strip
            added_spreadsheet_barcodes << {product_code: product_code, size_id: size_id, color_id: color_id, barcode: spreadsheet.row(i)[17].strip}
          else
            if barcode.blank?                        
              prb = ProductBarcode.where(["barcode LIKE ?", "1S%"]).select(:barcode).order("barcode DESC").first
              barcode = if prb.present?
                "1S#{prb.barcode.split("1S")[1].succ}"
              else
                "1S00001"
              end
            else
              barcode = "1S#{barcode.split("1S")[1].succ}"
            end
            product_color.product_barcodes.build size_id: size_id, barcode: barcode
          end
          products << product
        else
          size_id = Size.joins(:size_group).where(size: spreadsheet.row(i)[11].strip).where(["size_groups.id = ?", prdct.size_group_id]).pluck(:id).first
          if size_id.blank?
            error_message = "Error for row (##{i}) : Size #{spreadsheet.row(i)[11].strip} doesn't exist"
            break
          end
          price_code_id = PriceCode.where(code: spreadsheet.row(i)[12].strip).pluck(:id).first
          if price_code_id.blank?
            error_message = "Error for row (##{i}) : Price code #{spreadsheet.row(i)[12].strip} doesn't exist"
            break
          end
          product_detail = prdct.product_details.select{|pd| pd.size_id == size_id && pd.price_code_id == price_code_id}.first
          if product_detail.blank?
            product_detail = prdct.product_details.build size_id: size_id, price_code_id: price_code_id, size_group_id: prdct.size_group_id, attr_importing_data: true, user_is_adding_new_product: true
            product_detail.price_lists.build effective_date: current_date, price: spreadsheet.row(i)[10].to_f, user_is_adding_new_price: true, attr_importing_data: true
          end
          color_id = Color.where(code: spreadsheet.row(i)[14].strip).pluck(:id).first
          product_color = prdct.product_colors.select{|pc| pc.color_id == color_id}.first
          if product_color.blank?
            product_color = prdct.product_colors.build color_id: color_id, attr_importing_data: true
            if added_spreadsheet_barcodes.select{|ab| (ab[:product_code] != product_code || ab[:size_id] != size_id || ab[:color_id] != color_id) && ab[:barcode] == spreadsheet.row(i)[17].strip}.blank?
              product_color.product_barcodes.build size_id: size_id, barcode: spreadsheet.row(i)[17].strip
              added_spreadsheet_barcodes << {product_code: product_code, size_id: size_id, color_id: color_id, barcode: spreadsheet.row(i)[17].strip}
            else
              if barcode.blank?                        
                prb = ProductBarcode.where(["barcode LIKE ?", "1S%"]).select(:barcode).order("barcode DESC").first
                barcode = if prb.present?
                  "1S#{prb.barcode.split("1S")[1].succ}"
                else
                  "1S00001"
                end
              else
                barcode = "1S#{barcode.split("1S")[1].succ}"
              end
              product_color.product_barcodes.build size_id: size_id, barcode: barcode
            end
          else
            product_barcode = product_color.product_barcodes.select{|pb| pb.size_id == size_id}.first
            if product_barcode.blank?
              if added_spreadsheet_barcodes.select{|ab| (ab[:product_code] != product_code || ab[:size_id] != size_id || ab[:color_id] != color_id) && ab[:barcode] == spreadsheet.row(i)[17].strip}.blank?
                product_color.product_barcodes.build size_id: size_id, barcode: spreadsheet.row(i)[17].strip
                added_spreadsheet_barcodes << {product_code: product_code, size_id: size_id, color_id: color_id, barcode: spreadsheet.row(i)[17].strip}
              else
                if barcode.blank?                        
                  prb = ProductBarcode.where(["barcode LIKE ?", "1S%"]).select(:barcode).order("barcode DESC").first
                  barcode = if prb.present?
                    "1S#{prb.barcode.split("1S")[1].succ}"
                  else
                    "1S00001"
                  end
                else
                  barcode = "1S#{barcode.split("1S")[1].succ}"
                end
                product_color.product_barcodes.build size_id: size_id, barcode: barcode
              end
            end
          end
        end
      end
      if error_message.present?
        render js: "bootbox.alert({message: \"#{error_message}\",size: 'small'});"
      else
        valid = true
        ActiveRecord::Base.transaction do
          products.each do |pr|
            begin
              product_price_codes = []
              pr.product_details.each do |pd|
                product_price_codes << pd.price_code_id
              end
              if valid
                SizeGroup.select(:id).where(id: pr.size_group_id).first.sizes.select(:id).each do |size|
                  product_price_codes.uniq.each do |ppc|
                    if pr.product_details.select{|pd| pd.price_code_id == ppc && pd.size_id == size.id}.blank?
                      existed_product_detail = pr.product_details.select{|pd| pd.price_code_id == ppc}.first
                      other_size_price = existed_product_detail.price_lists.last.price
                      product_detail = pr.product_details.build size_id: size.id, price_code_id: ppc, size_group_id: pr.size_group_id, attr_importing_data: true, user_is_adding_new_product: true
                      product_detail.price_lists.build effective_date: current_date, price: other_size_price, user_is_adding_new_price: true, attr_importing_data: true
                    end
                  end
                  pr.product_colors.each do |pc|
                    if pc.product_barcodes.select{|pb| pb.size_id == size.id}.blank?
                      if barcode.blank?                        
                        prb = ProductBarcode.where(["barcode LIKE ?", "1S%"]).select(:barcode).order("barcode DESC").first
                        barcode = if prb.present?
                          "1S#{prb.barcode.split("1S")[1].succ}"
                        else
                          "1S00001"
                        end
                      else
                        barcode = "1S#{barcode.split("1S")[1].succ}"
                      end
                      pc.product_barcodes.build size_id: size.id, barcode: barcode
                    end
                  end
                end
                unless valid = pr.save
                  message = pr.errors.full_messages.map{|error| "#{error}<br/>"}.join
                  error_message = message
                  raise ActiveRecord::Rollback
                end
              else
                raise ActiveRecord::Rollback
              end
            rescue ActiveRecord::RecordNotUnique => e
              valid = false
              error_message = "Article code #{pr.code} has already been taken"
              raise ActiveRecord::Rollback
            rescue RuntimeError => e
              valid = false
              error_message = e.message
              raise ActiveRecord::Rollback
            end
          end
        end
        if valid
          render js: "bootbox.alert({message: \"Articles were successfully imported\",size: 'small'});"
        else
          render js: "bootbox.alert({message: \"#{error_message}\",size: 'small'});"
        end
      end
    end
  end
  
  private
  
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.joins(:brand, :vendor, :model, :goods_type).
      where(id: params[:id]).
      select("products.id, products.code, products.description, common_fields.name AS brand_name, vendors.code AS vendor_code, models_products.code AS model_code, goods_types_products.code AS goods_type_code, image, sex, target, size_group_id, brand_id, vendor_id, model_id, goods_type_id, products.additional_information").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    pl_attributes = if action_name.eql?("create")
      [:id, :price, :user_is_adding_new_price, :cost, :product_id, :attr_product_additional_information]
    else
      [:id, :price, :user_is_adding_new_price, :cost, :product_id]
    end
    
    params.require(:product).permit(:code, :description, :brand_id, :sex, :vendor_id,
      :target, :model_id,# :effective_date,
      :goods_type_id, :image, :image_cache, :remove_image, :size_group_id, :additional_information,
      product_details_attributes: [:id, :size_id, :price_code_id, :price, :user_is_adding_new_product, :size_group_id,
        price_lists_attributes: pl_attributes],
      cost_lists_attributes: [:id, :cost, :is_user_creating_product],
      product_colors_attributes: [:id, :selected_color_id, :color_id, :code, :name, :_destroy]
    )
  end
  

  def convert_cost_price_to_numeric
    params[:product][:cost_lists_attributes].each do |key, value|
      params[:product][:cost_lists_attributes][key][:cost] = params[:product][:cost_lists_attributes][key][:cost].gsub("Rp","").gsub(".","").gsub(",",".") if params[:product][:cost_lists_attributes][key][:cost].present?
    end if params[:product][:cost_lists_attributes].present?
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key][:price_lists_attributes].each do |price_lists_key, value|
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:price] = params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:price].gsub("Rp","").gsub(".","").gsub(",",".")
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:cost] = params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:cost].gsub("Rp","").gsub(".","").gsub(",",".")
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:product_id] = @product.id if @product.present? && !@product.new_record?
      end if params[:product][:product_details_attributes][key][:price_lists_attributes].present?
    end if params[:product][:product_details_attributes].present?
  end
  
  def add_additional_params_to_product_details(status)
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key].merge! size_group_id: params[:product][:size_group_id], user_is_adding_new_product: status
    end if params[:product][:product_details_attributes].present?
  end
   
  def add_additional_params_to_price_lists(action)
    # ambil cost
    cost = ""
    params[:product][:cost_lists_attributes].each do |key, value|
      cost = params[:product][:cost_lists_attributes][key][:cost]
    end if params[:product][:cost_lists_attributes].present?
    
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key][:price_lists_attributes].each do |price_lists_key, value|
        if action.eql?("create")
          params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].merge! user_is_adding_new_price: true
        else
          if params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:id].present?
            params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].merge! user_is_adding_new_price: false
          else
            params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].merge! user_is_adding_new_price: true
          end
        end
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:cost] = cost
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].merge! attr_product_additional_information: params[:product][:additional_information]
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:product_id] = params[:id] if action.eql?("update")
      end if params[:product][:product_details_attributes][key][:price_lists_attributes].present?
    end if params[:product][:product_details_attributes].present?
  end
  
  def add_additional_param_to_cost_lists(status)
    params[:product][:cost_lists_attributes].each do |key, value|
      params[:product][:cost_lists_attributes][key].merge! is_user_creating_product: status
    end if params[:product][:cost_lists_attributes].present?
  end
end
