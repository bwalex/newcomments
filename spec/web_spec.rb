require 'spec_helper'

describe "Admin web", :type => :request do
  subject { APP }

  def app
    subject
  end

  before do
    User.create!(
      email: 'root@example.com',
      new_password: 'root',
      new_password_confirmation: 'root',
      admin: true
    )

    User.create!(
      email: 'foo@bar.com',
      new_password: 'foo$!',
      new_password_confirmation: 'foo$!',
      admin: false
    )
  end

  context 'login process' do
    it 'fails if wrong username is provided' do
      visit '/login'
      fill_in 'email', with: 'root'
      fill_in 'password', with: 'root'
      click_on 'Login'

      current_path.should == '/login'
      page.should have_content('Invalid email or password')
    end

    it 'fails if wrong password is provided' do
      visit '/login'
      fill_in 'email', with: 'root@example.com'
      fill_in 'password', with: 'root0'
      click_on 'Login'

      current_path.should == '/login'
      page.should have_content('Invalid email or password')
    end

    it 'works with admin credentials' do
      visit '/login'
      fill_in 'email', with: 'root@example.com'
      fill_in 'password', with: 'root'
      click_on 'Login'

      current_path.should == '/admin/sites'
      page.should have_content('Logout')
    end

    it 'works with other credentials' do
      visit '/login'
      fill_in 'email', with: 'foo@bar.com'
      fill_in 'password', with: 'foo$!'
      click_on 'Login'

      current_path.should == '/admin/sites'
      page.should have_content('Logout')
    end
  end

  context '/admin/sites with admin user' do
    before do
      visit '/login'
      fill_in 'email', with: 'root@example.com'
      fill_in 'password', with: 'root'
      click_on 'Login'
    end

    it 'creates a site if it doesn\'t exist yet' do
      visit '/admin/sites'
      fill_in 'domain', with: 'u.test.com'
      click_on 'Add new site'

      current_path.should == '/admin/sites'
      page.should have_content('Successfully created new site')
      page.should have_link('u.test.com')
      Site.count.should == 1
      Site.first.domain.should == 'u.test.com'
    end
  end


  context '/admin/sites with normal user' do
    before do
      visit '/login'
      fill_in 'email', with: 'foo@bar.com'
      fill_in 'password', with: 'foo$!'
      click_on 'Login'
    end

    it 'doesn\'t allow creating new sites' do
      visit '/admin/sites'
      fill_in 'domain', with: 'u.test.com'
      click_on 'Add new site'

      current_path.should == '/admin/sites'
      page.should have_content('Only a global administrator can create new sites')
      page.should_not have_link('u.test.com')
      Site.count.should == 0
    end
  end

end
