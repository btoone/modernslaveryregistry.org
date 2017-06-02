require 'rails_helper'

RSpec.describe Statement, type: :model do
  before do
    allow(ScreenGrab).to receive(:fetch) do |url|
      FetchResult.with(
        url: url,
        broken_url: false,
        content_type: 'image/png',
        content_data: 'image data!'
      )
    end
    @sw = Sector.create! name: 'Software'
    @gb = Country.create! code: 'GB', name: 'United Kingdom'
    @company = Company.create! name: 'Cucumber Ltd', country_id: @gb.id, sector_id: @sw.id
  end

  it 'converts url to https if it exists' do
    VCR.use_cassette('cucumber.io') do
      statement = @company.statements.create!(url: 'http://cucumber.io/',
                                              approved_by: 'Big Boss',
                                              approved_by_board: 'Yes',
                                              signed_by_director: false,
                                              link_on_front_page: true,
                                              date_seen: Date.parse('21 May 2016'),
                                              contributor_email: 'anon@host.com')

      expect(statement.url).to eq('https://cucumber.io/')
    end
  end

  it 'does not validate admin-only visible fields for non-admins' do
    VCR.use_cassette('cucumber.io') do
      statement = @company.statements.create(url: 'http://cucumber.io/',
                                             verified_by: nil,
                                             contributor_email: 'anon@host.com')

      expect(statement.errors.messages).to eq({})
    end
  end

  it 'validates admin-only visible fields for admins' do
    VCR.use_cassette('cucumber.io') do
      user = User.create!(first_name: 'Super',
                          last_name: 'Admin',
                          email: 'admin@somewhere.com',
                          password: 'whatevs',
                          admin: true)

      statement = @company.statements.create(url: 'http://cucumber.io/',
                                             verified_by: user,
                                             contributor_email: 'somebody@host.com')

      expect(statement.errors.messages).to eq(approved_by_board: ['is not included in the list'],
                                              link_on_front_page: ['is not included in the list'],
                                              signed_by_director: ['is not included in the list'])
    end
  end

  it 'turns rows into CSV' do
    VCR.use_cassette('cucumber.io') do
      user = User.create!(first_name: 'Someone',
                          last_name: 'Smith',
                          email: 'someone@somewhere.com',
                          password: 'whatevs')

      @company.statements.create!(url: 'http://cucumber.io/',
                                  approved_by: 'Big Boss',
                                  approved_by_board: 'Yes',
                                  signed_by_director: false,
                                  link_on_front_page: true,
                                  verified_by: user,
                                  date_seen: Date.parse('2017-03-22'),
                                  published: true)

      statements = Statement.newest.published.includes(company: %i[sector country])
      csv = Statement.to_csv(statements, false)

      expect(csv).to eq(<<~CSV
        Company,URL,Sector,HQ,Date Added
        Cucumber Ltd,https://cucumber.io/,Software,United Kingdom,2017-03-22
CSV
                       )
    end
  end

  it 'turns rows into CSV with more rows for admins' do
    VCR.use_cassette('cucumber.io') do
      user = User.create!(first_name: 'Super',
                          last_name: 'Admin',
                          email: 'admin@somewhere.com',
                          password: 'whatevs',
                          admin: true)

      @company.statements.create!(url: 'http://cucumber.io/',
                                  approved_by: 'Big Boss',
                                  approved_by_board: 'Yes',
                                  signed_by_director: false,
                                  signed_by: 'Little Boss',
                                  link_on_front_page: true,
                                  verified_by: user,
                                  contributor_email: 'contributor@somewhere.com',
                                  date_seen: Date.parse('2017-03-22'),
                                  published: true)

      statements = Statement.newest.published.includes(company: %i[sector country])
      csv = Statement.to_csv(statements, true)

      expect(csv).to eq(<<~CSV
        Company,URL,Sector,HQ,Date Added,Approved by Board,Approved by,Signed by Director,Signed by,Link on Front Page,Published,Verified by,Contributed by,Broken URL
        Cucumber Ltd,https://cucumber.io/,Software,United Kingdom,2017-03-22,Yes,Big Boss,false,Little Boss,true,true,admin@somewhere.com,contributor@somewhere.com,false
CSV
                       )
    end
  end
end
