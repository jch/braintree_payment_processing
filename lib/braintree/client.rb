require 'rest_client'

module Braintree
  class Client
    # required arguments
    #   :username
    #   :password
    #
    # optionals arguments
    #   :api_url  - defaults to "https://secure.braintreepaymentgateway.com/api/transact.php"
    #   :on_error - proc object taking 2 arguments: hash of post parameters sent to Braintree,
    #               and Braintree::Response object.  Invoked when response is unsuccessful.
    #
    # example
    #   Braintree::Client.new({
    #     :username => 'testapi',
    #     :password => 'password1',
    #     :api_url  => 'https://secure.braintreepaymentgateway.com/api/transact.php'
    #     :on_error => Proc.new { |post_params, response|
    #       HoptoadNotifier.notify(:error_message => "Payment Error: #{response.text}")
    #     }
    #   })
    def initialize(args)
      # TODO: gem-ify Hash#assert_required_keys
      missing_keys = [:username, :password] - args.keys 
      raise(ArgumentError, "Missing required key(s): #{missing_keys.join(", ")}") unless missing_keys.empty?
      
      @api_url     = "https://secure.braintreepaymentgateway.com/api/transact.php"
      @on_error    = args[:on_error]
      @credentials = {
        :username => args[:username],
        :password => args[:password]
      }
    end
    
    # credit_card - valid ActiveMerchant::Billing::CreditCard object
    def add_credit_card_to_vault(credit_card)
      post_params =  {
        :customer_vault    => 'add_customer',
        :payment           => 'creditcard',
        :firstname         => credit_card.first_name,
        :lastname          => credit_card.last_name,
        :ccnumber          => credit_card.number,
        :ccexp             => sprintf("%.2d%.2d", credit_card.month, credit_card.year)
      }
      exec(post_params)
    end
    
    # customer_vault_id - id of customer to update
    # credit_card       - valid ActiveMerchant::Billing::CreditCard object
    def update_credit_card_to_vault(customer_vault_id, credit_card)
      post_params =  {
        :customer_vault    => 'update_customer',
        :customer_vault_id => customer_vault_id,
        :payment           => 'creditcard',
        :firstname         => credit_card.first_name,
        :lastname          => credit_card.last_name,
        :ccnumber          => credit_card.number,
        :ccexp             => sprintf("%.2d%.2d", credit_card.month, credit_card.year)
      }
      exec(post_params)
    end
    
    def delete_credit_card_to_vault(customer_vault_id)
      post_params = {
        :customer_vault    => 'delete_customer',
        :customer_vault_id => customer_vault_id
      }
      exec(post_params)
    end
    
    # customer_vault_id - if of customer to update
    # product_sku       - sku of plan to add customer to
    def add_recurring(customer_vault_id, product_sku)
      post_params =  {
        :type              => 'add_recurring',
        :customer_vault_id => customer_vault_id, # guaranteed to exist at this poin
        :product_sku_1     => product_sku
      }
      exec(post_params)
    end

    def delete_recurring(recurring_transaction_id)
      post_params = { :delete_recurring => recurring_transaction_id }
      exec(post_params)
    end
    
    # in email labeled with 'payments' - "New Misuse of Authorization Fee and
    # $0 Authorizations"
    #
    # Use this method to do our best to validate a card can actually be
    # charged.  Only Visa fully supports this feature; Mastercard will work
    # based on whether the issuer supports it, so it's hit or miss; All other
    # card types will error.
    #
    # possible response.response values
    #   '1' - card is valid
    #   '2' - card is invalid
    #   '3' - card is not supported or some other error occurred
    #
    # I recommend not using this at all because the results are so flaky.
    def validate_credit_card(credit_card)
      if !['visa', 'master'].include?(credit_card.type)
        return Braintree::Response::SUCCESS_RESPONSE
      end
      post_params = {
        :type     => 'validate',
        :ccnumber => credit_card.number,
        :ccexp    => sprintf("%.2d%.2d", credit_card.month, credit_card.year),
        :cvv      => credit_card.verification_value
      }

      exec(post_params)
    end
    
    protected

    def exec(post_params)
      post_params = post_params.merge(@credentials)
      
      raw_response = RestClient.post(@api_url, post_params) rescue ""
      response     = Braintree::Response.new(raw_response)
      
      if @on_error && !response.success?
        @on_error.call(post_params, response)
      end
      
      response
    end
  end
end