module Unleashed
  class ManualCustomer < Base

    def self.all
      date = ((Time.now-5.years).utc).strftime('%F')
      options = { Page: 1, pageSize: 1000, startDate: date, modifiedSince: date}
      endpoint = 'Customers'
      params = options.dup
      # Handle Page option
      endpoint << "/#{params[:Page]}" if params[:Page].present?
      response = JSON.parse(@@client.get(endpoint, params).body)
      customers = response.key?('Items') ? response['Items'] : []

      customers.each do |user|
        Hubspot::Company.create_update(user) 
      end
    end

  end
end