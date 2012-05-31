require 'resque'
require 'backgrounded/handler/abstract_handler'

# enqueue requests in resque
module Backgrounded
  module Resque
    class ResqueHandler < Backgrounded::Handler::AbstractHandler
      DEFAULT_QUEUE = 'backgrounded'
      INVALID_ID = -1
      @@queue = DEFAULT_QUEUE

      def request(object, method, args)
        @@queue = options[:queue] || DEFAULT_QUEUE
        instance, id = instance_identifiers(object)
        ::Resque.enqueue(ResqueHandler, instance, id, method, *args)
      end
      def self.queue
        @@queue
      end

      # invoke the requested method
      # fired from the resque workers
      def self.perform(clazz, id, method, *args)
        find_instance(clazz, id, method).send(method, *args)
      end

      private
      def self.find_instance(clazz, id, method)
        clazz = clazz.constantize
        id.to_i == INVALID_ID ? clazz : clazz.find(id)
      end
      def instance_identifiers(object)
        instance, id = if object.is_a?(Class) 
          [object.name, INVALID_ID]
        else
          [object.class.name, object.id]
        end
      end
    end
  end
end
