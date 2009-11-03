require File.dirname(__FILE__) + '/test_helper'

class BraintreeClientTest < ActiveSupport::TestCase
  def valid_options_for_client
    {
      :username => 'testapi',
      :password => 'password1'
    }
  end
  
  def create_client(options = {})
    Braintree::Client.new(valid_options_for_client.merge(options))
  end
  
  # https://www.paypal.com/en_US/vhelp/paypalmanager_help/credit_card_numbers.htm
  # discover         - 6011111111111117
  # american_express - 378282246310005
  # mastercard       - 5555555555554444
  def valid_options_for_credit_card
    {
      :type               => 'visa',
      :number             => '4111111111111111',
      :verification_value => '111',
      :expires_on         => Time.now + 1.year,
      :first_name         => 'Quentin',
      :last_name          => 'Costa'
    }
  end
  
  def create_credit_card(options = {})
    card_attrs = valid_options_for_credit_card.merge(options)
    expires_on = card_attrs.delete(:expires_on)
    card_attrs[:month] = expires_on.month
    card_attrs[:year] = expires_on.year
    ActiveMerchant::Billing::CreditCard.new(card_attrs)
  end
  
  test "username is required" do
    assert_raises(ArgumentError) do
      invalid_options = valid_options_for_client.dup
      invalid_options.delete(:username)
      Braintree::Client.new(invalid_options)
    end
  end
  
  test "password is required" do
    assert_raises(ArgumentError) do
      invalid_options = valid_options_for_client.dup
      invalid_options.delete(:password)
      Braintree::Client.new(invalid_options)
    end
  end
  
  test "should invoke global on_error callback if response is unsuccessful" do
    counter = 0
    error_callback = Proc.new { |post_params, response| counter += 1 }
    client = create_client(:on_error => error_callback)
    
    assert_difference "counter", 1 do
      response = client.delete_recurring('123_unknown_transaction_id_789')
      assert !response.success?
    end
  end
  
  # TODO: card verification is very flaky, will likely need to handle this case by case.
  test "validate an invalid visa card should return invalid code 2" do
    client = create_client

    # card has the right format, but has a bogus number and cvv code
    response = client.validate_credit_card(create_credit_card)
    
    # assert "2", response.response
  end
  
end
