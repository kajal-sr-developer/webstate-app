module Unleashed
  class ManualQuote < Base
    def self.all
      date = ((Time.now-15.minutes).utc).strftime('%F')
      options = { Page: 1, pageSize: 50, startDate: date, modifiedSince: date}
      endpoint = 'SalesQuotes'
      params = options.dup
      # Handle Page option
      endpoint << "/#{params[:Page]}" if params[:Page].present?
      response = JSON.parse(@@client.get(endpoint, params).body)
      quotes = response.key?('Items') ? response['Items'] : []
      quotes.each do |quote|
        Hubspot::Deal.create_update(quote)
      end
    end
  end
end
