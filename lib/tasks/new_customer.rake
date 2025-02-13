namespace :new_customer do
  desc "Create new customer"
  task create: :environment do
    Unleashed::ManualCustomer.all
    puts "Create new customer"
    Unleashed::ManualQuote.all
    puts "Create new quote"
    Unleashed::ManualOrder.all
    uts "Create new order"
  end
end
