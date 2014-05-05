module Aprimo
  class AudienceMember < Struct.new(:id, :values)
    OBJECT_ID = 9 # 9 == audience member type

    def self.api
      API.new
    end

    def self.metadata
      api.get("/MetaData/#{OBJECT_ID}", "Describe").body
    end

    def self.query(filters, options = {})
      xml = ::Builder::XmlMarkup.new(indent: 2)
      xml.list do
        xml.FilterItems do
          filters.each do |name, operator, value|
            xml.FilterItem(attribute: name, operator: operator, value: value)
          end
          xml.FilterItem(attribute: "pageNumber", value: options[:page_number] || "1")
          xml.FilterItem(attribute: "maxPageSize", value: options[:max_page_size] || "1")
        end
        xml.SortItems do
          xml.SortItem(attribute: "audience_member_id", sortOrder: "0")
        end
      end
      api.post("/Gateway/#{OBJECT_ID}", "Query", xml.target!).
        body[3..-1] # need to strip off some useless encoding bytes
    end

    def self.query_all(filters)
      xml = ::Builder::XmlMarkup.new(indent: 2)
      xml.list do
        xml.FilterItems do
          filters.each do |name, operator, value|
            xml.FilterItem(attribute: name, operator: operator, value: value)
          end
          xml.SortItems do
            xml.SortItem(attribute: "audience_member_id", sortOrder: "0")
          end
        end
      end
      api.post("/Gateway/#{OBJECT_ID}", "Query", xml.target!).
        body[3..-1] # need to strip off some useless encoding bytes
    end

    ## Finds all matching records
    def self.find_all(filters)
      raw_xml = query_all(filters)

      result = []
      Nokogiri(raw_xml).css("AudienceMember").each do |am|
        if am
          values = am.elements.map { |e| [e.name, e.text]}
          result << new(am["ID"], Hash[values])
        end
      end
      result
    end

    ## Finds first matching record
    def self.find(filters)
      raw_xml = query(filters)
      am = Nokogiri(raw_xml).at("AudienceMember")
      if am
        values = am.elements.map { |e| [e.name, e.text]}
        new(am["ID"], Hash[values])
      end
    end

    def self.find_by(aprimo_field, value, extra_conditions = [])
      filters = [[aprimo_field, API::EQUALS, value]] + extra_conditions
      find(filters)
    end

    def self.create(values)
      response =  api.post("/Gateway/#{OBJECT_ID}", "Create", new.xml(values)).body
      [successful?(response), response]
    end

    def update(values)
      response = self.class.api.post("/Gateway/#{OBJECT_ID}", "Update", xml(values)).body
      [self.class.successful?(response), response]
    end

    def xml(params)
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.tag!("ms:list", "xmlns:ms" => self.class.api.uri("/Gateway")) do
        xml.tag!("AudienceMember") do
          xml.tag!("audience_member_id", id)
          params.each do |name, value|
            xml.tag!(name, format(value))
          end
        end
      end

      xml.target!
    end

    protected

    def format(value)
      if value.is_a?(Date)
      value.strftime("%m/%d/%Y")
      elsif value.is_a?(Time)
        value.strftime("%m/%d/%Y %I:%M:%S %p")
      else
        value
      end
    end

    def self.successful?(response)
      Nokogiri(response).at("AudienceMember").try(:[], "Result") == "Success"
    end
  end
end
