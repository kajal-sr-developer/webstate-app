module Hubspot
  class Contact
    CONTACT_PATH='https://api.hubapi.com/crm/v3/objects/contacts'

    def self.create_update(user, company_id)

      contacts_search_url = "https://api.hubapi.com/crm/v3/objects/contacts/search"
      contacts_search_body = {
        filterGroups: [{
          filters: [{
            propertyName: "email",
            operator: "EQ",
            value: user['Email']
          }]
        }]
      }

      

      contacts_response = HTTParty.post(
        contacts_search_url,
        body: contacts_search_body.to_json,
        headers: {
          'Authorization' => "Bearer #{ENV['HUBSPOT_API_KEY']}",
          'Content-Type' => 'application/json'
        }
      )

      contacts_results = JSON.parse(contacts_response.body)

      # Create contact properties
      contact_properties = {
        properties: {
          email: user['Email'],
          firstname: user['ContactFirstName'],
          lastname: user['ContactLastName'],
          phone: user['PhoneNumber'],
          fax: user['FaxNumber']
        }
      }

      if contacts_results['total'] == 0
        # Create new contact if not found
        contact_response = HTTParty.post(
          "https://api.hubapi.com/crm/v3/objects/contacts",
          body: contact_properties.to_json,
          headers: {
            'Authorization' => "Bearer #{ENV['HUBSPOT_API_KEY']}",
            'Content-Type' => 'application/json'
          }
        )
        if contact_response.success?
          puts "Successfully created contact: #{user['Email']}"
          contact_id = JSON.parse(contact_response.body)['id']
        else
          puts "Error creating contact: #{contact_response.body}"
        end
      else

        contact_id = contacts_results['results'].first['id'] rescue nil
        # Update existing contact if found
        if contact_id.present?
          contact_response = HTTParty.patch(
            "https://api.hubapi.com/crm/v3/objects/contacts/#{contact_id}",
            body: contact_properties.to_json,
            headers: {
              'Authorization' => "Bearer #{ENV['HUBSPOT_API_KEY']}",
              'Content-Type' => 'application/json'
            }
          )
          if !contact_response.success?
            puts "Error updating contact: #{contact_response.body}"
          end
        end
        puts "Successfully found contact: #{user['Email']}"
      end
  

      # Associate contact with company after company is created/updated
      association_url = "https://api.hubapi.com/crm/v3/associations/company/contact/batch/create"
      association_body = {
        inputs: [{
          from: { id: company_id },
          to: { id: contact_id },
          type: "company_to_contact"
        }]
      }

      association_response = HTTParty.post(
        association_url,
        body: association_body.to_json,
        headers: {
          'Authorization' => "Bearer #{ENV['HUBSPOT_API_KEY']}",
          'Content-Type' => 'application/json'
        }
      )
      if association_response.present? && association_response.success?
        puts "Successfully associated contact with company: #{user['Email']}"
      else
        puts "Error associating contact with company: #{user['Email']}"
      end

    end
  end
end