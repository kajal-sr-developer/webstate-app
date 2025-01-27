module Hubspot
  class Quote
    QUOTE_PATH = 'https://api.hubapi.com/crm/v3/objects/quotes'

    def self.create_update_quote(quote,deal_id)
      quote_name = quote["QuoteNumber"]
      existing_quote = Hubspot::Quote.find_quote_by_name(quote_name) 
      duedate = (quote["DueDate"].to_time).to_i*1000  rescue ((Date.today + 1.year).to_time).to_i*1000
      comment = quote["Comments"].gsub('&amp;','&') rescue ""
      body_json = {
        "properties": {
        "hs_template_type": 'CUSTOMIZABLE_QUOTE_TEMPLATE',
        "hs_title": quote_name,
        "hs_sender_company_domain": 'westatehose.com.au',
        "hs_sender_lastname": 'Westate Hose Supplies',
        "hs_sender_company_address": 'Perth Distribution Centre, 89 Pilbara St, Welshpool WA 6106, Australia',
        "hs_sender_company_name": 'Westate Hose Supplies',
        "hs_sender_email": 'sales@westatehose.com.au',
        "hs_sender_company_city": '89 Pilbara St, Welshpool WA 6106',
        "hs_status": 'DRAFT',
        "hs_expiration_date": duedate,
        "hs_comments": comment,
        "hs_language": 'en'
        }
      }
      if existing_quote.present? && existing_quote.success? && existing_quote["total"] > 1
        for i in 0..(existing_quote["total"].to_i-2)
          if  existing_quote["results"][i]["properties"]["hs_status"] =="DRAFT" 
            id = existing_quote["results"][i]["id"]
            delete_response = HTTParty.delete("https://api.hubapi.com/crm/v3/objects/quotes/#{id}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
          end
        end 
      end
      if existing_quote["results"].blank?
        response = HTTParty.post("#{QUOTE_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        association_response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/quotes/#{response['id']}/associations/deals/#{deal_id}/quote_to_deal",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      else 
        hs_quote_id = existing_quote["results"].first["id"]
        response = HTTParty.patch("#{QUOTE_PATH}/#{hs_quote_id}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      end
        

      if response.present? && response.success?
        Hubspot::Quote.create_line_item(response["id"],quote,deal_id)
      end
    end

    def self.create_line_item(quote_id,quote,deal_id)
      line_items = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/line_items",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      if line_items["results"].present?
        delete_json = {
            "ids": line_items["results"].map{|i| i["toObjectId"]}
          }
         HTTParty.post("https://api.hubapi.com/crm-objects/v1/objects/line_items/batch-delete",:body=> delete_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })          
      end



      taxes = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/taxes",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      if taxes["results"].present?
        taxes["results"].each do |taxe|
          delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/taxes/#{taxe['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        end
      end

      discounts = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/discounts",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      if discounts["results"].present?
        discounts["results"].each do |discount|
          delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/discounts/#{discount['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        end
      end
      @product = []
      begin
        if quote["SalesQuoteLines"].present?
          quote["SalesQuoteLines"].each do |line_item|

            # product_name = line_item["ProductName"]
            # if unleashed_product.present?
              product_code = line_item["Product"]["ProductCode"]
              hs_product = Hubspot::Product.search_quoteline_item_product(product_code)
              if hs_product.present? && hs_product["results"].present?
                product = hs_product["results"].first["id"]
              else
                unleashed_product = Unleashed::Product.get_product(line_item["Product"]["ProductCode"])
                product_response = Hubspot::Product.create(unleashed_product)
                product = product_response["id"]
              end
              @product << [{
                            "name": "hs_product_id",
                            "value": product
                          },
                          {
                            "name": "quantity",
                            "value": line_item["QuoteQuantity"]
                          },
                          {
                            "name": "name",
                            "value": line_item["Product"]["ProductDescription"]
                          },{
                            "name": "price",
                            "value": line_item["UnitPrice"]
                          },{
                            "name": "hs_discount_percentage",
                            "value": line_item["DiscountRate"]*100
                          },{
                            "name": "hs_tax_rate",
                            "value": line_item["TaxRate"]*100
                          }]
            end
          batch_create_response = HTTParty.post("https://api.hubapi.com/crm-objects/v1/objects/line_items/batch-create",:body=> @product.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"})
          line_item_ids = batch_create_response.map{ |i| i["properties"]["hs_object_id"]}.map{|i| i["value"]}

            from_id = quote_id
            type = "quote_to_line_item"

            asso_body = {
              inputs: line_item_ids.map do |to_id|
                { "from" => { "id" => from_id }, "to" => { "id" => to_id }, "type" => type }
              end
            }

         acc_response = HTTParty.post("https://api.hubapi.com/crm/v3/associations/quote/line_item/batch/create",:body=> asso_body.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"})


          from_id = deal_id
            type = "deal_to_line_item"

            asso_body = {
              inputs: line_item_ids.map do |to_id|
                { "from" => { "id" => from_id }, "to" => { "id" => to_id }, "type" => type }
              end
            }
         deal_acc_response = HTTParty.post("https://api.hubapi.com/crm/v3/associations/deal/line_item/batch/create",:body=> asso_body.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"})
        end
      rescue
      end
    end 






    def self.create_update_sales_quote(sale,deal_id)
      quote_name = sale["OrderNumber"]
      existing_quote = Hubspot::Quote.find_quote_by_name(quote_name) 
      duedate = (sale["DueDate"].to_time).to_i*1000  rescue ((Date.today + 1.year).to_time).to_i*1000
      comment = sale["Comments"].gsub('&amp;','&') rescue ""
      body_json = {
        "properties": {
        "hs_template_type": 'CUSTOMIZABLE_QUOTE_TEMPLATE',
        "hs_title": quote_name,
        "hs_sender_company_domain": 'westatehose.com.au',
        "hs_sender_lastname": 'Westate Hose Supplies',
        "hs_sender_company_address": 'Perth Distribution Centre, 89 Pilbara St, Welshpool WA 6106, Australia',
        "hs_sender_company_name": 'Westate Hose Supplies',
        "hs_sender_email": 'sales@westatehose.com.au',
        "hs_sender_company_city": '89 Pilbara St, Welshpool WA 6106',
        "hs_status": 'DRAFT',
        "hs_expiration_date": duedate,
        "hs_comments": comment,
        "hs_language": 'en'
        }
      }
      if existing_quote.present? && existing_quote.success? && existing_quote["total"] > 1
        for i in 0..(existing_quote["total"].to_i-2)
          if  existing_quote["results"][i]["properties"]["hs_status"] =="DRAFT" 
            id = existing_quote["results"][i]["id"]
            delete_response = HTTParty.delete("https://api.hubapi.com/crm/v3/objects/quotes/#{id}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
          end
        end 
      end
      if existing_quote["results"].blank?
        response = HTTParty.post("#{QUOTE_PATH}/",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        association_response = HTTParty.put("https://api.hubapi.com/crm/v3/objects/quotes/#{response['id']}/associations/deals/#{deal_id}/quote_to_deal",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      else 
        hs_quote_id = existing_quote["results"].first["id"]
        response = HTTParty.patch("#{QUOTE_PATH}/#{hs_quote_id}",:body=> body_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      end
        

      if response.present? && response.success?
        Hubspot::Quote.create_sales_line_item(response["id"],sale,deal_id)
      end
    end

    def self.create_sales_line_item(quote_id,sale,deal_id)
      line_items = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/line_items",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      if line_items["results"].present?
        delete_json = {
            "ids": line_items["results"].map{|i| i["toObjectId"]}
          }
         HTTParty.post("https://api.hubapi.com/crm-objects/v1/objects/line_items/batch-delete",:body=> delete_json.to_json,:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })          
      end



      taxes = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/taxes",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      if taxes["results"].present?
        taxes["results"].each do |taxe|
          delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/taxes/#{taxe['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        end
      end

      discounts = HTTParty.get("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/discounts",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
      if discounts["results"].present?
        discounts["results"].each do |discount|
          delete_response = HTTParty.delete("https://api.hubapi.com/crm/v4/objects/quotes/#{quote_id}/associations/discounts/#{discount['toObjectId']}",:headers => { 'Content-Type' => 'application/json',"Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}" })
        end
      end
      @product = []
      begin
        if sale["SalesOrderLines"].present?
          sale["SalesOrderLines"].each do |line_item|

            # product_name = line_item["ProductName"]
            # if unleashed_product.present?
              product_code = line_item["Product"]["ProductCode"]
              hs_product = Hubspot::Product.search_quoteline_item_product(product_code)
              if hs_product.present? && hs_product["results"].present?
                product = hs_product["results"].first["id"]
              else
                unleashed_product = Unleashed::Product.get_product(line_item["Product"]["ProductCode"])
                product_response = Hubspot::Product.create(unleashed_product)
                product = product_response["id"]
              end
              @product << [{
                            "name": "hs_product_id",
                            "value": product
                          },
                          {
                            "name": "quantity",
                            "value": line_item["QuoteQuantity"]
                          },
                          {
                            "name": "name",
                            "value": line_item["Product"]["ProductDescription"]
                          },{
                            "name": "price",
                            "value": line_item["UnitPrice"]
                          },{
                            "name": "hs_discount_percentage",
                            "value": line_item["DiscountRate"]*100
                          },{
                            "name": "hs_tax_rate",
                            "value": line_item["TaxRate"]*100
                          }]
            end
          batch_create_response = HTTParty.post("https://api.hubapi.com/crm-objects/v1/objects/line_items/batch-create",:body=> @product.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"})
          line_item_ids = batch_create_response.map{ |i| i["properties"]["hs_object_id"]}.map{|i| i["value"]}

            from_id = quote_id
            type = "quote_to_line_item"

            asso_body = {
              inputs: line_item_ids.map do |to_id|
                { "from" => { "id" => from_id }, "to" => { "id" => to_id }, "type" => type }
              end
            }

         acc_response = HTTParty.post("https://api.hubapi.com/crm/v3/associations/quote/line_item/batch/create",:body=> asso_body.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"})


          from_id = deal_id
            type = "deal_to_line_item"

            asso_body = {
              inputs: line_item_ids.map do |to_id|
                { "from" => { "id" => from_id }, "to" => { "id" => to_id }, "type" => type }
              end
            }
         deal_acc_response = HTTParty.post("https://api.hubapi.com/crm/v3/associations/deal/line_item/batch/create",:body=> asso_body.to_json, :headers => {"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"})
        end
      rescue
      end
    end 




		def self.find_quote_by_name(quote_name)
      sleep(2)
			body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "hs_title",
                "operator": "EQ",
                "value": "#{quote_name}"
              }
            ]
          }
        ]
      }
      response = HTTParty.post("#{QUOTE_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"
         })
      return response
		end
  end
end