require 'resque'
require 'backgrounded/handler/abstract_handler'
require 'active_record/base'

# enqueue requests in resque
module Backgrounded
  module Resque
    class ResqueHandler < Backgrounded::Handler::AbstractHandler
      DEFAULT_QUEUE = 'backgrounded'
      INVALID_ID = -1

      # resque uses this attribute to determine what queue the job belongs in
      # @see Resque.queue_from_class
      class_attribute :queue
      self.queue = DEFAULT_QUEUE

      # enqueue the requested operation into resque
      # the resque worker will invoke .perform with the class/method/args
      # @see .perform
      def request(object, method, args)
        ResqueHandler.queue = options[:queue] || DEFAULT_QUEUE
        instance, id = instance_identifiers(object)
        ::Resque.enqueue(ResqueHandler, instance, id, method, *args)
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
        instance, id = if object.kind_of?(ActiveRecord::Base)
          [object.class.name, object.id]
        else
          [object.name, INVALID_ID]
        end
      end
    end
  end
end
