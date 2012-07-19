require 'test_helper'

class NavigationTest < ActiveSupport::IntegrationCase
  test 'user sign up should grant badge to itself' do
    visit '/users/new'
    fill_in 'Name', :with => 'Jack'
    click_button('Create MessagingUser')

    user = MessagingUser.where(:name => 'Jack').first
    assert_equal [Badge.by_name('just-registered').first], user.badges.to_a
  end

  test 'users#index should grant badge multiple times' do
    user = MessagingUser.create(:name => 'test-user')
    visit '/users'
    visit '/users'
    visit '/users'
    visit '/users'
    assert_equal 4, MessagingUser.first.badges.count
  end

  test 'user workflow should grant some badges at some times' do
    # Commented 9 times, no badges yet
    user = MessagingUser.create(:name => 'test-user')
    (1..9).each do |i|
      Comment.create(
        :name    => "Title #{i}",
        :comment => "Comment #{i}",
        :messaging_user_id => user.id,
        :votes   => 8
      )
    end
    assert user.badges.empty?, 'Should not have badges'

    # Make tenth comment, assert 10-commenter badge granted
    visit '/comments/new'
    fill_in 'Name', :with => 'Hi!'
    fill_in 'Comment', :with => 'Hi bro!'
    fill_in 'MessagingUser', :with => user.id
    click_button('Create Comment')

    user = MessagingUser.where(:name => 'test-user').first
    assert_equal [Badge.by_name('commenter').by_level(10).first], user.badges.to_a

    # Vote (to 5) a user's comment, assert relevant-commenter badge granted
    relevant_comment = user.comments.where(:votes => 8).first
    visit '/comments'
    within("tr#c_#{relevant_comment.id}") do
      click_link '2'
    end

    relevant_badge = Badge.by_name('relevant-commenter').first
    user_badges    = MessagingUser.where(:name => 'test-user').first.badges.to_a
    assert user_badges.include?(relevant_badge), "MessagingUser badges: #{user.badges.collect(&:name).inspect} should contain relevant-commenter badge."

    # Edit user's name by long name
    # tests ruby code in grant_on is being executed, and gives badge
    user = MessagingUser.where(:name => 'test-user').first
    user_badges = user.badges.to_a

    visit "/users/#{user.id}/edit"
    fill_in 'Name', :with => 'long_name!'
    click_button('Update MessagingUser')

    user = MessagingUser.where(:name => 'long_name!').first
    autobiographer_badge = Badge.by_name('autobiographer').first
    assert user.badges.to_a.include?(autobiographer_badge), "MessagingUser badges: #{user.badges.collect(&:name).inspect} should contain autobiographer badge."

    # Edit user's name by short name
    # tests ruby code in grant_on is being executed, and removes badge
    visit "/users/#{user.id}/edit"
    fill_in 'Name', :with => 'abc'
    click_button('Update MessagingUser')

    user = MessagingUser.where(:name => 'abc').first
    assert !user.badges.to_a.include?(autobiographer_badge), "MessagingUser badges: #{user.badges.collect(&:name).inspect} should remove autobiographer badge."
  end

  test 'user workflow should add up points at some times' do
    user = MessagingUser.create(:name => 'test-user')
    assert_equal 0, user.points, 'MessagingUser should start with 0 points'

    visit "/users/#{user.id}/edit"
    fill_in 'Name', :with => 'a'
    click_button('Update MessagingUser')

    user = MessagingUser.where(:name => 'a').first
    assert_equal 20, user.points, 'Updating info should grant 20 points'

    visit '/comments/new'
    click_button('Create Comment')

    user = MessagingUser.where(:name => 'a').first
    assert_equal 20, user.points, 'Empty comment should grant no points'

    visit '/comments/new'
    fill_in 'Name', :with => 'Hi!'
    fill_in 'Comment', :with => 'Hi bro!'
    fill_in 'MessagingUser', :with => user.id
    click_button('Create Comment')

    user = MessagingUser.where(:name => 'a').first
    assert_equal 40, user.points, 'Commenting should grant 20 points'

    visit "/comments/#{Comment.last.id}/vote/4"
    user = MessagingUser.first
    assert_equal 45, user.points, 'Voting comments should grant 5 points'
  end

  test 'user workflow should grant levels at some times' do
    user = MessagingUser.create(:name => 'test-user')
    assert user.badges.empty?

    # Edit user's name by 2 chars name
    visit "/users/#{user.id}/edit"
    fill_in 'Name', :with => 'ab'
    click_button('Update MessagingUser')

    user = MessagingUser.where(:name => 'ab').first
    assert_equal 0, user.level, "MessagingUser level should be 0."
    Merit::RankRules.new.check_rank_rules
    user.reload
    assert_equal 2, user.level, "MessagingUser level should be 2."

    # Edit user's name by short name. Doesn't go back to previous rank.
    visit "/users/#{user.id}/edit"
    fill_in 'Name', :with => 'a'
    click_button('Update MessagingUser')

    user = MessagingUser.where(:name => 'a').first
    Merit::RankRules.new.check_rank_rules
    user.reload
    assert_equal 2, user.level, "MessagingUser level should be 2."

    # Edit user's name by 5 chars name
    visit "/users/#{user.id}/edit"
    fill_in 'Name', :with => 'abcde'
    click_button('Update MessagingUser')

    user = MessagingUser.where(:name => 'abcde').first
    Merit::RankRules.new.check_rank_rules
    user.reload
    assert_equal 5, user.level, "MessagingUser level should be 5."
  end
end
