module Unleashed
  class Product < Base
    def self.get_product(product_codes)

      options = { productCode: product_codes, Page: 1, pageSize: 1}
      endpoint = "Products"
      params = options.dup
      # Handle Page option

      endpoint << "/#{params[:Page]}" if params[:Page].present?
      response = JSON.parse(@@client.get(endpoint, params).body) rescue nil
      products = response.key?('Items') ? response['Items'] : [] rescue nil
    end
    
    
  end
end