module ProductsHelper
  def selected_size_group
    return params[:size_groups] if params[:size_groups]
    return @product.sizes.first.size_group.id if @product.sizes.first
  end
end
