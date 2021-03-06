module HTTTee
  module Server
    module SSE
      class Body
        include EventMachine::Deferrable

        MESSAGE = 'message'
        CTRL    = 'ctrl'
        EOF     = 'eof'

        CTRL_TABLE = {
          "\n"    => 'newline',
          "\r"    => 'carriage-return',
          "\r \n" => 'crlf',
        }

        def initialize(body)
          @body = body
        end

        def call(chunks)
          chunks.each do |chunk|
            send_chunk(chunk)
          end
        end

        def send_chunk(chunk)
          data, ctrl, remaining = chunk.partition(%r{\r \n|\n|\r})

          send_data(data)             unless data.empty?
          send_ctrl(CTRL_TABLE[ctrl]) unless ctrl.empty?
          send_chunk(remaining)       unless remaining.empty?
        end

        def send_data(data)
          send_event(MESSAGE)

          send_message(data)
        end

        def send_ctrl(type)
          send_event(CTRL)

          send_message(type)
        end

        def send_message(data)
          send "data", data, "\n\n"
        end

        def send_event(event)
          send "event", event, "\n"
        end

        def send(type, data, term)
          @body.call(["#{type}: #{data}#{term}"])
        end

        def succeed
          send_ctrl(EOF)

          @body.succeed
        end

        def each(&blk)
          @body.each(&blk)
        end
      end
    end
  end
end
