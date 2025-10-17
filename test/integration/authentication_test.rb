require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @godmother = people(:godmother)
    @mentor = people(:mentor_waiting)
    @mentee = people(:mentee_waiting)
  end

  # ===== LOGIN TESTS =====

  test "godmother can access login page" do
    get sessions_new_url
    assert_response :success
    assert_select 'form'
  end

  test "godmother can login with valid credentials" do
    post sessions_create_url, params: {
      email: @godmother.email,
      password: 'test_password_123456'
    }

    assert_redirected_to root_url
    follow_redirect!
    assert_match /logged in/i, response.body.downcase

    # Verify session was created
    assert_not_nil session[:person_id]
    assert_equal @godmother.id, session[:person_id]
  end

  test "login fails with wrong password" do
    post sessions_create_url, params: {
      email: @godmother.email,
      password: 'wrong_password'
    }

    assert_response :success  # renders login form again
    assert_match /invalid/i, response.body.downcase
    assert_nil session[:person_id]
  end

  test "login fails with non-existent email" do
    post sessions_create_url, params: {
      email: 'nonexistent@example.com',
      password: 'any_password'
    }

    assert_response :success
    assert_match /invalid/i, response.body.downcase
    assert_nil session[:person_id]
  end

  test "mentor cannot login even with password" do
    # Mentors don't have passwords by default, but even if they did:
    post sessions_create_url, params: {
      email: @mentor.email,
      password: 'any_password'
    }

    assert_response :success
    assert_match /invalid/i, response.body.downcase
    assert_nil session[:person_id]
  end

  test "mentee cannot login" do
    post sessions_create_url, params: {
      email: @mentee.email,
      password: 'any_password'
    }

    assert_response :success
    assert_match /invalid/i, response.body.downcase
    assert_nil session[:person_id]
  end

  # ===== LOGOUT TESTS =====

  test "godmother can logout" do
    # Login first
    post sessions_create_url, params: {
      email: @godmother.email,
      password: 'test_password_123456'
    }
    assert_not_nil session[:person_id]

    # Logout
    get sessions_destroy_url
    assert_redirected_to root_url
    follow_redirect!
    assert_match /logged out/i, response.body.downcase
    assert_nil session[:person_id]
  end

  # ===== SESSION PERSISTENCE TESTS =====

  test "session persists across requests" do
    # Login
    post sessions_create_url, params: {
      email: @godmother.email,
      password: 'test_password_123456'
    }

    # Make another request
    get people_url
    assert_response :success
    assert_not_nil session[:person_id]
  end

  test "login redirects to last attempted URL" do
    # Try to access protected page
    get people_url
    assert_redirected_to controller: 'sessions', action: 'new'

    # Verify the last URL was stored
    last_url = session[:last]
    assert_not_nil last_url

    # Login
    post sessions_create_url, params: {
      email: @godmother.email,
      password: 'test_password_123456'
    }

    # Should redirect to the originally requested page
    assert_redirected_to last_url
  end

  # ===== HELPER METHOD TESTS =====

  test "current_person is nil when not logged in" do
    get sessions_new_url
    # We can't directly test controller helpers in integration tests,
    # but we can test the behavior
    assert_nil session[:person_id]
  end

  test "godmother? returns false when not logged in" do
    # Not logged in, try to access protected page
    get people_url
    assert_redirected_to controller: 'sessions', action: 'new'
  end
end
