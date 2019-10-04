require 'rails_helper'

describe Api::V1::PeopleController do
  render_views
  let(:ssn) { "#{rand(100..399)}-55-#{rand(1000..3999)}" }
  let(:person) { FactoryGirl.create :person, ssn: ssn }

  context 'valid with downcased first name, downcased last name and dob' do
    before do
      post :search, person: { first_name: person.first_name.downcase,
                              last_name: person.last_name.downcase,
                              dob: person.dob }
    end

    it 'finds and returns the right person' do
      expect(assigns[:person]).to eq(person)
    end
  end

  context 'valid with ssn' do
    before do
      post :search, person: { ssn: person.ssn }
    end

    it 'finds and returns the right person' do
      expect(assigns[:person]).to eq(person)
    end
  end

  context 'invalid with only first and last names' do
    before do
      post :search, person: { first_name: person.first_name, last_name: person.last_name }
    end

    it 'responds with a 406' do
      expect(response).to have_http_status(406)
    end
  end

  context 'a search that finds nothing' do
    before do
      post :search, person: { ssn: '555-55-5555' }
    end

    it 'responds with a 404' do
      expect(response).to have_http_status(404)
    end
  end
end

