require 'test_helper'
class UserTest < ActiveSupport::TestCase
  def setup
    activate_authlogic
    controller.session[:session_id] = "FakeSessionID"
    controller.cookies[:PDS_HANDLE] = { :value => VALID_PDS_HANDLE_FOR_NYU }
    Institutions.send(:instance_variable_set, :@loadpaths, nil)
    Institutions.send(:instance_variable_set, :@institutions, nil)
  end

  test "username=" do
    ba36 = User.find(1)
    token1 = ba36.persistence_token
    ba36.username=("ba36")
    token2 = ba36.persistence_token
    assert_equal(token1, token2)
    ba36.username=("ba37")
    token2 = ba36.persistence_token
    assert_not_equal(token1, token2)
  end

  test "user_attributes" do
    user = User.new
    user.user_attributes= {:test_attribute1 => "value1", :test_attribute2 => "value2"}
    assert_equal("value1", user.user_attributes[:test_attribute1])
    assert_equal("value2", user.user_attributes[:test_attribute2])
    user.user_attributes= {:test_attribute3 => "value3", :test_attribute4 => "value4"}
    assert_equal("value1", user.user_attributes[:test_attribute1])
    assert_equal("value2", user.user_attributes[:test_attribute2])
    assert_equal("value3", user.user_attributes[:test_attribute3])
    assert_equal("value4", user.user_attributes[:test_attribute4])
    user.user_attributes= {:test_attribute3 => "value3.1", :test_attribute4 => "value4.1"}
    assert_equal("value1", user.user_attributes[:test_attribute1])
    assert_equal("value2", user.user_attributes[:test_attribute2])
    assert_equal("value3.1", user.user_attributes[:test_attribute3])
    assert_equal("value4.1", user.user_attributes[:test_attribute4])
  end

  test "primary_institution" do
    Institutions.loadpaths<< "#{File.dirname(__FILE__)}/support/config"
    user = User.new
    assert_nothing_raised ArgumentError do
      user.primary_institution= "NYU"
    end
    assert_equal(Institutions.institutions[:NYU], user.primary_institution)
  end

  test "primary_institution no institutions" do
    user = User.new
    assert_nothing_raised do
      user.primary_institution= "NYU"
    end
    assert_equal(nil, user.primary_institution)
  end

  test "primary_institution= nil" do
    user = User.new
    assert_nothing_raised do
      user.primary_institution= "NYU"
    end
  end

  test "institutions" do
    Institutions.loadpaths<< "#{File.dirname(__FILE__)}/support/config"
    user = User.new
    assert_raise ArgumentError do
      user.institutions= "NYU"
    end
    user.institutions= ["NYU"]
    assert_not_nil(user.institutions)
    assert_equal([Institutions.institutions[:NYU]], user.institutions)
  end

  test "institutions not set" do
    user = User.new
    user.institutions= ["NYU"]
    assert_nil(user.institutions)
  end

  test "expired?" do
    user = User.new
    user.expiration_date = 1.week.ago
    user.refreshed_at = 1.week.ago - 1.second
    assert(user.expired?)
    user.expiration_date = 1.week.ago
    user.refreshed_at = 1.week.ago + 1.second
    assert(!user.expired?)
  end
end