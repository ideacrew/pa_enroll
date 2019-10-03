module Api
  module V1
    class PeopleController < ActionController::Base
      def search
        if has_valid_search_params?
          params[:person][:encrypted_ssn] = Person.encrypt_ssn(params[:person].delete(:ssn)) if params.key?(:person) && params[:person].key?(:ssn)

          if @person = Person.where(params[:person].permit(:dob, :encrypted_ssn, :first_name, :last_name)).first
            render "events/v2/individuals/search", :formats => [ :xml ], :locals => { :individual => @person }
          else
            head :not_found
          end
        else
          head :not_acceptable
        end
      end

      private
      def has_valid_search_params?
        params.key?(:person) &&
          (params[:person].key?(:ssn) ||
            (params[:person].key?(:dob) &&
             params[:person].key?(:first_name) &&
             params[:person].key?(:last_name)))
      end
    end
  end
end
