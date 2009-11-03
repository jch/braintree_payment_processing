require File.dirname(__FILE__) + '/test_helper'

class BraintreeResponseTest < ActiveSupport::TestCase
  test "should be successful if the response is '1' and the response_code is '100'" do
    raw = "response=1&response_code=100"
    response = Braintree::Response.new(raw)
    assert response.success?
  end
  
  test "SUCCESS_RESPONSE is a constant response that is successful" do
    assert Braintree::Response::SUCCESS_RESPONSE.success?
  end
  
  test "should not be successful if response is missing a response" do
    raw = "response_code=100"
    response = Braintree::Response.new(raw)
    assert !response.success?
  end
  
  test "should not be successful if response is missing a response code" do
    raw = "response=1"
    response = Braintree::Response.new(raw)
    assert !response.success?
  end
  
  test "should not be successful if response is anything other than '1'" do
    raw = "response=3&response_code=100"
    response = Braintree::Response.new(raw)
    assert !response.success?
  end
  
  test "should not be successful if response_code is anything other than '100'" do
    raw = "response=1&response_code=300"
    response = Braintree::Response.new(raw)
    assert !response.success?
  end
  
  test "should not be successful if raw response is blank" do
    raw = ""
    response = Braintree::Response.new(raw)
    assert !response.success?
  end
  
  test "text should be blank if raw response is blank" do
    raw = ""
    response = Braintree::Response.new(raw)
    assert response.text.blank?
  end
  
  test "code should be blank if raw response is blank" do
    raw = ""
    response = Braintree::Response.new(raw)
    assert response.code.blank?
  end
  
  test "should retrieve unknown values from raw response" do
    raw = "garply=rivegauche"
    response = Braintree::Response.new(raw)
    assert_equal 'rivegauche', response.garply
  end
  
  test "add credit card to vault should have response text 'Customer Added'" do
    raw = "response=1&responsetext=Customer Added&authcode=&transactionid=0&avsresponse=&cvvresponse=&orderid=&type=&response_code=100&customer_vault_id=113870"
    response = Braintree::Response.new(raw)
    assert_equal 'Customer Added', response.text
  end
  
  test "delete credit card from vault should have response text 'Customer Deleted'" do
    raw = "response=1&responsetext=Customer Deleted&authcode=&transactionid=0&avsresponse=&cvvresponse=&orderid=&type=&response_code=100&customer_vault_id=113870"
    response = Braintree::Response.new(raw)
    assert_equal 'Customer Deleted', response.text
  end
end
