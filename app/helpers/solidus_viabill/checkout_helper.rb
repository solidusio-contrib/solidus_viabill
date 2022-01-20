# frozen_string_literal: true

module SolidusViabill
  module CheckoutHelper
    VIABILL_PROTOCOL = '3.1'
    VIABILL_STATUS = %w[CANCELLED APPROVED REJECTED].freeze
    def build_checkout_request_body(order)
      gateway = SolidusViabill::Gateway.new
      request_body = {
        protocol: VIABILL_PROTOCOL,
        transaction: order.number,
        amount: order.outstanding_balance.to_s,
        currency: order.currency,
        test: SolidusViabill.config.viabill_test_env.to_s,
        md5check: '',
        sha256check: '',
        apikey: SolidusViabill.config.viabill_api_key,
        order_number: order.number,
        success_url: SolidusViabill.config.viabill_success_url,
        cancel_url: SolidusViabill.config.viabill_cancel_url,
        callback_url: SolidusViabill.config.viabill_callback_url,
        customParams: {
          email: order.email,
          phoneNumber: order.bill_address&.phone,
          fullName: order.bill_address.name,
          address: [order.bill_address.address1, order.bill_address.address2].join(', '),
          city: order.bill_address.city,
          postalCode: order.bill_address.zipcode,
          country: order.bill_address.country.name
        }
      }
      request_body[:sha256check] = gateway.generate_signature(
        request_body[:apikey],
        request_body[:amount],
        request_body[:currency],
        request_body[:transaction],
        request_body[:order_number],
        request_body[:success_url],
        request_body[:cancel_url],
        SolidusViabill.config.viabill_secret_key,
        '#'
      )
      request_body
    end

    def build_payment_params(order, status)
      raise 'Unverified Status for Payment' unless VIABILL_STATUS.include? status

      gateway = SolidusViabill::Gateway.new
      request_body = {
        amount: order.outstanding_balance.to_s,
        payment_method_id: Spree::PaymentMethod.find_by(type: 'SolidusViabill::ViabillPaymentMethod').id,
        source_attributes: {
          transaction_number: order.number,
          order_number: order.number,
          amount: order.outstanding_balance.to_s,
          currency: order.currency,
          status: status,
          time: Time.now.to_i,
          signature: ''
        }
      }
      request_body[:source_attributes][:signature] = gateway.generate_signature(
        request_body[:source_attributes][:transaction_number],
        request_body[:source_attributes][:amount],
        request_body[:source_attributes][:currency],
        request_body[:source_attributes][:order_number],
        request_body[:source_attributes][:status],
        request_body[:source_attributes][:time],
        SolidusViabill.config.viabill_secret_key,
        '#'
      )
      request_body
    end
  end
end