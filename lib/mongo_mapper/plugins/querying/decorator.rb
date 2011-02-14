require 'benchmark'

# encoding: UTF-8
module MongoMapper
  module Plugins
    module Querying
      module Decorator
        include DynamicQuerying::ClassMethods

        def model(model=nil)
          return @model if model.nil?
          @model = model
          self
        end

        def find!(*ids)
          raise DocumentNotFound, "Couldn't find without an ID" if ids.size == 0

          find(*ids).tap do |result|
            if result.nil? || ids.size != Array(result).size
              raise DocumentNotFound, "Couldn't find all of the ids (#{ids.join(',')}). Found #{Array(result).size}, but was expecting #{ids.size}"
            end
          end
        end

        def all(opts={})
          result = nil
          log_time("all query #{to_hash.inspect}") { result = super }
          log_time("all load  #{to_hash.inspect}") { result.map { |doc| model.load(doc) } }
        end

        def first(opts={})
          result = nil
          log_time("first query #{to_hash.inspect}") { result = super }
          log_time("first load  #{to_hash.inspect}") { model.load(result) }
        end

        def last(opts={})
          result = nil
          log_time("last query #{to_hash.inspect}") { result = super }
          log_time("last load  #{to_hash.inspect}") { model.load(result) }
        end

        private
          def method_missing(method, *args, &block)
            return super unless model.respond_to?(method)
            result = model.send(method, *args, &block)
            return super unless result.is_a?(Plucky::Query)
            merge(result)
          end
          
          def log_time(msg = "")
            logger = model.logger
            result = nil
            if logger
              time = Benchmark.realtime do
                result = yield
              end
              time_ms = (time*10000) / 10.0
              logger.debug "(#{time_ms}ms) #{msg}"
              result
            else
              yield
            end
          end
      end
    end
  end
end