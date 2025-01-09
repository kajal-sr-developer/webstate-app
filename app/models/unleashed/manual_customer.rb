module Unleashed
  class ManualCustomer < Base

    def self.all
    
      date = ((Time.now-15.minutes).utc).strftime('%F')
      options = { Page: 1, pageSize: 50, startDate: date, modifiedSince: date}
      endpoint = 'Customers'
      params = options.dup
      # Handle Page option
      endpoint << "/#{params[:Page]}" if params[:Page].present?
      response = JSON.parse(@@client.get(endpoint, params).body)
      customers = response.key?('Items') ? response['Items'] : []
      binding.pry
      customers.each do |user|
        Hubspot::Company.create_update(user) 
      end
    end
  end
end