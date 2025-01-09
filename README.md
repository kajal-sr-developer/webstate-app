# Unleashed to HubSpot Integration

This application synchronizes customer data from Unleashed to HubSpot CRM. It fetches customer records from Unleashed that have been modified in the last 15 minutes and creates or updates corresponding companies in HubSpot.

## Setup

1. Clone the repository
2. Install dependencies:

## Usage

### Manual Sync

To manually sync customers from Unleashed to HubSpot, run:

### What Gets Synced

The integration syncs the following customer data:
- Basic information (name, customer code, phone, email)
- Postal address details
- Physical address details
- Sales person information
- Tax and payment details
- Custom fields and settings

### Automation

You can set up a cron job to run the sync automatically. Example crontab entry to run every 15 minutes:

## Error Handling

The integration includes error handling and logging:
- Failed company creations/updates are logged with error messages
- Successful syncs are confirmed with console output
- Missing or invalid fields are handled gracefully with fallback to empty strings

## Dependencies

- Rails 7.x
- HTTParty for API requests
- Unleashed API client
- HubSpot API v3

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
