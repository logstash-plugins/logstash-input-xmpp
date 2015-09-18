# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require 'logstash/inputs/xmpp'
require 'support/xmpp4r_mocks.rb'

describe LogStash::Inputs::Xmpp do
  let(:rooms) { ['logstash', 'kibana'] }
  let(:config) do
    {
      'user' => 'foo@domain.org/chat',
      'password' => 'bAr',
      'rooms' => rooms
    }
  end

  before do
    allow(Jabber::Client).to receive(:new) do |jid|
      Jabber::ClientMock.new(jid)
    end

    allow(Jabber::MUC::SimpleMUCClient).to receive(:new) do |client|
      Jabber::MucClientMock.new(client)
    end
  end

  context 'when running' do
    let(:queue) { [] }
    let(:msg)   { 'Hello Logstash'}
    let(:inject_block) do
      -> { subject.client.inject_message(Jabber::MessageMock.new(msg)) }
    end

    subject { LogStash::Inputs::Xmpp.new(config) }

    before do
      subject.register
      plugin_thread = Thread.new(subject, queue) { |subj, que| subj.run(que) }
      sleep 0.01 until plugin_thread.status == 'sleep'
      inject_block.call
      subject.stop
    end

    context "when using Client" do
      it 'pushes normal events into a queue' do
        event = queue.first
        expect(event['message']).to eq(msg)
        expect(event['from']).to eq('bar@domain.org/chat')
      end
    end

    context "when using Rooms" do
      let(:inject_block) do
        -> do
          subject.muc_clients.each do |muc|
            muc.inject_message('now', 'bar', 'Hello Foo')
          end
        end
      end

      it 'pushes room events into a queue' do
        rooms.each do |room|
          event = queue.shift
          expect(event['message']).to eq('Hello Foo')
          expect(event['from']).to eq('bar')
          expect(event['room']).to eq(room)
        end
      end
    end
  end

  context 'when shutting down' do
    it_behaves_like "an interruptible input plugin"
  end
end
