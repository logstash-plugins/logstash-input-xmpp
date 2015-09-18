# encoding: utf-8
module Jabber
  class ClientMock
    def initialize(jid)
      @jid = jid
      @message_block = ->(msg) { puts "!ERROR! ----> Should not see #{msg}"}
    end
    def connect(*) true; end
    def auth(*) true; end
    def send(*) true; end
    def close(*) true; end
    def add_presence_callback(*) true; end
    def add_message_callback(*args, &block)
      @message_block = block
    end
    def inject_message(msg)
      @message_block.call(msg)
    end
  end

  class MucClientMock
    def initialize(client)
      @message_block = ->(time, from, body) { puts "!!!!! ----> Should not see #{time}, #{from}, #{body}"}
    end
    def join(rm)
    end
    def on_message(&block)
      @message_block = block
    end
    def inject_message(time, from, body)
      @message_block.call(time, from, body)
    end
  end

  class MessageMock
    From = Struct.new(:node, :domain, :resource)
    attr_reader :body, :from
    def initialize(str)
      @body = str
      @from = From.new('bar','domain.org','chat')
    end
  end
end
