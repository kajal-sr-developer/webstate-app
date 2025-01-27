module Hubspot
  class Product
  	PRODUCT_PATH = 'https://api.hubapi.com/crm/v3/objects/products'

    def self.create(product)
      if product.present?
	      product = product.first
	      group = product["ProductGroup"]["GroupName"] rescue ""
	      uom = product["UnitOfMeasure"]["Name"]  rescue ""
	      location = product["InventoryDetails"].first["BinLocation"] rescue ""
	      body_json = {
	        "properties": {
	          "name": product["ProductCode"],
	          "price": product["DefaultSellPrice"],
	          "hs_sku": product["ProductCode"],
	          "product_group": group,
	          "unitofmeasure": uom,
	          "packsize": product["PackSize"],
	          "weight": product["Weight"],
	          "width": product["Width"],
	          "height": product["Height"],
	          "depth": product["Depth"],
	          "binlocation": location,
	          "minstockalertlevel": product["MinStockAlertLevel"],
	          "maxstockalertlevel": product["MaxStockAlertLevel"],
	          "defaultsellprice": product["DefaultSellPrice"],
	          "minimumsellprice": product["MinimumSellPrice"],
	          "taxablesales": product["TaxableSales"],
	          "averagelandprice": product["AverageLandPrice"],
	          "defaultpurchaseprice": product["DefaultPurchasePrice"],
	          "minimumsalequantity": product["MinimumSaleQuantity"],
	          "lastcost": product["LastCost"]
	        }
	      }
	      response = HTTParty.post("#{PRODUCT_PATH}",:body=> body_json.to_json, :headers => {
	         "Content-Type" => "application/json",
	         "Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"
	       })
	       return response
	      end
    end
    
    def self.search_quoteline_item_product(product_name)
      sleep(2)
      amount = price rescue 0
      body_json =
          {
        "filterGroups":[
          {
            "filters":[
              {
                "propertyName": "name",
                "operator": "EQ",
                "value": "#{product_name}"
              }
            ],
          "limit": 1,
          }
        ]
      }
      response = HTTParty.post("#{PRODUCT_PATH}/search",:body=> body_json.to_json, :headers => {
           "Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"
         })
      if response["total"].present? && response["total"] > 1
        response["results"].each_with_index do |product,index|
          unless index == 0
            HTTParty.delete("#{PRODUCT_PATH}/#{product['id']}", :headers => {
           		"Content-Type" => "application/json","Authorization" => "Bearer #{ENV['HUBSPOT_API_KEY']}"
         		})
           
          end
        end
      end
      return response
    end
  end
end