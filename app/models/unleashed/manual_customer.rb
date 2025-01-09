module Unleashed
  class ManualCustomer < Base

    def self.all
    
      date = ((Time.now-10.years).utc).strftime('%F')
      for i in 1..200
        options = { Page: i, pageSize: 50, startDate: date, modifiedSince: date}
        endpoint = 'Customers'
        params = options.dup
        # Handle Page option
        endpoint << "/#{params[:Page]}" if params[:Page].present?
        response = JSON.parse(@@client.get(endpoint, params).body)
        customers = response.key?('Items') ? response['Items'] : []

        customers.each do |user|
          Hubspot::Company.create_update(user) 
        end
        puts "Page================= #{i} ====================done"
      end
    end

  end
end