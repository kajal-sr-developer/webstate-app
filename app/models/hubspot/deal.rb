module Hubspot
  class Deal 
    DEAL_PATH='https://api.hubapi.com/crm/v3/objects/deals'

    def self.create_update(quote)

      existing_deal = Hubspot::Deal.find_deal( quote['QuoteNumber'])
      accepted_date = Time.at((quote["AcceptedDate"].split('(').last.gsub(')/','')).to_i/1000, in: "UTC").midnight rescue nil
      expiry_date =  Time.at((quote["QuoteExpiryDate"].split('(').last.gsub(')/','')).to_i/1000, in: "UTC").midnight rescue nil
      quote_date =  Time.at((quote["QuoteDate"].split('(').last.gsub(')/','')).to_i/1000, in: "UTC").midnight rescue nil
      created_on =  Time.at((quote["CreatedOn"].split('(').last.gsub(')/','')).to_i/1000, in: "UTC").midnight rescue nil
      salesperson = quote["SalesPerson"]["FullName"] + ": " + quote["SalesPerson"]["Email"] rescue nil
      deal_name = quote["QuoteNumber"] rescue "--"
       if quote["QuoteStatus"]=="Pending"
        hs_stage = 'presentationscheduled'
      elsif quote["QuoteStatus"] == "Cancelled" || quote["QuoteStatus"] == "Deleted"
        hs_stage = 'contractsent'
      elsif quote["QuoteStatus"] == "Open" || quote["QuoteStatus"] == "Draft"
         hs_stage = 'appointmentscheduled'
      elsif quote["QuoteStatus"] == "Accepted"
        hs_stage = '965389987'
      else
      end

      body_json = {
        properties: {
          accepted_date: accepted_date,
          bcsub: quote['BCSubTotal'],
          bctax: quote['BCTaxTotal'], 
          bctotal: quote['BCTotal'],
          comments: quote['Comments'],
          createdby: quote['CreatedBy'],
          createdon: created_on,
          deliverycity: quote['DeliveryCity'],
          deliverycountry: quote['DeliveryCountry'],
          deliverymethod: quote['DeliveryMethod'],
          deliveryname: quote['DeliveryName'],
          deliverypost: quote['DeliveryPostCode'],
          deliveryregion: quote['DeliveryRegion'],
          deliverystreet: quote['DeliveryStreetAddress'],
          deliverystreet2: quote['DeliveryStreetAddress2'],
          deliverysuburb: quote['DeliverySuburb'],
          discountrate: quote['DiscountRate'],
          exchangerate: quote['ExchangeRate'],
          quotedate: quote_date,
          quotenumber: quote['QuoteNumber'],
          quotestatus: quote['QuoteStatus'],
          salesorder: quote['SalesOrders'].join(','),
          salesperson: salesperson,
          quoteexpirydate: expiry_date,
          dealname: deal_name,
          pipeline: "default",
          dealstage: hs_stage,
          amount: quote['SubTotal']
        }
      }

      if existing_deal["results"].blank?
        response = HTTParty.post("#{DEAL_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        puts "deal created#{deal_name}"
      else 
        deal_id = existing_deal["results"].first["id"]
        response = HTTParty.patch("#{DEAL_PATH}/#{deal_id}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        puts "deal updated#{deal_name}"
      end
      customer = Hubspot::Company.find_by_customer_code(quote["Customer"]["CustomerCode"])
      company_id = customer["results"].first["id"] rescue nil
      if response.present? && response.success?
        if company_id.present?
          company_response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{response["id"]}/associations/companies/#{company_id}/deal_to_company",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        end 
        Hubspot::Quote.create_update_quote(quote,response["id"])
      else  
        puts "deal failed #{response.message}"
      end
    end




    def self.create_update_sales_deal(sale)

      existing_deal = Hubspot::Deal.find_deal_by_order(sale['OrderNumber'])
      orderdate = Time.at((sale["AcceptedDate"].split('(').last.gsub(')/','')).to_i/1000, in: "UTC").midnight rescue nil
      requireddate =  Time.at((sale["saleExpiryDate"].split('(').last.gsub(')/','')).to_i/1000, in: "UTC").midnight rescue nil
      created_on =  Time.at((sale["CreatedOn"].split('(').last.gsub(')/','')).to_i/1000, in: "UTC").midnight rescue nil
      salesperson = sale["SalesPerson"]["FullName"] + ": " + sale["SalesPerson"]["Email"] rescue nil
      complete_date =  Time.at((sale["CompletedDate"].split('(').last.gsub(')/','')).to_i/1000, in: "UTC").midnight rescue nil
      deal_name = sale["OrderNumber"] rescue "--"
       if sale["OrderStatus"]=="Open"
        hs_stage = '969781838'
      elsif sale["OrderStatus"] == "Parked"
        hs_stage = '969781839'
      elsif sale["OrderStatus"] == "Placed"
         hs_stage = '969781840'
      elsif sale["OrderStatus"] == "Backordered"
        hs_stage = '969781841'
      elsif sale["OrderStatus"] == "Completed"
        hs_stage = '969781842'
      elsif sale["OrderStatus"] == "Deleted"
        hs_stage = '969781843'
      else
      end

      body_json = {
        properties: {
          orderdate: orderdate,
          bcsub: sale['BCSubTotal'],
          bctax: sale['BCTaxTotal'], 
          bctotal: sale['BCTotal'],
          comments: sale['Comments'],
          createdby: sale['CreatedBy'],
          createdon: created_on,
          deliverycity: sale['DeliveryCity'],
          deliverycountry: sale['DeliveryCountry'],
          deliverymethod: sale['DeliveryMethod'],
          deliveryname: sale['DeliveryName'],
          deliverypost: sale['DeliveryPostCode'],
          deliveryregion: sale['DeliveryRegion'],
          deliverystreet: sale['DeliveryStreetAddress'],
          deliverystreet2: sale['DeliveryStreetAddress2'],
          deliverysuburb: sale['DeliverySuburb'],
          discountrate: sale['DiscountRate'],
          exchangerate: sale['ExchangeRate'],
          ordernumber: sale['OrderNumber'],
          orderstatus: sale['OrderStatus'],
          salesperson: salesperson,
          requireddate: requireddate,
          dealname: deal_name,
          pipeline: "659954245",
          dealstage: hs_stage,
          amount: sale['SubTotal'],
          completedate:  complete_date
        }
      }

      if existing_deal["results"].blank?
        response = HTTParty.post("#{DEAL_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        puts "deal created#{deal_name}"
      else 
        deal_id = existing_deal["results"].first["id"]
        response = HTTParty.patch("#{DEAL_PATH}/#{deal_id}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        puts "deal updated#{deal_name}"
      end
      customer = Hubspot::Company.find_by_customer_code(sale["Customer"]["CustomerCode"])
      company_id = customer["results"].first["id"] rescue nil
      if response.present? && response.success?
        if company_id.present?
          company_response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/deals/#{response["id"]}/associations/companies/#{company_id}/deal_to_company",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        end 
        Hubspot::Quote.create_update_sales_quote(sale,response["id"])
      else  
        puts "deal failed #{response.message}"
      end
    end





     def self.find_deal(quote_number)
      sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "quotenumber",
                "operator": "EQ",
                "value": "#{quote_number}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{DEAL_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"
         })
      return response
    end

    def self.find_deal_by_order(order_number)
      sleep(1)
       body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "ordernumber",
                "operator": "EQ",
                "value": "#{order_number}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{DEAL_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"
         })
      return response
    end

  end
end