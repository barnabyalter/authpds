require 'test_helper'
class UserSessionTest < ActiveSupport::TestCase

  def setup
    activate_authlogic
    controller.session[:session_id] = "FakeSessionID"
    controller.cookies[:PDS_HANDLE] = { :value => VALID_PDS_HANDLE_FOR_NYU }
  end

  test "login_url" do
    user_session = UserSession.new
    assert_equal(
      "https://logindev.library.nyu.edu/pds?func=load-login&calling_system=authpds&url=http%3A%2F%2Frailsapp.library.nyu.edu%2Fvalidate%3Freturn_url%3D",
        user_session.login_url)
  end

  test "logout_url" do
    user_session = UserSession.new
    assert_equal(
      "https://logindev.library.nyu.edu/pds?func=logout&url=http%3A%2F%2Fbobcatdev.library.nyu.edu",
        user_session.logout_url)
  end

  test "sso_url" do
    user_session = UserSession.new
    assert_equal(
    "https://logindev.library.nyu.edu/pds?func=sso&calling_system=authpds&url=http%3A%2F%2Frailsapp.library.nyu.edu%2Fvalidate%3Freturn_url%3D",
        user_session.sso_url)
  end

  test "validate_url" do
    user_session = UserSession.new
    assert_equal(
      "http://railsapp.library.nyu.edu/validate?return_url=http://railsapp.library.nyu.edu",
        user_session.send(:validate_url, :return_url => "http://railsapp.library.nyu.edu"))
    assert_equal(
      "http://railsapp.library.nyu.edu/validate?return_url=http://railsapp.library.nyu.edu&authpds_custom_param1=custom_param1",
        user_session.send(:validate_url, :controller => "test_controller",
          :action => "test_action", :return_url => "http://railsapp.library.nyu.edu",
            :custom_param1 => "custom_param1"))
  end

  test "pds_handle" do
    user_session = UserSession.new
    assert_equal(VALID_PDS_HANDLE_FOR_NYU, user_session.send(:pds_handle))
  end

  test "pds_user" do
    user_session = UserSession.new
    VCR.use_cassette('nyu') do
      pds_user = user_session.pds_user
      assert_instance_of(Authpds::Exlibris::Pds::BorInfo, pds_user)
      assert_equal("N12162279", pds_user.id)
      assert_equal("N12162279", pds_user.nyuidn)
      assert_equal("51", pds_user.bor_status)
      assert_equal("CB", pds_user.bor_type)
      assert_equal("SCOT THOMAS", pds_user.name)
      assert_equal("SCOT THOMAS", pds_user.givenname)
      assert_equal("DALTON", pds_user.sn)
      assert_equal("Y", pds_user.ill_permission)
      assert_equal("GA", pds_user.college_code)
      assert_equal("CSCI", pds_user.dept_code)
      assert_equal("Information Systems", pds_user.major)
      assert_equal("NYU", pds_user.institute)
    end
  end

  test "persist_session" do
    user_session = UserSession.new
    assert_nil(controller.session["authpds_credentials"])
    assert_nil(user_session.send(:attempted_record))
    assert_nil(user_session.record)
    VCR.use_cassette('nyu') do
      assert_no_difference('User.count') do
        user_session.send(:persist_session)
      end
      assert_not_nil(user_session.send(:attempted_record))
      assert_nil(user_session.record)
      assert_equal("N12162279", user_session.send(:attempted_record).username)
    end
  end

  test "find" do
    user_session = UserSession.new
    assert_nil(controller.session["authpds_credentials"])
    assert_nil(user_session.send(:attempted_record))
    assert_nil(user_session.record)
    VCR.use_cassette('nyu') do
      assert_difference('User.count') {
        user_session = UserSession.find
      }
      assert_not_nil(controller.session["authpds_credentials"])
      assert_not_nil(user_session.send(:attempted_record))
      assert_not_nil(user_session.record)
      assert_equal(controller.session["authpds_credentials"], user_session.record.persistence_token)
      assert_equal("N12162279", user_session.record.username)
    end
  end

  test "expiration_date" do
    user_session = UserSession.new
    assert_in_delta(-0.00001, 1.day.ago.to_f, user_session.expiration_date.to_f)
  end

  test "get_record" do
    user_session = UserSession.new
    record = user_session.send(:get_record, "std5")
    assert_instance_of(User, record)
    assert_equal("std5", record.username)
    assert_nil(record.id)
    assert_nil(record.firstname)
    record = user_session.send(:get_record, "st75")
    assert_instance_of(User, record)
    assert_equal("st75", record.username)
    assert_not_nil(record.id)
    assert_equal(3, record.id)
    assert_not_nil(record.firstname)
    assert_equal("Sydney Leigh", record.firstname)
  end
end