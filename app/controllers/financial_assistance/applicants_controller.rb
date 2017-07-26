class FinancialAssistance::ApplicantsController < ApplicationController

  before_action :set_current_person

  include UIHelpers::WorkflowController
  include FinancialAssistanceHelper

  before_filter :find, :find_application, :except => [:age_18_to_26] #except the ajax request


  def edit
    @applicant = @application.applicants.find(params[:id])
    render layout: 'financial_assistance'
  end

  def other_questions
    @applicant = @application.applicants.find(params[:id])
    render layout: 'financial_assistance'
  end

  def save_questions
    format_date_params params[:financial_assistance_applicant]
    @applicant = @application.applicants.find(params[:id])
    @applicant.update_attributes!(permit_params(params[:financial_assistance_applicant]))
    redirect_to find_application_path(@application)
  end

  def step
    flash[:error] = nil
    model_name = @model.class.to_s.split('::').last.downcase
    model_params = params[model_name]
    @model.clean_conditional_params(model_params) if model_params.present?
    @model.assign_attributes(permit_params(model_params)) if model_params.present?

    if params.key?(model_name)
      if @model.save(context: "step_#{@current_step.to_i}".to_sym)
        @current_step = @current_step.next_step if @current_step.next_step.present?
        if params[:commit] == "Finish"
          @model.update_attributes!(workflow: { current_step: 1 })
          redirect_to find_applicant_path(@application, @applicant)
        else
          @model.update_attributes!(workflow: { current_step: @current_step.to_i })
          render 'workflow/step', layout: 'financial_assistance'
        end
      else
        @model.assign_attributes(workflow: { current_step: @current_step.to_i })
        @model.save!(validate: false)
        flash[:error] = build_error_messages(@model)
        render 'workflow/step', layout: 'financial_assistance'
      end
    else
      render 'workflow/step', layout: 'financial_assistance'
    end
  end

  def age_18_to_26
    applicant = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:applicant_id])
    render :text => "#{(18..26).include?(applicant.age_of_the_applicant)}"
  end

  private

  def format_date_params model_params
    model_params["pregnancy_due_on"]=Date.strptime(model_params["pregnancy_due_on"].to_s, "%m/%d/%Y") if model_params["pregnancy_due_on"].present?
    model_params["pregnancy_end_on"]=Date.strptime(model_params["pregnancy_end_on"].to_s, "%m/%d/%Y") if model_params["pregnancy_end_on"].present?
    model_params["student_status_end_on"]=Date.strptime(model_params["student_status_end_on"].to_s, "%m/%d/%Y") if model_params["student_status_end_on"].present?
  end

  def build_error_messages(model)
    model.valid?("step_#{@current_step.to_i}".to_sym) ? nil : model.errors.messages.first.flatten.flatten.join(',').gsub(",", " ").titleize
  end

  def find_application
    @application = FinancialAssistance::Application.find(params[:application_id])
  end

  def find
    @applicant = FinancialAssistance::Application.find(params[:application_id]).applicants.find(params[:id])
  end

  def permit_params(attributes)
    attributes.permit!
  end
end