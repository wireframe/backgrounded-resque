require 'resque'
require 'backgrounded/handler/abstract_handler'

# handler that acts like the in process handler but marshalls the arguments
# this simulates how resque encodes/decodes values to/from redis
# useful when passing symbols to arguments and they end up being processed as strings
module Backgrounded
  module Resque
    class PseudoResqueHandler < Backgrounded::Handler::AbstractHandler
      def request(object, method, args)
        marshalled_args = ::Resque.decode(::Resque.encode(args))
        object.send method, *marshalled_args
      end
    end
  end
end
