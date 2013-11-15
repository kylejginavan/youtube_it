# encoding: UTF-8

class YouTubeIt
  module Instrumentation

    begin
      require 'active_support/log_subscriber'
      require 'active_support/concern'

      def self.measure(url, &block)
        payload = { :url => url }
        ActiveSupport::Notifications.instrument("fetch.youtube", payload, &block)
      end

      class LogSubscriber < ActiveSupport::LogSubscriber
        def fetch(event)
          self.class.runtime += event.duration

          info '  YouTube: GET %s %s (%.1fms)' % [
            event.payload[:url],
            ("ERROR: #{event.payload[:error]}" if event.payload.key?(:error)),
            event.duration
          ]
        end

        class << self
          def runtime=(value)
            Thread.current[:youtube_runtime] = value
          end

          def runtime
            Thread.current[:youtube_runtime] ||= 0
          end

          def reset_runtime
            rt, self.runtime = runtime, 0
            rt
          end
        end
      end

      # ActionController Instrumentation to log time spent in YouTube
      # requests at the bottom of log messages.
      #
      module ControllerRuntime
        extend ActiveSupport::Concern

        attr_internal :youtube_runtime

        def append_info_to_payload(payload)
          super
          payload[:youtube_runtime] = (youtube_runtime || 0) + Instrumentation::LogSubscriber.runtime
        end
        protected :append_info_to_payload

        def cleanup_view_runtime
          rt_before_render = Instrumentation::LogSubscriber.reset_runtime
          runtime = super
          rt_after_render = Instrumentation::LogSubscriber.reset_runtime
          self.youtube_runtime = rt_before_render + rt_after_render
          runtime - rt_after_render
        end
        protected :cleanup_view_runtime

        module ClassMethods
          def log_process_action(payload)
            messages, youtube_runtime = super, payload[:youtube_runtime]
            messages << ("YouTube: %.1fms" % youtube_runtime.to_f) if youtube_runtime
            messages
          end
        end
      end

      if defined?(::Rails::Railtie)
        class Railtie < ::Rails::Railtie
          initializer 'youtube_it.setup_instrumentation' do
            YouTubeIt::Instrumentation::LogSubscriber.attach_to :youtube

            ActiveSupport.on_load(:action_controller) do
              include YouTubeIt::Instrumentation::ControllerRuntime
            end
          end
        end
      end

    rescue LoadError
      # Define a dummy hook
      #
      def self.measure(*args, &block)
        block.call(payload = {})
      end
    end

  end
end
