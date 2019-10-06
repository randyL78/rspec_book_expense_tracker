# frozen_string_literal: true

require_relative '../../../app/api'
require 'rack/test'

# Unit tests for the API
module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def parsed(res)
      JSON.parse(res.body)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    describe 'GET /expenses/:date' do
      context 'when an expense exists on a given date' do
        before do
          allow(ledger).to receive(:expenses_on)
            .with('2017-06-12')
            .and_return(%w[expense_1 expense_2])
        end

        it 'returns the expense as JSON' do
          get '/expenses/2017-06-12'

          expect(parsed(last_response)).to eq(%w[expense_1 expense_2])
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-12'
          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no expenses on a given date' do
        before do
          allow(ledger).to receive(:expenses_on)
            .with('2017-06-12')
            .and_return([])
        end

        it 'returns an empty array as JSON' do
          get '/expenses/2017-06-12'

          expect(parsed(last_response)).to eq([])
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-12'

          expect(last_response.status).to eq(200)
        end
      end
    end

    describe 'POST /expenses' do
      context 'when the expense is successfully recorded' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end

        it 'returns with the expense id' do
          post '/expenses', JSON.generate(expense)

          expect(parsed(last_response)).to include('expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
          post '/expenses', JSON.generate(expense)

          expect(last_response.status).to eq(200)
        end
      end

      context 'when the expense fails validation' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)

          expect(parsed(last_response))
            .to include('error' => 'Expense incomplete')
        end

        it 'responds with 422 (Unprocessible entity)' do
          post '/expenses', JSON.generate(expense)

          expect(last_response.status).to eq(422)
        end
      end
    end
  end
end
