require 'test_helper'

class ParticipantRegistrationTest < ActionDispatch::IntegrationTest
  setup do
    @mentor_params = {
      person: {
        name: 'New Mentor',
        pronoun: 'she/her',
        email: 'newmentor@example.com',
        about: 'I am an experienced developer who wants to mentor',
        role_id: 2,  # mentor role
        tag_list: 'ruby, rails'
      }
    }

    @mentee_params = {
      person: {
        name: 'New Mentee',
        pronoun: 'they/them',
        email: 'newmentee@example.com',
        about: 'I am new to tech and looking for guidance',
        role_id: 1,  # mentee role
        tag_list: 'python, learning'
      }
    }
  end

  # ===== ACCESS TESTS =====

  test "anyone can access mentor registration page" do
    get new_person_url(r: 'mentor')
    assert_response :success
    assert_select 'form'
  end

  test "anyone can access mentee registration page" do
    get new_person_url(r: 'mentee')
    assert_response :success
    assert_select 'form'
  end

  test "registration page defaults to mentee when no role specified" do
    get new_person_url
    assert_response :success
    assert_select 'form'
  end

  # ===== SUCCESSFUL REGISTRATION TESTS =====

  test "mentor can register with valid data and captcha" do
    get new_person_url(r: 'mentor')
    assert_response :success

    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    assert_difference 'Person.count', 1 do
      post people_url, params: @mentor_params.merge({
        number: 0,
        address: captcha_answer
      })
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match /registration/i, response.body.downcase

    # Verify the person was created with correct attributes
    new_person = Person.find_by(email: 'newmentor@example.com')
    assert_not_nil new_person
    assert_equal 'New Mentor', new_person.name
    assert_equal 2, new_person.role  # mentor role
    assert_equal 1, new_person.state  # unverified state initially
    assert_not_nil new_person.verification_token
  end

  test "mentee can register with valid data and captcha" do
    get new_person_url(r: 'mentee')
    assert_response :success

    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    assert_difference 'Person.count', 1 do
      post people_url, params: @mentee_params.merge({
        number: 0,
        address: captcha_answer
      })
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match /registration/i, response.body.downcase

    # Verify the person was created with correct attributes
    new_person = Person.find_by(email: 'newmentee@example.com')
    assert_not_nil new_person
    assert_equal 'New Mentee', new_person.name
    assert_equal 1, new_person.role  # mentee role
    assert_equal 1, new_person.state  # unverified state initially
    assert_not_nil new_person.verification_token
  end

  # ===== CAPTCHA VALIDATION TESTS =====

  test "mentor registration fails with wrong captcha" do
    get new_person_url(r: 'mentor')
    assert_response :success

    assert_no_difference 'Person.count' do
      post people_url, params: @mentor_params.merge({
        number: 0,
        address: 'wrong answer'
      })
    end

    assert_response :success  # renders the form again
    assert_match /human|question/i, response.body.downcase
  end

  test "mentee registration fails with wrong captcha" do
    get new_person_url(r: 'mentee')
    assert_response :success

    assert_no_difference 'Person.count' do
      post people_url, params: @mentee_params.merge({
        number: 0,
        address: 'wrong answer'
      })
    end

    assert_response :success  # renders the form again
    assert_match /human|question/i, response.body.downcase
  end

  # ===== DUPLICATE EMAIL TESTS =====

  test "mentor registration fails with duplicate email" do
    existing_email = people(:mentor_waiting).email

    get new_person_url(r: 'mentor')
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    assert_no_difference 'Person.count' do
      post people_url, params: {
        person: @mentor_params[:person].merge(email: existing_email),
        number: 0,
        address: captcha_answer
      }
    end

    assert_response :success
    assert_match /email/i, response.body.downcase
  end

  test "mentee registration fails with duplicate email" do
    existing_email = people(:mentee_waiting).email

    get new_person_url(r: 'mentee')
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    assert_no_difference 'Person.count' do
      post people_url, params: {
        person: @mentee_params[:person].merge(email: existing_email),
        number: 0,
        address: captcha_answer
      }
    end

    assert_response :success
    assert_match /email/i, response.body.downcase
  end

  test "cannot register with same email across different roles" do
    # Register as mentor first
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    post people_url, params: @mentor_params.merge({
      number: 0,
      address: captcha_answer
    })

    # Try to register as mentee with same email
    assert_no_difference 'Person.count' do
      post people_url, params: {
        person: @mentee_params[:person].merge(email: 'newmentor@example.com'),
        number: 0,
        address: captcha_answer
      }
    end

    assert_response :success
    assert_match /email/i, response.body.downcase
  end

  # ===== REQUIRED FIELDS VALIDATION TESTS =====

  test "mentor registration fails without required fields" do
    get new_person_url(r: 'mentor')
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    assert_no_difference 'Person.count' do
      post people_url, params: {
        person: {
          name: '',  # missing required name
          email: 'test@example.com',
          about: '',  # missing required about
          role_id: 2
        },
        number: 0,
        address: captcha_answer
      }
    end

    assert_response :success  # renders form with errors
  end

  test "mentee registration fails without required fields" do
    get new_person_url(r: 'mentee')
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    assert_no_difference 'Person.count' do
      post people_url, params: {
        person: {
          name: 'Valid Name',
          email: '',  # missing required email
          about: 'Valid about',
          role_id: 1
        },
        number: 0,
        address: captcha_answer
      }
    end

    assert_response :success  # renders form with errors
  end

  # ===== EMAIL VERIFICATION TESTS =====

  test "mentor can verify email with valid token" do
    # Create an unverified mentor
    get new_person_url(r: 'mentor')
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    post people_url, params: @mentor_params.merge({
      number: 0,
      address: captcha_answer
    })

    new_person = Person.find_by(email: 'newmentor@example.com')
    assert_equal 1, new_person.state  # unverified
    assert_nil new_person.validated_at

    # Verify email with token
    get "/verify_email/#{new_person.verification_token}"

    assert_redirected_to root_path
    follow_redirect!
    assert_match /verified/i, response.body.downcase

    # Check person state changed to waiting
    new_person.reload
    assert_equal 4, new_person.state  # waiting state
    assert_not_nil new_person.validated_at
  end

  test "mentee can verify email with valid token" do
    # Create an unverified mentee
    get new_person_url(r: 'mentee')
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    post people_url, params: @mentee_params.merge({
      number: 0,
      address: captcha_answer
    })

    new_person = Person.find_by(email: 'newmentee@example.com')
    assert_equal 1, new_person.state  # unverified
    assert_nil new_person.validated_at

    # Verify email with token
    get "/verify_email/#{new_person.verification_token}"

    assert_redirected_to root_path
    follow_redirect!
    assert_match /verified/i, response.body.downcase

    # Check person state changed to waiting
    new_person.reload
    assert_equal 4, new_person.state  # waiting state
    assert_not_nil new_person.validated_at
  end

  test "email verification fails with invalid token" do
    get "/verify_email/invalid_token"

    assert_redirected_to root_path
    follow_redirect!
    # The page shows a message about the verification link not being valid
    assert_match /link|contact/i, response.body.downcase
  end

  test "email verification shows message if already verified" do
    verified_person = people(:mentor_waiting)

    get "/verify_email/#{verified_person.verification_token}"

    assert_redirected_to root_path
    follow_redirect!
    assert_match /already/i, response.body.downcase
  end

  # ===== SECURITY TESTS =====

  test "participants cannot register as godmother without authentication" do
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    # Try to register as godmother (role 3)
    post people_url, params: {
      person: {
        name: 'Hacker',
        email: 'hacker@example.com',
        about: 'Trying to be godmother',
        role_id: 3,  # godmother role
        is_godmother: true
      },
      number: 0,
      address: captcha_answer
    }

    # Should render form with error, not create godmother
    assert_response :success
    assert_match /nice try/i, response.body.downcase

    # Verify no godmother was created
    hacker = Person.find_by(email: 'hacker@example.com')
    assert_nil hacker
  end

  test "mentees cannot set themselves as godmothers" do
    captcha_answer = I18n.t('captcha_questions')[0][:answer]

    # Login as godmother to bypass registration_open check
    post sessions_create_url, params: {
      email: people(:godmother).email,
      password: 'test_password_123456'
    }

    # Try to create mentee with godmother flag
    post people_url, params: {
      person: {
        name: 'Sneaky Mentee',
        email: 'sneaky@example.com',
        about: 'Trying to be mentee and godmother',
        role_id: 1,  # mentee role
        is_godmother: '1'
      },
      number: 0,
      address: captcha_answer,
      internal: true
    }

    # Should show error
    assert_response :success
    assert_match /mentee.*godmother/i, response.body.downcase
  end
end
