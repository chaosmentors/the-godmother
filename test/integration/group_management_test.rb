require 'test_helper'

class GroupManagementTest < ActionDispatch::IntegrationTest
  setup do
    @godmother = people(:godmother)
    @mentor = people(:mentor_waiting)
    @mentee = people(:mentee_waiting)

    # Login as godmother for all tests
    post sessions_create_url, params: {
      email: @godmother.email,
      password: 'test_password_123456'
    }
  end

  # ===== BASIC GROUP CREATION TESTS =====

  test "godmother can create a group with a mentor" do
    assert_difference 'Group.count', 1 do
      post groups_url, params: {
        group: {
          mentor_id: @mentor.id,
          label: 'Test Group'
        }
      }
    end

    group = Group.last
    assert_equal @mentor.id, group.mentor_id
    assert_equal 'Test Group', group.label
    assert_response :redirect
    assert_match %r{/groups/#{group.id}}, @response.redirect_url
  end

  test "cannot create group without mentor" do
    assert_no_difference 'Group.count' do
      post groups_url, params: {
        group: {
          label: 'No Mentor Group'
        }
      }
    end

    assert_response :redirect
    assert_match %r{/groups/new}, @response.redirect_url
    follow_redirect!
    assert_match /must select a mentor/i, response.body.downcase
  end

  test "group can be created without mentees initially" do
    assert_difference 'Group.count', 1 do
      post groups_url, params: {
        group: {
          mentor_id: @mentor.id,
          label: 'Mentor Only Group'
        }
      }
    end

    group = Group.last
    assert_equal 0, group.mentees.count
  end

  # ===== STATE MANAGEMENT TESTS - GROUP CREATION =====

  test "mentor state changes to in_group when assigned to group" do
    assert_equal 4, @mentor.state  # waiting state before

    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }

    @mentor.reload
    assert_equal 5, @mentor.state  # in_group state after
  end

  test "mentee state changes to in_group when added to group" do
    # Create group with mentor via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }
    group = Group.last

    assert_equal 4, @mentee.state  # waiting state before
    assert_nil @mentee.group_id

    # Add mentee to group
    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group',
        mentee_ids: [@mentee.id]
      }
    }

    @mentee.reload
    assert_equal 5, @mentee.state  # in_group state after
    assert_equal group.id, @mentee.group_id
  end

  test "multiple mentees all get in_group state when added" do
    # Create another mentee
    mentee2 = Person.create!(
      name: 'Second Mentee',
      email: 'mentee2@example.com',
      about: 'Another mentee',
      role: 1,
      state: 4,  # waiting
      has_conference_ticket: true
    )

    # Create group via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Multi Mentee Group'
      }
    }
    group = Group.last

    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Multi Mentee Group',
        mentee_ids: [@mentee.id, mentee2.id]
      }
    }

    @mentee.reload
    mentee2.reload

    assert_equal 5, @mentee.state
    assert_equal 5, mentee2.state
    assert_equal group.id, @mentee.group_id
    assert_equal group.id, mentee2.group_id
  end

  # ===== STATE MANAGEMENT TESTS - REMOVING FROM GROUP =====

  test "mentee state changes back to waiting when removed from group" do
    # Create group with mentee via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }
    group = Group.last

    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group',
        mentee_ids: [@mentee.id]
      }
    }

    @mentee.reload
    assert_equal 5, @mentee.state  # in_group

    # Remove mentee from group via controller
    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group',
        mentee_ids: []
      }
    }

    @mentee.reload
    assert_equal 4, @mentee.state  # waiting state
    assert_nil @mentee.group_id
  end

  test "mentor state changes back to waiting when removed from group" do
    # Create group via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }
    group = Group.last

    @mentor.reload
    assert_equal 5, @mentor.state  # in_group

    # Create another mentor to replace
    mentor2 = Person.create!(
      name: 'Second Mentor',
      email: 'mentor2@example.com',
      about: 'Another mentor',
      role: 2,
      state: 4,  # waiting
      has_conference_ticket: true
    )

    # Replace mentor via controller
    patch group_url(group), params: {
      group: {
        mentor_id: mentor2.id,
        label: 'Test Group',
        mentee_ids: []
      }
    }

    @mentor.reload
    mentor2.reload

    assert_equal 4, @mentor.state  # waiting state
    assert_equal 5, mentor2.state  # in_group state
  end

  # ===== STATE MANAGEMENT TESTS - GROUP DELETION =====

  test "mentor state changes back to waiting when group is deleted" do
    # Create group via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }
    group = Group.last

    @mentor.reload
    assert_equal 5, @mentor.state  # in_group

    # Delete group
    delete group_url(group)

    @mentor.reload
    assert_equal 4, @mentor.state  # waiting state
    assert_nil Group.find_by(id: group.id)
  end

  test "mentee state changes back to waiting when group is deleted" do
    # Create group and add mentee via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }
    group = Group.last

    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group',
        mentee_ids: [@mentee.id]
      }
    }

    @mentee.reload
    assert_equal 5, @mentee.state  # in_group

    # Delete group
    delete group_url(group)

    @mentee.reload
    assert_equal 4, @mentee.state  # waiting state
    assert_nil @mentee.group_id
  end

  test "all group members return to waiting state when group is deleted" do
    mentee2 = Person.create!(
      name: 'Second Mentee',
      email: 'mentee2@example.com',
      about: 'Another mentee',
      role: 1,
      state: 4,
      has_conference_ticket: true
    )

    # Create group via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Full Group'
      }
    }
    group = Group.last

    # Add mentees via controller
    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Full Group',
        mentee_ids: [@mentee.id, mentee2.id]
      }
    }

    @mentor.reload
    @mentee.reload
    mentee2.reload

    assert_equal 5, @mentor.state
    assert_equal 5, @mentee.state
    assert_equal 5, mentee2.state

    # Delete group
    delete group_url(group)

    @mentor.reload
    @mentee.reload
    mentee2.reload

    assert_equal 4, @mentor.state
    assert_equal 4, @mentee.state
    assert_equal 4, mentee2.state
  end

  # ===== VALIDATION TESTS =====

  test "only people with conference tickets can be assigned to groups" do
    # Create mentor without conference ticket
    mentor_no_ticket = Person.create!(
      name: 'No Ticket Mentor',
      email: 'noticket@example.com',
      about: 'Mentor without ticket',
      role: 2,
      state: 4,
      has_conference_ticket: false
    )

    assert_no_difference 'Group.count' do
      post groups_url, params: {
        group: {
          mentor_id: mentor_no_ticket.id,
          label: 'Test Group'
        }
      }
    end

    assert_response :redirect
    assert_match %r{/groups/new}, @response.redirect_url
    follow_redirect!
    assert_match /not available/i, response.body.downcase
  end

  test "people already in groups cannot be assigned to new groups" do
    # Create first group with mentor via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'First Group'
      }
    }
    group1 = Group.last

    # Add mentee to first group
    patch group_url(group1), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'First Group',
        mentee_ids: [@mentee.id]
      }
    }

    @mentor.reload
    @mentee.reload
    assert_equal 5, @mentor.state
    assert_equal 5, @mentee.state

    # Try to assign same mentor to another group - create with different mentor
    mentor2 = Person.create!(
      name: 'Available Mentor',
      email: 'available@example.com',
      about: 'Available mentor',
      role: 2,
      state: 4,
      has_conference_ticket: true
    )

    # Create second group with available mentor
    post groups_url, params: {
      group: {
        mentor_id: mentor2.id,
        label: 'Second Group'
      }
    }
    group2 = Group.last

    # Try to add @mentee (currently in group1) - should be filtered by backend
    patch group_url(group2), params: {
      group: {
        mentor_id: mentor2.id,
        label: 'Second Group',
        mentee_ids: [@mentee.id]  # Try to add mentee from another group
      }
    }

    group2.reload
    @mentee.reload

    # Mentee should still be in original group
    assert_equal group1.id, @mentee.group_id
    assert_equal 0, group2.mentees.count
  end

  # ===== GROUP UPDATE TESTS =====

  test "can update group label" do
    # Create group via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Original Label'
      }
    }
    group = Group.last

    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Updated Label'
      }
    }

    group.reload
    assert_equal 'Updated Label', group.label
  end

  test "can add mentees to existing group" do
    # Create group via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }
    group = Group.last

    assert_equal 0, group.mentees.count

    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group',
        mentee_ids: [@mentee.id]
      }
    }

    group.reload
    assert_equal 1, group.mentees.count
    assert_includes group.mentees, @mentee
  end

  # ===== MARKING GROUP AS DONE =====

  test "marking group as done changes all members to done state" do
    # Create group and add mentee via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }
    group = Group.last

    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group',
        mentee_ids: [@mentee.id]
      }
    }

    @mentor.reload
    @mentee.reload
    assert_equal 5, @mentor.state  # in_group
    assert_equal 5, @mentee.state  # in_group

    # Marking as done should send an email to the mentor
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      get "/done/#{group.id}"
    end

    @mentor.reload
    @mentee.reload
    assert_equal 42, @mentor.state  # done state
    assert_equal 42, @mentee.state  # done state
  end

  test "cannot mark group as done if it has no mentees" do
    # Create group via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Empty Group'
      }
    }
    group = Group.last

    get "/done/#{group.id}"

    assert_response :redirect
    assert_match %r{/groups/#{group.id}}, @response.redirect_url
    follow_redirect!
    assert_match /at least one mentee/i, response.body.downcase

    @mentor.reload
    assert_not_equal 42, @mentor.state  # should still be in_group
  end

  # ===== EDGE CASES =====

  test "deleting a person in a group should fail" do
    # Create group and add mentee via controller
    post groups_url, params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group'
      }
    }
    group = Group.last

    patch group_url(group), params: {
      group: {
        mentor_id: @mentor.id,
        label: 'Test Group',
        mentee_ids: [@mentee.id]
      }
    }

    @mentee.reload
    assert_equal 5, @mentee.state

    # Try to delete mentee who is in a group
    assert_no_difference 'Person.count' do
      delete person_url(@mentee.random_id)
    end

    assert_response :redirect
    assert_match %r{/people/#{@mentee.random_id}}, @response.redirect_url
    follow_redirect!
    assert_match /in a group/i, response.body.downcase
  end
end
