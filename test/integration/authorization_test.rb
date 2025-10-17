require 'test_helper'

class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @godmother = people(:godmother)
    @mentor = people(:mentor_waiting)
    @mentee = people(:mentee_waiting)
  end

  # Helper to login as godmother
  def login_as_godmother
    post sessions_create_url, params: {
      email: @godmother.email,
      password: 'test_password_123456'
    }
  end

  # ===== PUBLIC ACCESS TESTS (Should Work Without Login) =====

  test "anyone can access registration page" do
    get new_person_url
    assert_response :success
  end

  test "anyone can submit registration" do
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    assert_difference 'Person.count', 1 do
      post people_url, params: {
        person: {
          name: 'Public User',
          email: 'public@example.com',
          about: 'Testing public access',
          role_id: 2
        },
        number: 0,
        address: captcha_answer
      }
    end

    assert_redirected_to root_path
  end

  test "anyone can verify their email" do
    get "/verify_email/#{@mentor.verification_token}"
    assert_redirected_to root_path
  end

  test "anyone can access login page" do
    get sessions_new_url
    assert_response :success
  end

  # ===== PEOPLE CONTROLLER - PROTECTED ACTIONS =====

  test "unauthenticated user cannot access people index" do
    get people_url
    assert_redirected_to controller: 'sessions', action: 'new'
    follow_redirect!
    assert_match /must be logged in/i, response.body.downcase
  end

  test "unauthenticated user cannot view person details" do
    get person_url(@mentor.random_id)
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot edit person" do
    get edit_person_url(@mentor.random_id)
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot update person" do
    patch person_url(@mentor.random_id), params: {
      person: { name: 'Hacked Name' }
    }
    assert_redirected_to controller: 'sessions', action: 'new'

    # Verify person was NOT updated
    @mentor.reload
    assert_not_equal 'Hacked Name', @mentor.name
  end

  test "unauthenticated user cannot delete person" do
    assert_no_difference 'Person.count' do
      delete person_url(@mentor.random_id)
    end
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot change person state" do
    original_state = @mentor.state

    get "/change_state/#{@mentor.random_id}/5"
    assert_redirected_to controller: 'sessions', action: 'new'

    # Verify state was NOT changed
    @mentor.reload
    assert_equal original_state, @mentor.state
  end

  test "unauthenticated user cannot access people search" do
    get search_url
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot send password reset" do
    post send_password_reset_person_url(@godmother.random_id)
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  # ===== GROUPS CONTROLLER - ALL ACTIONS PROTECTED =====

  test "unauthenticated user cannot access groups index" do
    get groups_url
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot view group" do
    # Create a group first (requires login)
    login_as_godmother
    group = Group.create!(mentor_id: @mentor.id, label: 'Test Group')
    get sessions_destroy_url  # Logout

    get group_url(group)
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot create group" do
    get new_group_url
    assert_redirected_to controller: 'sessions', action: 'new'

    assert_no_difference 'Group.count' do
      post groups_url, params: {
        group: { mentor_id: @mentor.id, label: 'Hacked Group' }
      }
    end
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot edit group" do
    login_as_godmother
    group = Group.create!(mentor_id: @mentor.id, label: 'Test Group')
    get sessions_destroy_url  # Logout

    get edit_group_url(group)
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot update group" do
    login_as_godmother
    group = Group.create!(mentor_id: @mentor.id, label: 'Original Label')
    get sessions_destroy_url  # Logout

    patch group_url(group), params: {
      group: { mentor_id: @mentor.id, label: 'Hacked Label' }
    }
    assert_redirected_to controller: 'sessions', action: 'new'

    # Verify group was NOT updated
    group.reload
    assert_equal 'Original Label', group.label
  end

  test "unauthenticated user cannot delete group" do
    login_as_godmother
    group = Group.create!(mentor_id: @mentor.id, label: 'Test Group')
    group_id = group.id
    get sessions_destroy_url  # Logout

    assert_no_difference 'Group.count' do
      delete group_url(group)
    end
    assert_redirected_to controller: 'sessions', action: 'new'

    # Verify group still exists
    assert Group.exists?(group_id)
  end

  test "unauthenticated user cannot mark group as done" do
    login_as_godmother
    group = Group.create!(mentor_id: @mentor.id, mentee_ids: [@mentee.id], label: 'Test Group')
    get sessions_destroy_url  # Logout

    get "/done/#{group.id}"
    assert_redirected_to controller: 'sessions', action: 'new'

    # Verify person states were NOT changed to done
    @mentor.reload
    @mentee.reload
    assert_not_equal Person.state_id(:done), @mentor.state
    assert_not_equal Person.state_id(:done), @mentee.state
  end

  test "unauthenticated user cannot batch create groups" do
    get batch_create_groups_url
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot access CSV group import" do
    get csv_batch_create_groups_url
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  test "unauthenticated user cannot upload CSV for group import" do
    # Just test without actual file - the important part is that it's blocked
    post csv_batch_create_groups_url, params: {}
    assert_redirected_to controller: 'sessions', action: 'new'
  end

  # ===== GODMOTHER ACCESS TESTS (Should Work With Login) =====

  test "godmother can access people index" do
    login_as_godmother
    get people_url
    assert_response :success
  end

  test "godmother can view person details" do
    login_as_godmother
    get person_url(@mentor.random_id)
    assert_response :success
  end

  test "godmother can access groups index" do
    login_as_godmother
    get groups_url
    assert_response :success
  end

  test "godmother can create new group" do
    login_as_godmother
    get new_group_url
    assert_response :success
  end

  test "godmother can edit person" do
    login_as_godmother
    get edit_person_url(@mentor.random_id)
    assert_response :success
  end

  test "godmother can update person" do
    login_as_godmother
    original_name = @mentor.name

    patch person_url(@mentor.random_id), params: {
      person: {
        name: 'Updated Name',
        email: @mentor.email,
        about: @mentor.about,
        role_id: @mentor.role
      }
    }

    @mentor.reload
    assert_equal 'Updated Name', @mentor.name
  end

  test "godmother can delete person not in group" do
    login_as_godmother

    # Create a person without a group
    person_to_delete = Person.create!(
      name: 'Deletable Person',
      email: 'deletable@example.com',
      about: 'Will be deleted',
      role: 2,
      state: 4
    )

    assert_difference 'Person.count', -1 do
      delete person_url(person_to_delete.random_id)
    end

    assert_response :redirect
    assert_match %r{/people}, @response.redirect_url
  end

  test "godmother can change person state" do
    login_as_godmother
    original_state = @mentor.state

    get "/change_state/#{@mentor.random_id}/#{Person.state_id(:okay)}"

    @mentor.reload
    assert_equal Person.state_id(:okay), @mentor.state
    assert_not_equal original_state, @mentor.state
  end

  test "godmother can access batch create groups" do
    login_as_godmother
    get batch_create_groups_url
    assert_response :redirect
    assert_match %r{/groups}, @response.redirect_url
  end

  test "godmother can access CSV group import page" do
    login_as_godmother
    get csv_batch_create_groups_url
    assert_response :success
  end
end
