class AhsDocsReport
    attr_reader :doc_owner, :user, :doc, :doc_type

    def initialize(doc_type:, user:, doc:, doc_owner:)
      @doc_type = doc_type
      @user = user
      @doc = doc
      @doc_owner = doc_owner
    end


    def call
        HTTParty.post('https://pahixdemo.azurewebsites.net/api/IdeaCrew/SendToAHS', body: xml_payload)
    rescue => e
        Rails.logger.error { "Service unavailable #{e.backtrace}" }
    end

    private

    def xml_payload
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.root {
            xml.type "verification"
                xml.user {
                    xml.id doc_owner.id.to_s
                    xml.hbx_id doc_owner.hbx_id
                    xml.first_name doc_owner.first_name
                    xml.last_name doc_owner.last_name
                    xml.ssn doc_owner.ssn
                    xml.dob doc_owner.dob
                    xml.phone_number doc_owner.phones.first.try(&:full_phone_number) || "123-456-7890"
                }
                xml.document {
                    xml.timestamp Time.now
                    xml.source user.has_hbx_staff_role? ? "admin" : "consumer"
                    xml.document_type doc_type
                    xml.purpose "self attested verification"
                    xml.uri doc.present? ? doc : "no doc uri"
                }
            }
        end
        builder.to_xml
    end
end

    