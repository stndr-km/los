# frozen_string_literal: true

module Customers
  class CustomersController < ApplicationController
    before_action :require_login

    def dashboard
      @customers = CustomerInfo.all
      @customer_data = @customers.group_by_month(:created_at).count.map {|date, count| [date.to_time.to_i * 1000, count] }
    end

    def customer_list
      @loan_profiles = if current_user.role.downcase == "admin"
                         LoanProfile.select(:customer_info_id, :name, :mobile, :partner_name, :lender_name, :status, :amount_offered, :external_loan_id, :message, :rejection_reason, :created_at)
                                    .order("customer_info_id DESC")
                                    .page(params[:page]).per(10)
                       else
                         LoanProfile.select(:customer_info_id, :name, :mobile, :lender_name, :status, :amount_offered, :external_loan_id, :message, :rejection_reason, :created_at)
                                    .where(partner_name: current_user.code)
                                    .order("customer_info_id DESC")
                                    .page(params[:page]).per(10)
                       end

      render json: @loan_profiles.as_json(only: %i[customer_info_id name mobile partner_name lender_name status amount_offered external_loan_id message rejection_reason created_at])
    end

    def filter_list
      key = params[:key]
      value = params[:value]

      valid_keys = %w[customer_info_id partner_name lender_name external_loan_id mobile name status]
      unless valid_keys.include?(key)
        render json: {error: "Invalid key for filtering"}, status: :bad_request
        return
      end

      @loan_profiles = if current_user.role.downcase == "admin"
                         LoanProfile.select(:customer_info_id, :name, :mobile, :partner_name, :lender_name, :status, :amount_offered, :external_loan_id, :message, :rejection_reason, :created_at)
                                    .where(key => value)
                                    .order("customer_info_id DESC")
                                    .page(params[:page]).per(10)
                       else
                         LoanProfile.select(:customer_info_id, :name, :mobile, :lender_name, :status, :amount_offered, :external_loan_id, :message, :rejection_reason, :created_at)
                                    .where(partner_name: current_user.code)
                                    .where(key => value)
                                    .order("customer_info_id DESC")
                                    .page(params[:page]).per(10)
                       end

      render json: @loan_profiles.as_json(only: %i[customer_info_id name mobile partner_name lender_name status amount_offered external_loan_id message rejection_reason created_at])
    end

    def update
      customer_info = CustomerInfo.find(params[:id])
      if customer_info.update(customer_info_params)
        render json: customer_info, status: :ok
      else
        render json: customer_info.errors, status: :unprocessable_entity
      end
    end

    private

    def require_login
      return if current_user

      flash[:error] = "You must be logged in to access this page."
      redirect_to "/user_login"
    end

    def customer_info_params
      params.require(:customer_info).permit(:first_name, :last_name, :dob, :pan_number, :mobile, :email, :guardian_name, :gender, :education_level, :home_city, :home_state, :business_city, :loan_amount,
                                            :insurance, :shop_type, :business_type, :guardian_occupation, :shop_road_type, :shop_img_url, :other_occupation, :monthly_income, :business_state,
                                            :type_of_loan, :home_address, :home_pincode, :business_address, :business_pincode, :partner_code, :company_name, :employment_type, :salary_received_type)
            .merge(latitude: params[:latitude], longitude: params[:longitude], accuracy: params[:accuracy], occupation_category: params[:occupation_category], relation_with_guardian: params[:relation_with_guardian], loan_category: params[:loan_category])
    end
  end
end
