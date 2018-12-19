require 'spec_helper'
require 'active_support/notifications'

describe QueryCounter do
  after(:each) do
    QueryCounter.reset
    ActiveSupport::Notifications.unsubscribe(instrument_event_name)
  end

  let(:resource) { :db }
  let(:instrument_event_duration) { 0.01 }
  let(:instrument_event_name) { 'sql.active_record' }
  let(:instrument_resource_proc) do
    Proc.new do
      ActiveSupport::Notifications.instrument(instrument_event_name) do |payload|
        sleep(instrument_event_duration)
      end
    end
  end
  let(:instrument_resource) { instrument_resource_proc.call }

  let(:db_client_class) do
    Class.new do
      def query!(sql)
      end
    end
  end
  let(:db_client) { db_client_class.new }

  context 'record' do
    subject { QueryCounter.record(resource, 0.1) }

    it 'increments the total number of queries' do
      expect {
        expect {
          subject
        }.to change { QueryCounter.count(resource) }.by(1)
      }.to change { QueryCounter.global_count(resource) }.by(1)
    end
  end

  context 'count' do
    subject { QueryCounter.count(resource) }

    it 'returns 0 if no counts were recorded' do
      expect(subject).to eq(0)
    end
  end

  context 'global_count' do
    before(:each) do
      QueryCounter.global_collector.reset
    end

    subject { QueryCounter.global_count(resource) }

    it 'returns 0 if no counts were recorded' do
      expect(subject).to eq(0)
    end
  end

  context 'auto_subscribe!' do
    before(:each) do
      QueryCounter.auto_subscribe!(resource, instrument_event_name)
    end

    it 'automatically attaches to the notifications event and collects stats' do
      expect {
        instrument_resource
      }.to change { QueryCounter.count(resource) }.by(1)
    end
  end

  context 'around' do
    before(:each) do
      QueryCounter.auto_subscribe!(resource, instrument_event_name)
    end

    let(:num_resource_calls) { 3 }
    subject { QueryCounter.around { num_resource_calls.times { instrument_resource_proc.call } } }

    it 'keeps track of the number of calls within a given block' do
      2.times { instrument_resource_proc.call }
      expect(subject.count(resource)).to eq(num_resource_calls)
      expect(QueryCounter.count(resource)).to eq(num_resource_calls + 2)
    end

    it 'supports nested around blocks' do
      2.times { instrument_resource_proc.call }
      outside_collector = QueryCounter.around do
        4.times { instrument_resource_proc.call }
        expect(subject.count(resource)).to eq(num_resource_calls)
      end
      expect(outside_collector.count(resource)).to eq(num_resource_calls + 4)
      expect(QueryCounter.count(resource)).to eq(num_resource_calls + 6)
    end

    describe 'events' do
      it 'records the notification events' do
        2.times { instrument_resource_proc.call }
        outside_collector = QueryCounter.around do
          4.times { instrument_resource_proc.call }
          expect(subject.events(resource).size).to eq(num_resource_calls)
        end
        expect(outside_collector.events(resource).size).to eq(num_resource_calls + 4)
        expect(QueryCounter.current_collector.events(resource).size).to eq(0)
      end
    end
  end

  context 'auto_instrument!' do
    before(:each) do
      QueryCounter.auto_instrument!(resource, db_client_class, :query!)
    end

    subject { db_client.query!('select * from bars') }

    it 'automatically wraps the method in insturmentation' do
      expect {
        subject
      }.to change { QueryCounter.count(resource) }.by(1)
    end
  end
end
