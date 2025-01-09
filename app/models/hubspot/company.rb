module Hubspot
  #
  # HubSpot Form API
  #
  # {https://developers.hubspot.com/docs/methods/forms/forms_overview}
  #  
  class Company
    COMPANY_PATH='https://api.hubapi.com/crm/v3/objects/companies'
    def self.create_update(user)

      customer_code = user['CustomerCode']
      
      # Search for company by CustomerCode
      search_url = "#{COMPANY_PATH}/search"
      search_body = {
        filterGroups: [{
          filters: [{
            propertyName: "customer_code",
            operator: "EQ", 
            value: customer_code
          }]
        }]
      }
      
      search_response = HTTParty.post(
        search_url,
        body: search_body.to_json,
        headers: {
          'Authorization' => "Bearer #{ENV['HUBSPOT_API_KEY']}",
          'Content-Type' => 'application/json'
        }
      )
      
      results = JSON.parse(search_response.body)
      physical_address =  user["Addresses"][1]
      postal_address = user["Addresses"][0]
      salesperson = user["SalesPerson"]["FullName"] + ": " + user["SalesPerson"]["Email"]
    
      
  
      # Create company properties with error handling for each field
      company_properties = {
        properties: {
          name: user['CustomerName'].presence || '',
          customer_code: user['CustomerCode'].presence || '',
          phone: user['PhoneNumber'].presence || '',
          address: postal_address&.dig('StreetAddress').presence || '',
          city: postal_address&.dig('City').presence || '',
          state: postal_address&.dig('Region').presence || '',
          country: postal_address&.dig('Country').presence || '',
          zip: postal_address&.dig('PostalCode').presence || '',
          email_address: user['EmailAddress'].presence || '',
          customer_type: user['CustomerType'].presence || '',
          gst_vat_number: user['GSTVATNumber'].presence || '',
          isobsoleted: user['Obsolete'].presence || false,
          payment_terms: user['PaymentTerm'].presence || '',
          physical_address_name: physical_address&.dig('AddressName').presence || '',
          physical_country: physical_address&.dig('Country').presence || '',
          physical_delivery_instruction: physical_address&.dig('DeliveryInstruction').presence || '',
          physical_postal_code: physical_address&.dig('PostalCode').presence || '',
          physical_state_region: physical_address&.dig('Region').presence || '',
          physical_street_address: physical_address&.dig('StreetAddress').presence || '',
          physical_street_address_2: physical_address&.dig('StreetAddress2').presence || '',
          physical_town_city: physical_address&.dig('City').presence || '',
          postal_suburb: postal_address&.dig('Suburb').presence || '',
          reminder: user['Reminder'].presence || '',
          salesperson: salesperson.presence || '',
          sell_price_tier: user['SellPriceTier'].presence || '',
          stop_credit: user['StopCredit'].presence || false,
          tax_code: user['TaxCode'].presence || '',
          taxable: user['Taxable'].presence || false,
          guid: user['Guid'].presence || ''
        }
      }

      if results['total'] == 0
        company_response = HTTParty.post(
          COMPANY_PATH,
          body: company_properties.to_json,
          headers: {
            'Authorization' => "Bearer #{ENV['HUBSPOT_API_KEY']}",
            'Content-Type' => 'application/json'
          }
        )
        
        if company_response.success?
          company_id = JSON.parse(company_response.body)['id']
          if user['Email'].present?
            Hubspot::Contact.create_update(user, company_id)
          end
          puts "Successfully created company: #{user['CustomerName']}"
        else
          puts "Error creating company #{user['CustomerName']}: #{company_response.body}"
        end
      else
        company_id = results['results'].first['id']
        company_response = HTTParty.patch(
          "#{COMPANY_PATH}/#{company_id}",
          body: company_properties.to_json,
          headers: {
            'Authorization' => "Bearer #{ENV['HUBSPOT_API_KEY']}",
            'Content-Type' => 'application/json'
          }
        )
        if company_response.success?
          if user['Email'].present?
            Hubspot::Contact.create_update(user, company_id)
          end
          puts "Successfully updated company: #{user['CustomerName']}"
        else
          puts "Error updating company #{user['CustomerName']}: #{company_response.body}"
        end
      end
    end
  end
end