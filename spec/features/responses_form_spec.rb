require 'spec_helper'

feature 'responses form' do
  before do
    @user = create(:user)
  end

  describe 'general' do # This should be refactored to split into different scenarios.
    before do
      @form = create(:form, question_types: %w(select_one multi_level_select_one select_multiple integer decimal location text long_text datetime date time))
      @qings = @form.questionings
      @form.publish!
      login(@user)
    end

    scenario 'should work', js: true do
      click_link('Submit')
      click_link(@form.name)
      expect(page).to have_selector('h1', text: 'New Response')
      select(@user.name, from: 'response_user_id')

      # Fill in answers
      select('Dog', from: 'response_answers_attributes_0_option_id')

      select('Plant', from: 'response_answers_attributes_1_0_option_id')
      select('Oak', from: 'response_answers_attributes_1_1_option_id')

      check('response_answers_attributes_2_choices_attributes_0_checked') # Cat
      fill_in('response_answers_attributes_3_value', with: '10')
      fill_in('response_answers_attributes_4_value', with: '10.2')
      fill_in('response_answers_attributes_5_value', with: '42.277976 -83.817573')
      fill_in('response_answers_attributes_6_value', with: 'Foo')
      fill_in_ckeditor('response_answers_attributes_7_value', with: "Foo Bar\nBaz")

      select(Time.now.year, from: 'response_answers_attributes_8_datetime_value_1i')
      select('March', from: 'response_answers_attributes_8_datetime_value_2i')
      select('12', from: 'response_answers_attributes_8_datetime_value_3i')
      select('18', from: 'response_answers_attributes_8_datetime_value_4i')
      select('32', from: 'response_answers_attributes_8_datetime_value_5i')

      select(Time.now.year, from: 'response_answers_attributes_9_date_value_1i')
      select('October', from: 'response_answers_attributes_9_date_value_2i')
      select('26', from: 'response_answers_attributes_9_date_value_3i')

      select('03', from: 'response_answers_attributes_10_time_value_4i')
      select('08', from: 'response_answers_attributes_10_time_value_5i')

      # Save and check it worked.
      click_button('Save')
      expect(page).to have_selector('h1', text: 'Response')

      # Check show mode.
      click_link(Response.first.id.to_s)
      check_response_show_form('Dog', %w(Plant Oak), 'Cat', '10', '10.2', '42.277976 -83.817573', 'Foo',
        "Foo Bar Baz", "Mar 12 #{Time.now.year} 18:32", "Oct 26 #{Time.now.year}", "03:08")

      # Check edit mode.
      click_link('Edit Response')
      select('Animal', from: 'response_answers_attributes_1_0_option_id')
      select('Cat', from: 'response_answers_attributes_1_1_option_id')
      uncheck('response_answers_attributes_2_choices_attributes_0_checked') # Cat
      check('response_answers_attributes_2_choices_attributes_1_checked') # Dog
      click_button('Save')

      # Check that change occurred.
      click_link(Response.first.id.to_s)
      check_response_show_form('Dog', %w(Animal Cat), 'Dog', '10', '10.2', '42.277976 -83.817573', 'Foo',
        "Foo Bar Baz", "Mar 12 #{Time.now.year} 18:32", "Oct 26 #{Time.now.year}", "03:08")

      # Delete.
      click_link('Delete Response')
      page.driver.browser.switch_to.alert.accept
      expect(page).to have_selector('.alert-success', text: 'deleted')
    end
  end

  describe 'hidden questions' do
    before do
      @form = create(:form, question_types: %w(text text))
      @qing0, @qing1 = @form.questionings
      @qing1.update_attributes(hidden: true, required: true) # Being required shouldn't make a difference.
      @form.publish!
      login(@user)
    end

    scenario 'should be properly ignored' do
      visit(new_response_path(locale: 'en', mode: 'm', mission_name: get_mission.compact_name, form_id: @form.id))
      expect(page).not_to have_selector("div.form_field#qing_#{@qing1.id}")
      select(@user.name, from: 'response_user_id')
      fill_in('response_answers_attributes_0_value', with: 'Foo')
      click_button('Save')

      # Ensure response saved properly.
      click_link(Response.first.id.to_s)
      expect(page).not_to have_selector("div.form_field#qing_#{@qing1.id}")
      expect(page).to have_selector("div.form_field#qing_#{@qing0.id} .ro-val", text: 'Foo')
    end
  end

  def check_response_show_form(*values)
    values.each_with_index{ |v,i| expect_answer(i, v) }
  end

  def expect_answer(qing_idx, value)
    qing = @qings[qing_idx]
    csscls = qing.multi_level? ? 'option-name' : 'ro-val'
    Array.wrap(value).each do |v|
      expect(page).to have_selector("#qing_#{qing.id} .#{csscls}", text: /^#{Regexp.escape(v)}$/)
    end
  end
end
