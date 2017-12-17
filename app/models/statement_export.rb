require 'csv'

class StatementExport
  def self.to_csv(statements, extra)
    fields = BASIC_FIELDS.merge(extra ? EXTRA_FIELDS : {})
    CSV.generate do |csv|
      csv << fields.map { |_, heading| heading }
      statements.each do |statement|
        csv << fields.map { |name, _| format_for_csv(statement.send(name)) }
      end
    end
  end

  def self.format_for_csv(value)
    value.respond_to?(:iso8601) ? value.iso8601 : value
  end

  BASIC_FIELDS = {
    company_name: 'Company',
    url: 'URL',
    sector_name: 'Sector',
    country_name: 'HQ',
    date_seen: 'Date Added'
  }.freeze

  EXTRA_FIELDS = {
    approved_by_board: 'Approved by Board',
    approved_by: 'Approved by',
    signed_by_director: 'Signed by Director',
    signed_by: 'Signed by',
    link_on_front_page: 'Link on Front Page',
    published: 'Published',
    verified_by_email: 'Verified by',
    contributor_email: 'Contributed by',
    broken_url: 'Broken URL'
  }.freeze
end