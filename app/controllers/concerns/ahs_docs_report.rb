class AhsDocsReport
    def self.call(params:, user:, doc:, doc_owner:)
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.root {
            xml.type "verification"
                xml.user {
                    xml.id doc_owner.person.id.to_s
                    xml.hbx_id doc_owner.person.hbx_id
                    xml.ssn doc_owner.person.ssn
                    xml.dob doc_owner.person.dob
                    xml.phone_number doc_owner.person.phones.first.try(&:full_phone_number) || "123-456-7890"
                }
                xml.document {
                    xml.timestamp Time.now
                    xml.source user.has_hbx_staff_role? ? "admin" : "consumer"
                    xml.document_type params[:type_name]
                    xml.purpose "self attested verification"
                    xml.uri doc.present? ? doc : "no doc uri"
                }
            }
        end
        payload = builder.to_xml
        HTTParty.post('https://pahixdemo.azurewebsites.net/api/IdeaCrew/SendToAHS', body: payload)
    end
end

    