module Unleashed
  class ManualOrder < Base

    def self.all
        date = ((Time.now-15.minutes).utc).strftime('%F')
        options = { Page: 1, pageSize: 50, startDate: date, modifiedSince: date}
        endpoint = 'SalesOrders'
        params = options.dup
        # Handle Page option
        endpoint << "/#{params[:Page]}" if params[:Page].present?
        response = JSON.parse(@@client.get(endpoint, params).body)
        sales = response.key?('Items') ? response['Items'] : []
        sales.each do |quote|
          Hubspot::Deal.create_update_sales_deal(quote)
        end

        # sales.each do |sale|
        #   begin
        #     Hubspot::Ticket.create(sale,invoice,shipment,purchase_order,customer)
        #   rescue
        #      puts "resce"
        #   end
        # end
      # end
      # 
      # 

      # products.map { |attributes| Unleashed::Product.new(@client, attributes) }
    end
  end
end