require 'spec_helper'

RSpec.describe SolidusViabill::CheckoutHelper, type: :helper do
  let(:spree_user) { create(:user_with_addresses) }
  let(:spree_address) { spree_user.addresses.first }
  let(:order) { create(:order, bill_address: spree_address, ship_address: spree_address, user: spree_user) }

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe '#build_checkout_request_body' do
    subject(:checkout_body) { build_checkout_request_body(order) }

    let(:key_list) {
      [
        :protocol,
        :transaction,
        :amount,
        :currency,
        :test,
        :md5check,
        :sha256check,
        :apikey,
        :order_number,
        :success_url,
        :cancel_url,
        :callback_url,
        :customParams
      ]
    }
    let(:custom_param_key_list) {
      [
        :email,
        :phoneNumber,
        :fullName,
        :address,
        :city,
        :postalCode,
        :country
      ]
    }

    it 'has all keys' do
      expect(checkout_body.keys).to eq key_list
    end

    it 'has all keys in customParams' do
      expect(checkout_body[:customParams].keys).to eq custom_param_key_list
    end
  end

  describe '#build_payment_params' do
    let(:gateway) { SolidusViabill::Gateway.new }
    let(:key_list) {
      [
        :amount,
        :payment_method_id,
        :source_attributes
      ]
    }

    let(:source_attribute_keys) {
      [
        :transaction_number,
        :order_number,
        :amount,
        :currency,
        :status,
        :time,
        :signature
      ]
    }

    before do
      create(:viabill_payment_method)
    end

    it 'has all keys' do
      expect(build_payment_params(order, 'APPROVED').keys).to eq key_list
    end

    it 'has all keys in source_attributes' do
      expect(
        build_payment_params(order, 'APPROVED')[:source_attributes].keys
      ).to eq source_attribute_keys
    end

    it 'has correct signature' do
      expect(
        build_payment_params(order, 'APPROVED')[:source_attributes][:signature]
      ).to eq gateway.generate_signature(
        order.number,
        order.outstanding_balance.to_s,
        order.currency,
        order.number,
        'APPROVED',
        Time.now.to_i,
        SolidusViabill.config.viabill_secret_key,
        '#'
      )
    end

    it 'does not raise error for status "APPROVED"' do
      expect{
        build_payment_params(order, 'APPROVED')
      }.not_to raise_error RuntimeError
    end

    it 'does not raise error for status "CANCELLED"' do
      expect{
        build_payment_params(order, 'CANCELLED')
      }.not_to raise_error RuntimeError
    end

    it 'does not raise error for status "REJECTED"' do
      expect{
        build_payment_params(order, 'REJECTED')
      }.not_to raise_error RuntimeError
    end

    it 'raises error for unrecognised status' do
      expect{
        build_payment_params(order, 'FAILED')
      }.to raise_error RuntimeError
    end

    it 'raises error for empty status' do
      expect{
        build_payment_params(order, ' ')
      }.to raise_error RuntimeError
    end

    it 'raises error for nil status' do
      expect{
        build_payment_params(order, nil)
      }.to raise_error RuntimeError
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end